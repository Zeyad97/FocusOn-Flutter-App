import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/practice_spot.dart';
import '../models/annotation.dart';

/// Simple and clean database helper for PDF practice spots
/// Designed for easy extension with sync capabilities
class DBHelper {
  static Database? _database;
  static const String _databaseName = 'practice_spots.db';
  static const int _databaseVersion = 2;

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

    // Annotation layers table for layer management
    await db.execute('''
      CREATE TABLE annotation_layers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color_tag INTEGER NOT NULL,
        is_visible INTEGER DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        piece_id TEXT NOT NULL
      )
    ''');

    // Annotations table with enhanced data support
    await db.execute('''
      CREATE TABLE annotations (
        id TEXT PRIMARY KEY,
        piece_id TEXT NOT NULL,
        page INTEGER NOT NULL,
        layer_id TEXT NOT NULL,
        color_tag INTEGER NOT NULL,
        tool INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        data_json TEXT,
        bounds_json TEXT,
        metadata_json TEXT,
        FOREIGN KEY (layer_id) REFERENCES annotation_layers (id) ON DELETE CASCADE
      )
    ''');

    // Indexes for performance
    await db.execute('CREATE INDEX idx_spots_piece ON $_spotsTable(piece)');
    await db.execute('CREATE INDEX idx_spots_page ON $_spotsTable(page)');
    await db.execute('CREATE INDEX idx_spots_active ON $_spotsTable(is_active)');
    await db.execute('CREATE INDEX idx_spots_due ON $_spotsTable(next_due)');
    await db.execute('CREATE INDEX idx_history_spot ON $_practiceHistoryTable(spot_id)');
    await db.execute('CREATE INDEX idx_history_date ON $_practiceHistoryTable(practice_date)');
    
