import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/practice_spot.dart';
import '../models/annotation.dart';

/// Simple and clean database helper for PDF practice spots
/// Designed for easy extension with sync capabilities
class DBHelper {
  static Database? _database;
  static const String _databaseName = 'practice_spots.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String _spotsTable = 'spots';
  static const String _practiceHistoryTable = 'practice_history';

  /// Get the database instance (singleton pattern)
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  static Future<void> _createTables(Database db, int version) async {
    // Main spots table - exactly as requested with extensions
    await db.execute('''
      CREATE TABLE $_spotsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        piece TEXT NOT NULL,
        page INTEGER NOT NULL,
        x REAL NOT NULL,
        y REAL NOT NULL,
        width REAL NOT NULL,
        height REAL NOT NULL,
        color TEXT NOT NULL,
        last_practice TEXT,
        repeat_count INTEGER DEFAULT 0,
        readiness INTEGER DEFAULT 0,
        
        -- Extended fields for advanced features
        title TEXT,
        description TEXT,
        notes TEXT,
        priority TEXT DEFAULT 'medium',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        
        -- SRS fields (optional - can be ignored for basic usage)
        next_due TEXT,
        ease_factor REAL DEFAULT 2.5,
        interval_days INTEGER DEFAULT 1,
        repetitions INTEGER DEFAULT 0,
        
        -- Sync support (for future cloud integration)
        sync_status TEXT DEFAULT 'local',
        last_synced TEXT,
        cloud_id TEXT
      )
    ''');

    // Practice history table for detailed tracking
    await db.execute('''
      CREATE TABLE $_practiceHistoryTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        spot_id INTEGER NOT NULL,
        practice_date TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        quality_score INTEGER, -- 1-5 rating
        notes TEXT,
        
        -- Sync support
        sync_status TEXT DEFAULT 'local',
        cloud_id TEXT,
        
        FOREIGN KEY (spot_id) REFERENCES $_spotsTable (id) ON DELETE CASCADE
      )
    ''');

    // Indexes for performance
    await db.execute('CREATE INDEX idx_spots_piece ON $_spotsTable(piece)');
    await db.execute('CREATE INDEX idx_spots_page ON $_spotsTable(page)');
    await db.execute('CREATE INDEX idx_spots_active ON $_spotsTable(is_active)');
    await db.execute('CREATE INDEX idx_spots_due ON $_spotsTable(next_due)');
    await db.execute('CREATE INDEX idx_history_spot ON $_practiceHistoryTable(spot_id)');
    await db.execute('CREATE INDEX idx_history_date ON $_practiceHistoryTable(practice_date)');
  }

