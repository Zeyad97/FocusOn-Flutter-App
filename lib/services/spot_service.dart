import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/spot.dart';

class SpotService {
  static Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'spots.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }
  
  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE spots (
        id TEXT PRIMARY KEY,
        pieceId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        notes TEXT,
        pageNumber INTEGER NOT NULL,
        x REAL NOT NULL,
        y REAL NOT NULL,
        width REAL NOT NULL,
        height REAL NOT NULL,
        priority TEXT NOT NULL,
        readinessLevel TEXT NOT NULL,
        color TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        lastPracticed TEXT,
        nextDue TEXT,
        practiceCount INTEGER DEFAULT 0,
        successCount INTEGER DEFAULT 0,
        failureCount INTEGER DEFAULT 0,
        easeFactor REAL DEFAULT 2.5,
        interval INTEGER DEFAULT 1,
        repetitions INTEGER DEFAULT 0,
        isActive INTEGER DEFAULT 1,
        metadata TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE spot_history (
        id TEXT PRIMARY KEY,
        spotId TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        result TEXT NOT NULL,
        practiceTimeMinutes INTEGER NOT NULL,
        notes TEXT,
        metadata TEXT,
        FOREIGN KEY (spotId) REFERENCES spots (id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('CREATE INDEX idx_spots_piece ON spots(pieceId)');
    await db.execute('CREATE INDEX idx_spots_due ON spots(nextDue)');
    await db.execute('CREATE INDEX idx_spots_active ON spots(isActive)');
    await db.execute('CREATE INDEX idx_history_spot ON spot_history(spotId)');
  }
  
  Future<void> saveSpot(Spot spot) async {
    final db = await database;
    
    // Debug logging
    print('SpotService: Saving spot "${spot.title}" (pieceId: ${spot.pieceId}, isActive: ${spot.isActive})');
    print('  - Color: ${spot.color.name}');
    print('  - Priority: ${spot.priority.name}');
    print('  - Readiness: ${spot.readinessLevel.name}');
    
    // Check if spot exists by checking if it has an ID and exists in database
    final existingSpot = await getSpot(spot.id);
    
    if (existingSpot != null) {
      // Update existing spot
      print('SpotService: Spot exists, updating...');
      await updateSpot(spot);
    } else {
      // Insert new spot
      print('SpotService: New spot, inserting...');
      await db.insert(
        'spots',
        _spotToMap(spot),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    print('SpotService: Spot saved successfully');
  }

  Future<void> updateSpot(Spot spot) async {
    final db = await database;
    
    print('SpotService: Updating spot "${spot.title}" (id: ${spot.id})');
    print('  - Color: ${spot.color.name}');
    print('  - Priority: ${spot.priority.name}');
    print('  - Readiness: ${spot.readinessLevel.name}');
    
    await db.update(
      'spots',
      _spotToMap(spot),
      where: 'id = ?',
      whereArgs: [spot.id],
    );
    
    print('SpotService: Spot updated successfully');
  }

  Future<void> recordPracticeSession(String spotId, SpotResult result, int practiceTimeMinutes, {String? notes}) async {
    final db = await database;
    
    // Record practice history
    final historyId = DateTime.now().millisecondsSinceEpoch.toString();
    await db.insert('spot_history', {
      'id': historyId,
      'spotId': spotId,
      'timestamp': DateTime.now().toIso8601String(),
      'result': result.name,
      'practiceTimeMinutes': practiceTimeMinutes,
      'notes': notes,
      'metadata': '{}',
    });
    
    // Update spot with practice results
    final spot = await getSpot(spotId);
    if (spot != null) {
      final updatedSpot = spot.copyWith(
        practiceCount: spot.practiceCount + 1,
        successCount: result == SpotResult.excellent || result == SpotResult.good 
            ? spot.successCount + 1 
            : spot.successCount,
        failureCount: result == SpotResult.failed 
            ? spot.failureCount + 1 
            : spot.failureCount,
        lastPracticed: DateTime.now(),
        lastResult: result,
        lastResultAt: DateTime.now(),
        updatedAt: DateTime.now(),
        color: spot.getUpdatedColorBasedOnResult(result),
      );
      
      await updateSpot(updatedSpot);
      print('SpotService: Practice session recorded for spot $spotId');
    }
  }

  Future<List<Map<String, dynamic>>> getPracticeHistory(String spotId) async {
    final db = await database;
    return await db.query(
      'spot_history',
      where: 'spotId = ?',
      whereArgs: [spotId],
      orderBy: 'timestamp DESC',
    );
  }
  
  Future<Spot?> getSpot(String id) async {
    final db = await database;
    final maps = await db.query(
      'spots',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return _mapToSpot(maps.first);
  }
  
  Future<List<Spot>> getSpotsForPiece(String pieceId) async {
    final db = await database;
    final maps = await db.query(
      'spots',
      where: 'pieceId = ? AND isActive = 1',
      whereArgs: [pieceId],
      orderBy: 'createdAt ASC',
    );
    
    return maps.map((map) => _mapToSpot(map)).toList();
  }
  
  Future<List<Spot>> getDueSpots() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final maps = await db.query(
      'spots',
      where: 'isActive = 1 AND (nextDue IS NULL OR nextDue <= ?)',
      whereArgs: [now],
      orderBy: 'priority DESC, nextDue ASC',
    );

    final spots = maps.map((map) => _mapToSpot(map)).toList();
    print('SpotService: getDueSpots found ${spots.length} due spots');
    for (final spot in spots) {
      print('  - "${spot.title}" (pieceId: ${spot.pieceId}, nextDue: ${spot.nextDue}, isActive: ${spot.isActive})');
    }
    
    return spots;
  }

  Future<List<Spot>> getAllActiveSpots() async {
    final db = await database;
    final maps = await db.query(
      'spots',
      where: 'isActive = 1',
      orderBy: 'updatedAt DESC',
    );

    final spots = maps.map((map) => _mapToSpot(map)).toList();
    print('SpotService: getAllActiveSpots found ${spots.length} spots in database');
    for (final spot in spots) {
      print('  - "${spot.title}" (pieceId: ${spot.pieceId}, isActive: ${spot.isActive})');
    }
    
    return spots;
  }
  
  Future<void> deleteSpot(String id) async {
    print('SpotService: Deleting spot with id: $id');
    final db = await database;
    
    // Delete from spots table
    final spotsDeleted = await db.delete(
      'spots',
      where: 'id = ?',
      whereArgs: [id],
    );
    print('SpotService: Deleted $spotsDeleted spots from database');
    
    // Also delete history
    final historyDeleted = await db.delete(
      'spot_history',
      where: 'spotId = ?',
      whereArgs: [id],
    );
    print('SpotService: Deleted $historyDeleted history records');
  }
  
  Future<void> saveSpotHistory(SpotHistory history) async {
    final db = await database;
    await db.insert(
      'spot_history',
      _historyToMap(history),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<List<SpotHistory>> getSpotHistory(String spotId) async {
    final db = await database;
    final maps = await db.query(
      'spot_history',
      where: 'spotId = ?',
      whereArgs: [spotId],
      orderBy: 'timestamp DESC',
    );
    
    return maps.map((map) => _mapToHistory(map)).toList();
  }
  
  Future<List<SpotHistory>> getAllHistory() async {
    final db = await database;
    final maps = await db.query(
      'spot_history',
      orderBy: 'timestamp DESC',
    );
    
    return maps.map((map) => _mapToHistory(map)).toList();
  }
  
  Map<String, dynamic> _spotToMap(Spot spot) {
    return {
      'id': spot.id,
      'pieceId': spot.pieceId,
      'title': spot.title,
      'description': spot.description,
      'notes': spot.notes,
      'pageNumber': spot.pageNumber,
      'x': spot.x,
      'y': spot.y,
      'width': spot.width,
      'height': spot.height,
      'priority': spot.priority.name,
      'readinessLevel': spot.readinessLevel.name,
      'color': spot.color.name,
      'createdAt': spot.createdAt.toIso8601String(),
      'updatedAt': spot.updatedAt.toIso8601String(),
      'lastPracticed': spot.lastPracticed?.toIso8601String(),
      'nextDue': spot.nextDue?.toIso8601String(),
      'practiceCount': spot.practiceCount,
      'successCount': spot.successCount,
      'failureCount': spot.failureCount,
      'easeFactor': spot.easeFactor,
      'interval': spot.interval,
      'repetitions': spot.repetitions,
      'isActive': spot.isActive ? 1 : 0,
      'metadata': spot.metadata != null ? spot.metadata.toString() : null,
    };
  }
  
  Spot _mapToSpot(Map<String, dynamic> map) {
    return Spot(
      id: map['id'],
      pieceId: map['pieceId'],
      title: map['title'],
      description: map['description'],
      notes: map['notes'],
      pageNumber: map['pageNumber'],
      x: map['x'],
      y: map['y'],
      width: map['width'],
      height: map['height'],
      priority: SpotPriority.values.firstWhere(
        (p) => p.name == map['priority'],
        orElse: () => SpotPriority.medium,
      ),
      readinessLevel: ReadinessLevel.values.firstWhere(
        (r) => r.name == map['readinessLevel'],
        orElse: () => ReadinessLevel.newSpot,
      ),
      color: SpotColor.values.firstWhere(
        (c) => c.name == map['color'],
        orElse: () => SpotColor.red,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      lastPracticed: map['lastPracticed'] != null 
          ? DateTime.parse(map['lastPracticed']) 
          : null,
      nextDue: map['nextDue'] != null 
          ? DateTime.parse(map['nextDue']) 
          : null,
      practiceCount: map['practiceCount'] ?? 0,
      successCount: map['successCount'] ?? 0,
      failureCount: map['failureCount'] ?? 0,
      easeFactor: map['easeFactor'] ?? 2.5,
      interval: map['interval'] ?? 1,
      repetitions: map['repetitions'] ?? 0,
      isActive: map['isActive'] == 1,
      metadata: map['metadata'] != null ? {} : null, // Parse JSON if needed
    );
  }
  
  Map<String, dynamic> _historyToMap(SpotHistory history) {
    return {
      'id': history.id,
      'spotId': history.spotId,
      'timestamp': history.timestamp.toIso8601String(),
      'result': history.result.name,
      'practiceTimeMinutes': history.practiceTimeMinutes,
      'notes': history.notes,
      'metadata': history.metadata?.toString(),
    };
  }
  
  SpotHistory _mapToHistory(Map<String, dynamic> map) {
    return SpotHistory(
      id: map['id'],
      spotId: map['spotId'],
      timestamp: DateTime.parse(map['timestamp']),
      result: SpotResult.values.firstWhere(
        (r) => r.name == map['result'],
        orElse: () => SpotResult.good,
      ),
      practiceTimeMinutes: map['practiceTimeMinutes'],
      notes: map['notes'],
      metadata: map['metadata'] != null ? {} : null, // Parse JSON if needed
    );
  }
}

final spotServiceProvider = Provider<SpotService>((ref) => SpotService());