    // Annotation indexes for performance
    await db.execute('CREATE INDEX idx_annotations_piece_id ON annotations(piece_id)');
    await db.execute('CREATE INDEX idx_annotations_page ON annotations(page)');
    await db.execute('CREATE INDEX idx_annotations_layer_id ON annotations(layer_id)');
    await db.execute('CREATE INDEX idx_annotations_color_tag ON annotations(color_tag)');
    await db.execute('CREATE INDEX idx_annotations_tool ON annotations(tool)');
    await db.execute('CREATE INDEX idx_annotation_layers_piece ON annotation_layers(piece_id)');
  }

  /// Handle database upgrades
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Add migration logic here when schema changes
    if (oldVersion < 2) {
      // Add annotation tables in version 2
      debugPrint('DBHelper: Upgrading database from version $oldVersion to $newVersion - adding annotation tables');
      
      // Create annotation layers table
      await db.execute('''
        CREATE TABLE annotation_layers (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          color_tag INTEGER NOT NULL,
          is_visible INTEGER DEFAULT 1,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          piece_id TEXT NOT NULL
        )
      ''');

      // Create annotations table
      await db.execute('''
        CREATE TABLE annotations (
          id TEXT PRIMARY KEY,
          piece_id TEXT NOT NULL,
          page INTEGER NOT NULL,
          layer_id TEXT NOT NULL,
          color_tag INTEGER NOT NULL,
          tool INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          data_json TEXT,
          bounds_json TEXT,
          metadata_json TEXT,
          FOREIGN KEY (layer_id) REFERENCES annotation_layers (id) ON DELETE CASCADE
        )
      ''');

      // Add annotation indexes
      await db.execute('CREATE INDEX idx_annotations_piece_id ON annotations(piece_id)');
      await db.execute('CREATE INDEX idx_annotations_page ON annotations(page)');
      await db.execute('CREATE INDEX idx_annotations_layer_id ON annotations(layer_id)');
      await db.execute('CREATE INDEX idx_annotations_color_tag ON annotations(color_tag)');
      await db.execute('CREATE INDEX idx_annotations_tool ON annotations(tool)');
      await db.execute('CREATE INDEX idx_annotation_layers_piece ON annotation_layers(piece_id)');
      
      debugPrint('DBHelper: Successfully created annotation tables');
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
  // ANNOTATION METHODS - Advanced Implementation
  // ====================================================================

  /// Insert annotation with enhanced data support
  static Future<void> insertAnnotation(Annotation annotation) async {
    final db = await database;
    final data = annotation.toJson();
    
    // Convert complex data to JSON strings for SQLite storage
    if (data['data'] != null) {
      data['data_json'] = jsonEncode(data['data']);
    }
    if (data['bounds'] != null) {
      data['bounds_json'] = jsonEncode(data['bounds']);
    }
    if (data['metadata'] != null) {
      data['metadata_json'] = jsonEncode(data['metadata']);
    }
    
    // Remove the complex objects and keep only primitives for SQLite
    data.remove('data');
    data.remove('bounds');
    data.remove('metadata');
    
    await db.insert(
      'annotations',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('DBHelper: Inserted annotation ${annotation.id}');
  }

  /// Bulk insert annotations for performance
  static Future<void> insertAnnotations(List<Annotation> annotations) async {
    final db = await database;
    final batch = db.batch();
    
    for (final annotation in annotations) {
      final data = annotation.toJson();
      
      // Convert complex data to JSON strings
      if (data['data'] != null) {
        data['data_json'] = jsonEncode(data['data']);
      }
      if (data['bounds'] != null) {
        data['bounds_json'] = jsonEncode(data['bounds']);
      }
      if (data['metadata'] != null) {
        data['metadata_json'] = jsonEncode(data['metadata']);
      }
      
      // Remove complex objects
      data.remove('data');
      data.remove('bounds');
      data.remove('metadata');
      
      batch.insert(
        'annotations',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
    debugPrint('DBHelper: Bulk inserted ${annotations.length} annotations');
  }

  /// Get annotations for piece with enhanced data reconstruction
  static Future<List<Annotation>> getAnnotationsForPiece(String pieceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'annotations',
      where: 'piece_id = ?',
      whereArgs: [pieceId],
      orderBy: 'created_at DESC',
    );
    
    debugPrint('DBHelper: Retrieved ${maps.length} annotations for piece $pieceId');
    return maps.map((map) => _annotationFromMap(map)).toList();
  }

  /// Update annotation
  static Future<void> updateAnnotation(Annotation annotation) async {
    final db = await database;
    final data = annotation.toJson();
    
    // Convert complex data to JSON strings
    if (data['data'] != null) {
      data['data_json'] = jsonEncode(data['data']);
    }
    if (data['bounds'] != null) {
      data['bounds_json'] = jsonEncode(data['bounds']);
    }
    if (data['metadata'] != null) {
      data['metadata_json'] = jsonEncode(data['metadata']);
    }
    
    // Remove complex objects
    data.remove('data');
    data.remove('bounds');
    data.remove('metadata');
    
    await db.update(
      'annotations',
      data,
      where: 'id = ?',
      whereArgs: [annotation.id],
    );
    debugPrint('DBHelper: Updated annotation ${annotation.id}');
  }

  /// Delete annotation
  static Future<void> deleteAnnotation(String annotationId) async {
    final db = await database;
    await db.delete(
      'annotations',
      where: 'id = ?',
      whereArgs: [annotationId],
    );
    debugPrint('DBHelper: Deleted annotation $annotationId');
  }

  /// Delete annotations for piece
  static Future<void> deleteAnnotationsForPiece(String pieceId) async {
    final db = await database;
    await db.delete(
      'annotations',
      where: 'piece_id = ?',
      whereArgs: [pieceId],
    );
    debugPrint('DBHelper: Deleted all annotations for piece $pieceId');
  }

  /// Delete annotations by layer ID
  static Future<void> deleteAnnotationsByLayer(String pieceId, String layerId) async {
    final db = await database;
    await db.delete(
      'annotations',
      where: 'piece_id = ? AND layer_id = ?',
      whereArgs: [pieceId, layerId],
    );
    debugPrint('DBHelper: Deleted annotations for layer $layerId in piece $pieceId');
  }

  /// Move annotations to default layer
  static Future<void> moveAnnotationsToDefaultLayer(String pieceId, String layerId) async {
    final db = await database;
    await db.update(
      'annotations',
      {'layer_id': 'default'},
      where: 'piece_id = ? AND layer_id = ?',
      whereArgs: [pieceId, layerId],
    );
    debugPrint('DBHelper: Moved annotations from layer $layerId to default layer');
  }

  /// Convert database map to Annotation with enhanced data reconstruction
  static Annotation _annotationFromMap(Map<String, dynamic> map) {
    // Reconstruct complex data from JSON strings
    dynamic data;
    Map<String, dynamic>? boundsData;
    Map<String, dynamic>? metadataData;
    
    if (map['data_json'] != null) {
      final dataMap = jsonDecode(map['data_json']) as Map<String, dynamic>;
      final tool = AnnotationTool.values[map['tool']];
      
      // Reconstruct data based on tool type
      switch (tool) {
        case AnnotationTool.pen:
        case AnnotationTool.highlighter:
        case AnnotationTool.eraser:
          data = VectorPath.fromJson(dataMap);
          break;
        case AnnotationTool.text:
          data = TextData.fromJson(dataMap);
          break;
        case AnnotationTool.stamp:
          data = StampData.fromJson(dataMap);
          break;
      }
    }
    
    if (map['bounds_json'] != null) {
      boundsData = jsonDecode(map['bounds_json']) as Map<String, dynamic>;
    }
    
    if (map['metadata_json'] != null) {
      metadataData = jsonDecode(map['metadata_json']) as Map<String, dynamic>;
    }
    
    return Annotation(
      id: map['id'],
      pieceId: map['piece_id'],
      page: map['page'],
      layerId: map['layer_id'],
      colorTag: ColorTag.values[map['color_tag']],
      tool: AnnotationTool.values[map['tool']],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      data: data,
      bounds: boundsData != null ? Rect.fromLTRB(
        boundsData['left'].toDouble(),
        boundsData['top'].toDouble(),
        boundsData['right'].toDouble(),
        boundsData['bottom'].toDouble(),
      ) : null,
      metadata: metadataData,
    );
  }

  // ====================================================================
  // ANNOTATION LAYER METHODS - Complete Implementation
  // ====================================================================

  /// Insert annotation layer
  static Future<void> insertAnnotationLayer(String pieceId, AnnotationLayer layer) async {
    final db = await database;
    final data = layer.toJson();
    data['piece_id'] = pieceId; // Associate layer with piece
    
    await db.insert(
      'annotation_layers',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('DBHelper: Inserted annotation layer ${layer.id} for piece $pieceId');
  }

  /// Get annotation layers for a specific piece
  static Future<List<AnnotationLayer>> getAnnotationLayersForPiece(String pieceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'annotation_layers',
      where: 'piece_id = ?',
      whereArgs: [pieceId],
      orderBy: 'created_at ASC',
    );
    
    debugPrint('DBHelper: Retrieved ${maps.length} annotation layers for piece $pieceId');
    return maps.map((map) => AnnotationLayer.fromJson(map)).toList();
  }

  /// Get all annotation layers (legacy method)
  static Future<List<AnnotationLayer>> getAnnotationLayers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'annotation_layers',
      orderBy: 'created_at ASC',
    );
    
    debugPrint('DBHelper: Retrieved ${maps.length} annotation layers (all pieces)');
    return maps.map((map) => AnnotationLayer.fromJson(map)).toList();
  }

  /// Update annotation layer
  static Future<void> updateAnnotationLayer(String pieceId, AnnotationLayer layer) async {
    final db = await database;
    final data = layer.toJson();
    data['piece_id'] = pieceId;
    
    await db.update(
      'annotation_layers',
      data,
      where: 'id = ? AND piece_id = ?',
      whereArgs: [layer.id, pieceId],
    );
    debugPrint('DBHelper: Updated annotation layer ${layer.id} for piece $pieceId');
  }

  /// Delete annotation layer
  static Future<void> deleteAnnotationLayer(String pieceId, String layerId) async {
    final db = await database;
    await db.delete(
      'annotation_layers',
      where: 'id = ? AND piece_id = ?',
      whereArgs: [layerId, pieceId],
    );
    debugPrint('DBHelper: Deleted annotation layer $layerId for piece $pieceId');
  }
}