  /// Handle database upgrades
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Add migration logic here when schema changes
    if (oldVersion < 2) {
      // Example: Add new column in version 2
      // await db.execute('ALTER TABLE $_spotsTable ADD COLUMN new_field TEXT');
    }
  }

  // ====================================================================
  // CRUD OPERATIONS - Simple interface matching your requirements
  // ====================================================================

  /// Insert a new practice spot
  static Future<int> insertSpot(PracticeSpot spot) async {
    final db = await database;
    final id = await db.insert(_spotsTable, spot.toMap());
    print('DBHelper: Inserted spot "${spot.title ?? 'Unnamed'}" with ID: $id');
    return id;
  }

  /// Update an existing spot
  static Future<int> updateSpot(PracticeSpot spot) async {
    final db = await database;
    final rowsAffected = await db.update(
      _spotsTable,
      spot.toMap(),
      where: 'id = ?',
      whereArgs: [spot.id],
    );
    print('DBHelper: Updated spot ID ${spot.id}, rows affected: $rowsAffected');
    return rowsAffected;
  }

  /// Get a specific spot by ID
  static Future<PracticeSpot?> getSpot(int id) async {
    final db = await database;
    final maps = await db.query(
      _spotsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return PracticeSpot.fromMap(maps.first);
  }

  /// Get all spots for a specific piece
  static Future<List<PracticeSpot>> getSpotsForPiece(String piece) async {
    final db = await database;
    final maps = await db.query(
      _spotsTable,
      where: 'piece = ? AND is_active = 1',
      whereArgs: [piece],
      orderBy: 'page ASC, y ASC',
    );
    
    final spots = maps.map((map) => PracticeSpot.fromMap(map)).toList();
    print('DBHelper: Found ${spots.length} spots for piece "$piece"');
    return spots;
  }

  /// Get all spots for a specific page
  static Future<List<PracticeSpot>> getSpotsForPage(String piece, int page) async {
    final db = await database;
    final maps = await db.query(
      _spotsTable,
      where: 'piece = ? AND page = ? AND is_active = 1',
      whereArgs: [piece, page],
      orderBy: 'y ASC, x ASC',
    );
    
    return maps.map((map) => PracticeSpot.fromMap(map)).toList();
  }

  /// Get all active spots (for practice dashboard)
  static Future<List<PracticeSpot>> getAllActiveSpots() async {
    final db = await database;
    final maps = await db.query(
      _spotsTable,
      where: 'is_active = 1',
      orderBy: 'updated_at DESC',
    );
    
    final spots = maps.map((map) => PracticeSpot.fromMap(map)).toList();
    print('DBHelper: Found ${spots.length} active spots');
    return spots;
  }

  /// Get spots due for practice (based on SRS or simple repeat timing)
  static Future<List<PracticeSpot>> getDueSpots() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final maps = await db.query(
      _spotsTable,
      where: 'is_active = 1 AND (next_due IS NULL OR next_due <= ?)',
      whereArgs: [now],
      orderBy: 'priority DESC, readiness ASC, last_practice ASC',
    );
    
    final spots = maps.map((map) => PracticeSpot.fromMap(map)).toList();
    print('DBHelper: Found ${spots.length} spots due for practice');
    return spots;
  }

  /// Delete a spot (soft delete - marks as inactive)
  static Future<int> deleteSpot(int id) async {
    final db = await database;
    final rowsAffected = await db.update(
      _spotsTable,
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
    print('DBHelper: Soft deleted spot ID $id');
    return rowsAffected;
  }

  /// Permanently delete a spot (hard delete)
  static Future<int> hardDeleteSpot(int id) async {
    final db = await database;
    
    // Delete practice history first
    await db.delete(
      _practiceHistoryTable,
      where: 'spot_id = ?',
      whereArgs: [id],
    );
    
    // Delete the spot
    final rowsAffected = await db.delete(
      _spotsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    print('DBHelper: Hard deleted spot ID $id and its history');
    return rowsAffected;
  }

  // ====================================================================
  // PRACTICE HISTORY OPERATIONS
  // ====================================================================

  /// Record a practice session
  static Future<int> recordPractice({
    required int spotId,
    required int durationMinutes,
    int? qualityScore, // 1-5 rating
    String? notes,
  }) async {
    final db = await database;
    
    final practiceData = {
      'spot_id': spotId,
      'practice_date': DateTime.now().toIso8601String(),
      'duration_minutes': durationMinutes,
      'quality_score': qualityScore,
      'notes': notes,
      'sync_status': 'local',
    };
    
    final id = await db.insert(_practiceHistoryTable, practiceData);
    
    // Update spot's practice count and last practice date
    await db.update(
      _spotsTable,
      {
        'last_practice': DateTime.now().toIso8601String(),
        'repeat_count': await _getSpotPracticeCount(spotId) + 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [spotId],
    );
    
    print('DBHelper: Recorded practice session for spot $spotId');
    return id;
  }

  /// Get practice history for a spot
  static Future<List<Map<String, dynamic>>> getPracticeHistory(int spotId) async {
    final db = await database;
    return await db.query(
      _practiceHistoryTable,
      where: 'spot_id = ?',
      whereArgs: [spotId],
      orderBy: 'practice_date DESC',
    );
  }

  /// Get total practice count for a spot
  static Future<int> _getSpotPracticeCount(int spotId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_practiceHistoryTable WHERE spot_id = ?',
      [spotId],
    );
    return result.first['count'] as int;
  }

  // ====================================================================
  // UTILITY METHODS
  // ====================================================================

  /// Get database statistics
  static Future<Map<String, int>> getStats() async {
    final db = await database;
    
    final spotCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_spotsTable WHERE is_active = 1')
    ) ?? 0;
    
    final practiceCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_practiceHistoryTable')
    ) ?? 0;
    
    final pieceCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(DISTINCT piece) FROM $_spotsTable WHERE is_active = 1')
    ) ?? 0;
    
    return {
      'totalSpots': spotCount,
      'totalPractices': practiceCount,
      'totalPieces': pieceCount,
    };
  }

  /// Clear all data (for testing or reset)
  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete(_practiceHistoryTable);
    await db.delete(_spotsTable);
    print('DBHelper: Cleared all data');
  }

  /// Close database connection
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // ====================================================================
  // FUTURE SYNC SUPPORT (Cloud backup/restore)
  // ====================================================================

  /// Mark spots for sync (when cloud sync is implemented)
  static Future<void> markForSync(List<int> spotIds) async {
    final db = await database;
    for (final id in spotIds) {
      await db.update(
        _spotsTable,
        {'sync_status': 'pending'},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  /// Get spots that need syncing
  static Future<List<PracticeSpot>> getSpotsNeedingSync() async {
    final db = await database;
    final maps = await db.query(
      _spotsTable,
      where: 'sync_status IN (?, ?)',
      whereArgs: ['local', 'pending'],
    );
    
    return maps.map((map) => PracticeSpot.fromMap(map)).toList();
  }

  // ====================================================================
  // ANNOTATION METHODS
  // ====================================================================

  /// Insert annotation (placeholder - needs table creation)
  Future<void> insertAnnotation(dynamic annotation) async {
    // TODO: Implement annotation table and insertion
    debugPrint('DBHelper: insertAnnotation called - not yet implemented');
  }

  /// Get annotations for piece (placeholder)
  Future<List<Annotation>> getAnnotationsForPiece(String pieceId) async {
    // TODO: Implement annotation retrieval
    debugPrint('DBHelper: getAnnotationsForPiece called - not yet implemented');
    return <Annotation>[];
  }

  /// Update annotation (placeholder)
  Future<void> updateAnnotation(dynamic annotation) async {
    // TODO: Implement annotation update
    debugPrint('DBHelper: updateAnnotation called - not yet implemented');
  }

  /// Delete annotation (placeholder)
  Future<void> deleteAnnotation(String annotationId) async {
    // TODO: Implement annotation deletion
    debugPrint('DBHelper: deleteAnnotation called - not yet implemented');
  }

  /// Delete annotations for piece (placeholder)
  Future<void> deleteAnnotationsForPiece(String pieceId) async {
    // TODO: Implement bulk annotation deletion
    debugPrint('DBHelper: deleteAnnotationsForPiece called - not yet implemented');
  }

  /// Insert annotation layer (placeholder)
  Future<void> insertAnnotationLayer(dynamic layer) async {
    // TODO: Implement layer insertion
    debugPrint('DBHelper: insertAnnotationLayer called - not yet implemented');
  }

  /// Get annotation layers (placeholder)
  Future<List<AnnotationLayer>> getAnnotationLayers() async {
    // TODO: Implement layer retrieval
    debugPrint('DBHelper: getAnnotationLayers called - not yet implemented');
    return <AnnotationLayer>[];
  }

  /// Update annotation layer (placeholder)
  Future<void> updateAnnotationLayer(dynamic layer) async {
    // TODO: Implement layer update
    debugPrint('DBHelper: updateAnnotationLayer called - not yet implemented');
  }

  /// Delete annotation layer (placeholder)
  Future<void> deleteAnnotationLayer(String layerId) async {
    // TODO: Implement layer deletion
    debugPrint('DBHelper: deleteAnnotationLayer called - not yet implemented');
  }
}
