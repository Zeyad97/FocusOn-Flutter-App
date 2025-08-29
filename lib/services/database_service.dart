import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/piece.dart';
import '../models/spot.dart';
import '../models/practice_session.dart';
import '../models/annotation.dart';
import '../models/project.dart';
import '../models/bookmark.dart';

/// Core database service for FocusON Scores
/// Handles all data persistence with SQLite
class DatabaseService {
  static const String _databaseName = 'focuson_scores.db';
  static const int _databaseVersion = 6;

  static Database? _database;
  static final DatabaseService _instance = DatabaseService._internal();
  
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  /// Get database instance, creating it if necessary
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize database with all tables
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        // Ensure foreign key constraints are enabled
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// Create all database tables
  Future<void> _onCreate(Database db, int version) async {
    // Pieces table
    await db.execute('''
      CREATE TABLE pieces (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        composer TEXT NOT NULL,
        key_signature TEXT,
        difficulty INTEGER NOT NULL,
        genre TEXT,
        duration INTEGER,
        concert_date INTEGER,
        last_opened INTEGER,
        last_viewed_page INTEGER,
        last_zoom REAL,
        view_mode TEXT,
        pdf_file_path TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        project_id TEXT,
        metadata TEXT,
        total_time_spent INTEGER DEFAULT 0,
        thumbnail_path TEXT,
        total_pages INTEGER DEFAULT 0,
        target_tempo INTEGER,
        current_tempo INTEGER,
        is_favorite INTEGER DEFAULT 0,
        tags TEXT
      )
    ''');

    // Spots table
    await db.execute('''
      CREATE TABLE spots (
        id TEXT PRIMARY KEY,
        piece_id TEXT NOT NULL,
        page_number INTEGER NOT NULL,
        rect_x REAL NOT NULL,
        rect_y REAL NOT NULL,
        rect_width REAL NOT NULL,
        rect_height REAL NOT NULL,
        color TEXT NOT NULL,
        difficulty INTEGER NOT NULL,
        label TEXT NOT NULL,
        next_due INTEGER NOT NULL,
        is_pinned INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        metadata TEXT,
        FOREIGN KEY (piece_id) REFERENCES pieces (id) ON DELETE CASCADE
      )
    ''');

    // Spot history table
    await db.execute('''
      CREATE TABLE spot_history (
        id TEXT PRIMARY KEY,
        spot_id TEXT NOT NULL,
        session_date INTEGER NOT NULL,
        result TEXT NOT NULL,
        session_duration INTEGER,
        notes TEXT,
        metadata TEXT,
        FOREIGN KEY (spot_id) REFERENCES spots (id) ON DELETE CASCADE
      )
    ''');

    // Practice sessions table
    await db.execute('''
      CREATE TABLE practice_sessions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        start_time INTEGER,
        end_time INTEGER,
        planned_duration INTEGER NOT NULL,
        micro_breaks_enabled INTEGER DEFAULT 1,
        micro_break_interval INTEGER DEFAULT 1800000,
        micro_break_duration INTEGER DEFAULT 300000,
        project_id TEXT,
        metadata TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Spot sessions table (individual spots within practice sessions)
    await db.execute('''
      CREATE TABLE spot_sessions (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        spot_id TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        allocated_time INTEGER NOT NULL,
        status TEXT NOT NULL,
        start_time INTEGER,
        end_time INTEGER,
        result TEXT,
        notes TEXT,
        metadata TEXT,
        FOREIGN KEY (session_id) REFERENCES practice_sessions (id) ON DELETE CASCADE,
        FOREIGN KEY (spot_id) REFERENCES spots (id) ON DELETE CASCADE
      )
    ''');

    // Projects table
    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        concert_date INTEGER,
        piece_ids TEXT,
        daily_practice_goal INTEGER DEFAULT 1800000,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        metadata TEXT
      )
    ''');

    // Annotation layers table
    await db.execute('''
      CREATE TABLE annotation_layers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        is_visible INTEGER DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Annotations table
    await db.execute('''
      CREATE TABLE annotations (
        id TEXT PRIMARY KEY,
        piece_id TEXT NOT NULL,
        page INTEGER NOT NULL,
        layer_id TEXT NOT NULL,
        color_tag INTEGER NOT NULL,
        tool INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        path TEXT,
        text TEXT,
        stamp_type TEXT,
        bounds TEXT,
        metadata TEXT,
        FOREIGN KEY (piece_id) REFERENCES pieces (id) ON DELETE CASCADE,
        FOREIGN KEY (layer_id) REFERENCES annotation_layers (id) ON DELETE CASCADE
      )
    ''');

    // Bookmarks table
    await db.execute('''
      CREATE TABLE bookmarks (
        id TEXT PRIMARY KEY,
        pdf_id TEXT NOT NULL,
        page_number INTEGER NOT NULL,
        note TEXT DEFAULT '',
        created_at INTEGER NOT NULL,
        FOREIGN KEY (pdf_id) REFERENCES pieces (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await _createIndexes(db);
  }

  /// Create database indexes for optimized queries
  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX idx_spots_piece_id ON spots (piece_id)');
    await db.execute('CREATE INDEX idx_spots_next_due ON spots (next_due)');
    await db.execute('CREATE INDEX idx_spots_color ON spots (color)');
    await db.execute('CREATE INDEX idx_spot_history_spot_id ON spot_history (spot_id)');
    await db.execute('CREATE INDEX idx_spot_history_session_date ON spot_history (session_date)');
    await db.execute('CREATE INDEX idx_spot_sessions_session_id ON spot_sessions (session_id)');
    await db.execute('CREATE INDEX idx_spot_sessions_spot_id ON spot_sessions (spot_id)');
    await db.execute('CREATE INDEX idx_pieces_project_id ON pieces (project_id)');
    await db.execute('CREATE INDEX idx_pieces_last_opened ON pieces (last_opened)');
    await db.execute('CREATE INDEX idx_annotations_piece_id ON annotations (piece_id)');
    await db.execute('CREATE INDEX idx_annotations_page ON annotations (page)');
    await db.execute('CREATE INDEX idx_annotations_layer_id ON annotations (layer_id)');
    await db.execute('CREATE INDEX idx_annotations_color_tag ON annotations (color_tag)');
    await db.execute('CREATE INDEX idx_annotations_tool ON annotations (tool)');
    await db.execute('CREATE INDEX idx_bookmarks_pdf_id ON bookmarks (pdf_id)');
    await db.execute('CREATE INDEX idx_bookmarks_page_number ON bookmarks (page_number)');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add missing columns to pieces table
      await db.execute('ALTER TABLE pieces ADD COLUMN genre TEXT');
      await db.execute('ALTER TABLE pieces ADD COLUMN duration INTEGER');
      await db.execute('ALTER TABLE pieces ADD COLUMN last_viewed_page INTEGER');
      await db.execute('ALTER TABLE pieces ADD COLUMN last_zoom REAL');
      await db.execute('ALTER TABLE pieces ADD COLUMN view_mode TEXT');
      await db.execute('ALTER TABLE pieces ADD COLUMN total_time_spent INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE pieces ADD COLUMN thumbnail_path TEXT');
      await db.execute('ALTER TABLE pieces ADD COLUMN total_pages INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE pieces ADD COLUMN target_tempo INTEGER');
      await db.execute('ALTER TABLE pieces ADD COLUMN current_tempo INTEGER');
    }
    
    if (oldVersion < 3) {
      // Add annotation tables
      await db.execute('''
        CREATE TABLE annotation_layers (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          is_visible INTEGER DEFAULT 1,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE annotations (
          id TEXT PRIMARY KEY,
          piece_id TEXT NOT NULL,
          page INTEGER NOT NULL,
          layer_id TEXT NOT NULL,
          color_tag INTEGER NOT NULL,
          tool INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          path TEXT,
          text TEXT,
          stamp_type TEXT,
          bounds TEXT,
          metadata TEXT,
          FOREIGN KEY (piece_id) REFERENCES pieces (id) ON DELETE CASCADE,
          FOREIGN KEY (layer_id) REFERENCES annotation_layers (id) ON DELETE CASCADE
        )
      ''');

      // Add annotation indexes
      await db.execute('CREATE INDEX idx_annotations_piece_id ON annotations (piece_id)');
      await db.execute('CREATE INDEX idx_annotations_page ON annotations (page)');
      await db.execute('CREATE INDEX idx_annotations_layer_id ON annotations (layer_id)');
      await db.execute('CREATE INDEX idx_annotations_color_tag ON annotations (color_tag)');
      await db.execute('CREATE INDEX idx_annotations_tool ON annotations (tool)');
    }

    if (oldVersion < 4) {
      // Add bookmarks table
      await db.execute('''
        CREATE TABLE bookmarks (
          id TEXT PRIMARY KEY,
          pdf_id TEXT NOT NULL,
          page_number INTEGER NOT NULL,
          note TEXT DEFAULT '',
          created_at INTEGER NOT NULL,
          FOREIGN KEY (pdf_id) REFERENCES pieces (id) ON DELETE CASCADE
        )
      ''');

      // Add bookmark indexes
      await db.execute('CREATE INDEX idx_bookmarks_pdf_id ON bookmarks (pdf_id)');
      await db.execute('CREATE INDEX idx_bookmarks_page_number ON bookmarks (page_number)');
    }
    
    if (oldVersion < 5) {
      // Add is_favorite column to pieces table
      await db.execute('ALTER TABLE pieces ADD COLUMN is_favorite INTEGER DEFAULT 0');
    }
    
    if (oldVersion < 6) {
      // Add tags column to pieces table
      await db.execute('ALTER TABLE pieces ADD COLUMN tags TEXT');
    }
  }

  /// Delete and recreate database (for development/testing)
  Future<void> recreateDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    
    // Delete existing database
    if (await File(path).exists()) {
      await File(path).delete();
      print('DatabaseService: Deleted existing database');
    }
    
    // Recreate database
    _database = await _initDatabase();
    print('DatabaseService: Database recreated with new schema');
  }

  // ============================================================================
  // PIECES CRUD OPERATIONS
  // ============================================================================

  /// Insert a new piece
  Future<void> insertPiece(Piece piece) async {
    final db = await database;
    try {
      print('DatabaseService: Attempting to insert piece "${piece.title}" with data: ${piece.toJson()}');
      await db.insert(
        'pieces',
        piece.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('DatabaseService: Successfully inserted piece "${piece.title}"');
    } catch (e) {
      print('DatabaseService: Error inserting piece "${piece.title}": $e');
      print('DatabaseService: Piece data: ${piece.toJson()}');
      rethrow;
    }
  }

  /// Get all pieces
  Future<List<Piece>> getAllPieces() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pieces',
      orderBy: 'last_opened DESC, title ASC',
    );

    return Future.wait(maps.map((map) async {
      final piece = Piece.fromJson(map);
      final spots = await getSpotsForPiece(piece.id);
      return piece.copyWith(spots: spots);
    }));
  }

  /// Get piece by ID
  Future<Piece?> getPieceById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pieces',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final piece = Piece.fromJson(maps.first);
    final spots = await getSpotsForPiece(id);
    return piece.copyWith(spots: spots);
  }

  /// Update piece
  Future<void> updatePiece(Piece piece) async {
    final db = await database;
    await db.update(
      'pieces',
      piece.toJson(),
      where: 'id = ?',
      whereArgs: [piece.id],
    );
  }

  /// Delete piece and all associated data
  Future<void> deletePiece(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      // Delete spot history for this piece's spots
      await txn.execute('''
        DELETE FROM spot_history 
        WHERE spot_id IN (SELECT id FROM spots WHERE piece_id = ?)
      ''', [id]);
      
      // Delete spot sessions for this piece's spots
      await txn.execute('''
        DELETE FROM spot_sessions 
        WHERE spot_id IN (SELECT id FROM spots WHERE piece_id = ?)
      ''', [id]);
      
      // Delete spots
      await txn.delete('spots', where: 'piece_id = ?', whereArgs: [id]);
      
      // Delete piece
      await txn.delete('pieces', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Search pieces by title or composer
  Future<List<Piece>> searchPieces(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pieces',
      where: 'title LIKE ? OR composer LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'title ASC',
    );

    return Future.wait(maps.map((map) async {
      final piece = Piece.fromJson(map);
      final spots = await getSpotsForPiece(piece.id);
      return piece.copyWith(spots: spots);
    }));
  }

  // ============================================================================
  // SPOTS CRUD OPERATIONS
  // ============================================================================

  /// Insert a new spot
  Future<void> insertSpot(Spot spot) async {
    final db = await database;
    
    // Map Spot model fields to database schema
    final spotData = {
      'id': spot.id,
      'piece_id': spot.pieceId, // Map pieceId to piece_id
      'page_number': spot.pageNumber,
      'rect_x': spot.x,
      'rect_y': spot.y,
      'rect_width': spot.width,
      'rect_height': spot.height,
      'color': spot.color.name,
      'difficulty': spot.priority.index + 1, // Map priority to difficulty (1-5)
      'label': spot.title,
      'next_due': spot.nextDue?.millisecondsSinceEpoch ?? DateTime.now().add(Duration(days: 1)).millisecondsSinceEpoch,
      'is_pinned': spot.isActive ? 1 : 0,
      'created_at': spot.createdAt.millisecondsSinceEpoch,
      'updated_at': spot.updatedAt.millisecondsSinceEpoch,
      'metadata': spot.metadata,
    };
    
    await db.insert(
      'spots',
      spotData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all spots for a piece
  Future<List<Spot>> getSpotsForPiece(String pieceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'spots',
      where: 'piece_id = ?',
      whereArgs: [pieceId],
      orderBy: 'page_number ASC, rect_y ASC',
    );

    return maps.map((map) {
      // Map database fields back to Spot model
      final spotData = {
        'id': map['id'],
        'pieceId': map['piece_id'], // Map piece_id back to pieceId
        'title': map['label'],
        'description': '', // Not stored in this table
        'notes': null,
        'pageNumber': map['page_number'],
        'x': map['rect_x'],
        'y': map['rect_y'],
        'width': map['rect_width'],
        'height': map['rect_height'],
        'priority': SpotPriority.values[(map['difficulty'] ?? 1) - 1].name, // Map difficulty back to priority
        'readinessLevel': ReadinessLevel.learning.name, // Default value
        'color': map['color'],
        'createdAt': DateTime.fromMillisecondsSinceEpoch(map['created_at']).toIso8601String(),
        'updatedAt': DateTime.fromMillisecondsSinceEpoch(map['updated_at']).toIso8601String(),
        'lastPracticed': null,
        'nextDue': map['next_due'] != null ? DateTime.fromMillisecondsSinceEpoch(map['next_due']).toIso8601String() : null,
        'practiceCount': 0,
        'successCount': 0,
        'failureCount': 0,
        'easeFactor': 2.5,
        'interval': 1,
        'repetitions': 0,
        'isActive': (map['is_pinned'] ?? 1) == 1,
        'metadata': map['metadata'],
      };
      
      return Spot.fromJson(spotData);
    }).toList();
  }

  /// Get spot by ID
  Future<Spot?> getSpotById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'spots',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    // Map database fields back to Spot model
    final map = maps.first;
    final spotData = {
      'id': map['id'],
      'pieceId': map['piece_id'], // Map piece_id back to pieceId
      'title': map['label'],
      'description': '', // Not stored in this table
      'notes': null,
      'pageNumber': map['page_number'],
      'x': map['rect_x'],
      'y': map['rect_y'],
      'width': map['rect_width'],
      'height': map['rect_height'],
      'priority': SpotPriority.values[(map['difficulty'] ?? 1) - 1].name, // Map difficulty back to priority
      'readinessLevel': ReadinessLevel.learning.name, // Default value
      'color': map['color'],
      'createdAt': DateTime.fromMillisecondsSinceEpoch(map['created_at']).toIso8601String(),
      'updatedAt': DateTime.fromMillisecondsSinceEpoch(map['updated_at']).toIso8601String(),
      'lastPracticed': null,
      'nextDue': map['next_due'] != null ? DateTime.fromMillisecondsSinceEpoch(map['next_due']).toIso8601String() : null,
      'practiceCount': 0,
      'successCount': 0,
      'failureCount': 0,
      'easeFactor': 2.5,
      'interval': 1,
      'repetitions': 0,
      'isActive': (map['is_pinned'] ?? 1) == 1,
      'metadata': map['metadata'],
    };
    
    return Spot.fromJson(spotData);
  }

  /// Get all spots due before given date
  Future<List<Spot>> getSpotsDueBefore(DateTime dateTime) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'spots',
      where: 'next_due <= ?',
      whereArgs: [dateTime.millisecondsSinceEpoch],
      orderBy: 'next_due ASC',
    );

    return maps.map((map) {
      // Map database fields back to Spot model
      final spotData = {
        'id': map['id'],
        'pieceId': map['piece_id'], // Map piece_id back to pieceId
        'title': map['label'],
        'description': '', // Not stored in this table
        'notes': null,
        'pageNumber': map['page_number'],
        'x': map['rect_x'],
        'y': map['rect_y'],
        'width': map['rect_width'],
        'height': map['rect_height'],
        'priority': SpotPriority.values[(map['difficulty'] ?? 1) - 1].name, // Map difficulty back to priority
        'readinessLevel': ReadinessLevel.learning.name, // Default value
        'color': map['color'],
        'createdAt': DateTime.fromMillisecondsSinceEpoch(map['created_at']).toIso8601String(),
        'updatedAt': DateTime.fromMillisecondsSinceEpoch(map['updated_at']).toIso8601String(),
        'lastPracticed': null,
        'nextDue': map['next_due'] != null ? DateTime.fromMillisecondsSinceEpoch(map['next_due']).toIso8601String() : null,
        'practiceCount': 0,
        'successCount': 0,
        'failureCount': 0,
        'easeFactor': 2.5,
        'interval': 1,
        'repetitions': 0,
        'isActive': (map['is_pinned'] ?? 1) == 1,
        'metadata': map['metadata'],
      };
      
      return Spot.fromJson(spotData);
    }).toList();
  }

  /// Get spots by color
  Future<List<Spot>> getSpotsByColor(SpotColor color) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'spots',
      where: 'color = ?',
      whereArgs: [color.name],
      orderBy: 'next_due ASC',
    );

    return maps.map((map) {
      // Map database fields back to Spot model
      final spotData = {
        'id': map['id'],
        'pieceId': map['piece_id'], // Map piece_id back to pieceId
        'title': map['label'],
        'description': '', // Not stored in this table
        'notes': null,
        'pageNumber': map['page_number'],
        'x': map['rect_x'],
        'y': map['rect_y'],
        'width': map['rect_width'],
        'height': map['rect_height'],
        'priority': SpotPriority.values[(map['difficulty'] ?? 1) - 1].name, // Map difficulty back to priority
        'readinessLevel': ReadinessLevel.learning.name, // Default value
        'color': map['color'],
        'createdAt': DateTime.fromMillisecondsSinceEpoch(map['created_at']).toIso8601String(),
        'updatedAt': DateTime.fromMillisecondsSinceEpoch(map['updated_at']).toIso8601String(),
        'lastPracticed': null,
        'nextDue': map['next_due'] != null ? DateTime.fromMillisecondsSinceEpoch(map['next_due']).toIso8601String() : null,
        'practiceCount': 0,
        'successCount': 0,
        'failureCount': 0,
        'easeFactor': 2.5,
        'interval': 1,
        'repetitions': 0,
        'isActive': (map['is_pinned'] ?? 1) == 1,
        'metadata': map['metadata'],
      };
      
      return Spot.fromJson(spotData);
    }).toList();
  }

  /// Update spot
  Future<void> updateSpot(Spot spot) async {
    final db = await database;
    await db.update(
      'spots',
      spot.toJson(),
      where: 'id = ?',
      whereArgs: [spot.id],
    );
  }

  /// Delete spot and all associated data
  Future<void> deleteSpot(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('spot_history', where: 'spot_id = ?', whereArgs: [id]);
      await txn.delete('spot_sessions', where: 'spot_id = ?', whereArgs: [id]);
      await txn.delete('spots', where: 'id = ?', whereArgs: [id]);
    });
  }

  // ============================================================================
  // SPOT HISTORY OPERATIONS
  // ============================================================================

  /// Insert spot history record
  Future<void> insertSpotHistory(SpotHistory history) async {
    final db = await database;
    await db.insert(
      'spot_history',
      history.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get history for a spot
  Future<List<SpotHistory>> getSpotHistory(String spotId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'spot_history',
      where: 'spot_id = ?',
      whereArgs: [spotId],
      orderBy: 'session_date DESC',
    );

    return maps.map((map) => SpotHistory.fromJson(map)).toList();
  }

  /// Get recent practice statistics
  Future<Map<String, dynamic>> getPracticeStats(int days) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_sessions,
        SUM(CASE WHEN result = 'success' THEN 1 ELSE 0 END) as successful_sessions,
        AVG(session_duration) as avg_duration
      FROM spot_history 
      WHERE session_date >= ?
    ''', [cutoffDate.millisecondsSinceEpoch]);

    return results.first;
  }

  // ============================================================================
  // PRACTICE SESSIONS OPERATIONS
  // ============================================================================

  /// Insert practice session
  Future<void> insertPracticeSession(PracticeSession session) async {
    print('[DatabaseService] Inserting practice session: ${session.id}');
    try {
      final db = await database;
      await db.transaction((txn) async {
        print('[DatabaseService] Inserting session data: ${session.toJson()}');
        await txn.insert(
          'practice_sessions',
          session.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        
        // Insert spot sessions
        print('[DatabaseService] Inserting ${session.spotSessions.length} spot sessions');
        for (final spotSession in session.spotSessions) {
          await txn.insert(
            'spot_sessions',
            spotSession.toJson(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
      print('[DatabaseService] ✅ Practice session inserted successfully: ${session.id}');
    } catch (e) {
      print('[DatabaseService] ❌ Error inserting practice session: $e');
      rethrow;
    }
  }

  /// Get practice session by ID
  Future<PracticeSession?> getPracticeSessionById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'practice_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final session = PracticeSession.fromJson(maps.first);
    final spotSessions = await getSpotSessionsForSession(id);
    return session.copyWith(spotSessions: spotSessions);
  }

  /// Get spot sessions for a practice session
  Future<List<SpotSession>> getSpotSessionsForSession(String sessionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'spot_sessions',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'order_index ASC',
    );

    return maps.map((map) => SpotSession.fromJson(map)).toList();
  }

  /// Update practice session
  Future<void> updatePracticeSession(PracticeSession session) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'practice_sessions',
        session.toJson(),
        where: 'id = ?',
        whereArgs: [session.id],
      );
      
      // Delete existing spot sessions and re-insert
      await txn.delete(
        'spot_sessions',
        where: 'session_id = ?',
        whereArgs: [session.id],
      );
      
      for (final spotSession in session.spotSessions) {
        await txn.insert(
          'spot_sessions',
          spotSession.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Get recent practice sessions
  Future<List<PracticeSession>> getRecentPracticeSessions({int days = 7, int? limit}) async {
    final db = await database;
    final cutoffTime = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    
    final results = await db.query(
      'practice_sessions',
      where: 'created_at >= ?',
      whereArgs: [cutoffTime],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    
    List<PracticeSession> sessions = [];
    for (final row in results) {
      final spotSessions = await _getSpotSessionsForPracticeSession(row['id'] as String);
      sessions.add(_practiceSessionFromMap(row, spotSessions));
    }
    
    return sessions;
  }

  // ============================================================================
  // PROJECTS OPERATIONS  
  // ============================================================================

  /// Insert project
  Future<void> insertProject(Project project) async {
    final db = await database;
    await db.insert(
      'projects',
      project.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all projects
  Future<List<Project>> getAllProjects() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'projects',
      orderBy: 'concert_date ASC, name ASC',
    );

    return maps.map((map) => Project.fromJson(map)).toList();
  }

  /// Get project by ID
  Future<Project?> getProjectById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Project.fromJson(maps.first);
  }

  /// Update project
  Future<void> updateProject(Project project) async {
    final db = await database;
    await db.update(
      'projects',
      project.toJson(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  /// Delete project
  Future<void> deleteProject(String id) async {
    final db = await database;
    await db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  // ============================================================================
  // UTILITY OPERATIONS
  // ============================================================================

  /// Close database connection
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Get today's practice sessions
  Future<List<PracticeSession>> getTodayPracticeSessions() async {
    print('[DatabaseService] Getting today\'s practice sessions');
    final db = await database;
    final todayStart = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0).millisecondsSinceEpoch;
    final todayEnd = DateTime.now().copyWith(hour: 23, minute: 59, second: 59, millisecond: 999).millisecondsSinceEpoch;
    
    print('[DatabaseService] Searching for sessions between $todayStart and $todayEnd');
    
    final results = await db.query(
      'practice_sessions',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [todayStart, todayEnd],
      orderBy: 'created_at DESC',
    );
    
    print('[DatabaseService] Found ${results.length} practice sessions for today');
    
    List<PracticeSession> sessions = [];
    for (final row in results) {
      print('[DatabaseService] Processing session: ${row['id']}');
      final spotSessions = await _getSpotSessionsForPracticeSession(row['id'] as String);
      sessions.add(_practiceSessionFromMap(row, spotSessions));
    }
    
    print('[DatabaseService] Returning ${sessions.length} practice sessions');
    return sessions;
  }

  /// Get spot history since a certain date
  Future<List<SpotHistory>> getSpotHistorySince(DateTime since) async {
    final db = await database;
    
    final results = await db.query(
      'spot_history',
      where: 'session_date >= ?',
      whereArgs: [since.millisecondsSinceEpoch],
      orderBy: 'session_date DESC',
    );
    
    return results.map((row) => _spotHistoryFromMap(row)).toList();
  }

  /// Helper method to get spot sessions for a practice session
  Future<List<SpotSession>> _getSpotSessionsForPracticeSession(String sessionId) async {
    final db = await database;
    
    final results = await db.query(
      'spot_sessions',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'order_index ASC',
    );
    
    return results.map((row) => _spotSessionFromMap(row)).toList();
  }

  /// Convert database row to PracticeSession
  PracticeSession _practiceSessionFromMap(Map<String, dynamic> map, List<SpotSession> spotSessions) {
    return PracticeSession(
      id: map['id'] as String,
      name: map['name'] as String,
      type: SessionType.values.firstWhere(
        (t) => t.toString() == map['type'],
        orElse: () => SessionType.smart,
      ),
      status: SessionStatus.values.firstWhere(
        (s) => s.toString() == map['status'],
        orElse: () => SessionStatus.planned,
      ),
      startTime: map['start_time'] != null ? DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int) : null,
      endTime: map['end_time'] != null ? DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int) : null,
      plannedDuration: Duration(milliseconds: map['planned_duration'] as int),
      spotSessions: spotSessions,
      microBreaksEnabled: (map['micro_breaks_enabled'] as int) == 1,
      microBreakInterval: Duration(milliseconds: map['micro_break_interval'] as int),
      microBreakDuration: Duration(milliseconds: map['micro_break_duration'] as int),
      projectId: map['project_id'] as String?,
      metadata: map['metadata'] != null ? 
        (map['metadata'] as String).isEmpty ? null : 
        Map<String, dynamic>.from(jsonDecode(map['metadata'] as String)) : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// Convert database row to SpotSession
  SpotSession _spotSessionFromMap(Map<String, dynamic> map) {
    return SpotSession(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      spotId: map['spot_id'] as String,
      orderIndex: map['order_index'] as int,
      allocatedTime: Duration(milliseconds: map['allocated_time'] as int),
      status: SpotSessionStatus.values.firstWhere(
        (s) => s.toString() == map['status'],
        orElse: () => SpotSessionStatus.pending,
      ),
      startTime: map['start_time'] != null ? DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int) : null,
      endTime: map['end_time'] != null ? DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int) : null,
      result: map['result'] != null ? SpotResult.values.firstWhere(
        (r) => r.toString() == map['result'],
        orElse: () => SpotResult.failed,
      ) : null,
      notes: map['notes'] as String?,
      metadata: map['metadata'] != null ? 
        (map['metadata'] as String).isEmpty ? null : 
        Map<String, dynamic>.from(jsonDecode(map['metadata'] as String)) : null,
    );
  }

  /// Convert database row to SpotHistory
  SpotHistory _spotHistoryFromMap(Map<String, dynamic> map) {
    return SpotHistory(
      id: map['id'] as String,
      spotId: map['spot_id'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['session_date'] as int),
      result: SpotResult.values.firstWhere(
        (r) => r.toString() == map['result'],
        orElse: () => SpotResult.failed,
      ),
      practiceTimeMinutes: map['session_duration'] as int? ?? 0,
      notes: map['notes'] as String?,
      metadata: map['metadata'] != null ? 
        (map['metadata'] as String).isEmpty ? null : 
        Map<String, dynamic>.from(jsonDecode(map['metadata'] as String)) : null,
    );
  }

  /// Delete all data (for testing/reset)
  Future<void> deleteAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('spot_history');
      await txn.delete('spot_sessions');
      await txn.delete('practice_sessions');
      await txn.delete('spots');
      await txn.delete('pieces');
      await txn.delete('projects');
    });
  }

  /// Get database file size
  Future<int> getDatabaseSize() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    final file = File(path);
    
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// Get all spots
  /// Get all practice sessions from the database
  Future<List<PracticeSession>> getAllPracticeSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'practice_sessions',
      orderBy: 'created_at DESC',
    );
    
    List<PracticeSession> sessions = [];
    for (final map in maps) {
      // Get spot sessions for this practice session
      final spotSessions = await getSpotSessionsForSession(map['id'] as String);
      sessions.add(_practiceSessionFromMap(map, spotSessions));
    }
    
    return sessions;
  }

  /// Get all spots from the database
  Future<List<Spot>> getAllSpots() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('spots');
    
    List<Spot> spots = [];
    for (final map in maps) {
      // Convert database field names to match Spot model
      final spotData = <String, dynamic>{
        'id': map['id'],
        'pieceId': map['piece_id'], // Map piece_id to pieceId
        'title': map['title'],
        'description': map['description'],
        'notes': map['notes'],
        'pageNumber': map['page_number'] as int,
        'x': map['x'] as double,
        'y': map['y'] as double,
        'width': map['width'] as double,
        'height': map['height'] as double,
        'priority': map['priority'],
        'readinessLevel': map['readiness_level'],
        'color': map['color'],
        'createdAt': map['created_at'],
        'updatedAt': map['updated_at'],
        'lastPracticed': map['last_practiced'],
        'nextDue': map['next_due'],
        'practiceCount': map['practice_count'] as int,
        'successCount': map['success_count'] as int,
        'failureCount': map['failure_count'] as int,
        'easeFactor': map['ease_factor'] as double,
        'interval': map['interval'] as int,
        'repetitions': map['repetitions'] as int,
        'recommendedPracticeTime': map['recommended_practice_time'] as int?,
        'isActive': (map['is_active'] as int) == 1,
        'metadata': map['metadata'],
      };
      spots.add(Spot.fromJson(spotData));
    }
    
    return spots;
  }

  /// Get project by ID
  Future<Project?> getProject(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return Project.fromJson(maps.first);
    }
    return null;
  }

  /// Save project
  Future<void> saveProject(Project project) async {
    final db = await database;
    await db.insert(
      'projects',
      project.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ============================================================================
  // BOOKMARK CRUD OPERATIONS
  // ============================================================================

  /// Insert bookmark
  Future<void> insertBookmark(Bookmark bookmark) async {
    final db = await database;
    await db.insert(
      'bookmarks',
      bookmark.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all bookmarks for a piece
  Future<List<Bookmark>> getBookmarksForPiece(String pieceId) async {
    final db = await database;
    final maps = await db.query(
      'bookmarks',
      where: 'pdf_id = ?',
      whereArgs: [pieceId],
      orderBy: 'page_number ASC',
    );

    return List.generate(maps.length, (i) {
      return Bookmark.fromMap(maps[i]);
    });
  }

  /// Update bookmark
  Future<void> updateBookmark(Bookmark bookmark) async {
    final db = await database;
    await db.update(
      'bookmarks',
      bookmark.toMap(),
      where: 'id = ?',
      whereArgs: [bookmark.id],
    );
  }

  /// Delete bookmark
  Future<void> deleteBookmark(String bookmarkId) async {
    final db = await database;
    await db.delete(
      'bookmarks',
      where: 'id = ?',
      whereArgs: [bookmarkId],
    );
  }

  // ============================================================================
  // ANNOTATION CRUD OPERATIONS
  // ============================================================================

  /// Insert annotation
  Future<void> insertAnnotation(Annotation annotation) async {
    final db = await database;
    final data = annotation.toJson();
    
    // Convert complex data to JSON strings
    data['path'] = jsonEncode(data['path']);
    data['bounds'] = data['bounds'] != null ? jsonEncode(data['bounds']) : null;
    data['metadata'] = data['metadata'] != null ? jsonEncode(data['metadata']) : null;
    
    await db.insert(
      'annotations',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all annotations for a piece
  Future<List<Annotation>> getAnnotationsForPiece(String pieceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'annotations',
      where: 'piece_id = ?',
      whereArgs: [pieceId],
    );
    
    return maps.map((map) => _annotationFromMap(map)).toList();
  }

  /// Update annotation
  Future<void> updateAnnotation(Annotation annotation) async {
    final db = await database;
    final data = annotation.toJson();
    
    // Convert complex data to JSON strings
    data['path'] = jsonEncode(data['path']);
    data['bounds'] = data['bounds'] != null ? jsonEncode(data['bounds']) : null;
    data['metadata'] = data['metadata'] != null ? jsonEncode(data['metadata']) : null;
    
    await db.update(
      'annotations',
      data,
      where: 'id = ?',
      whereArgs: [annotation.id],
    );
  }

  /// Delete annotation
  Future<void> deleteAnnotation(String annotationId) async {
    final db = await database;
    await db.delete(
      'annotations',
      where: 'id = ?',
      whereArgs: [annotationId],
    );
  }

  /// Delete all annotations for a piece
  Future<void> deleteAnnotationsForPiece(String pieceId) async {
    final db = await database;
    await db.delete(
      'annotations',
      where: 'piece_id = ?',
      whereArgs: [pieceId],
    );
  }

  /// Insert annotation layer
  Future<void> insertAnnotationLayer(AnnotationLayer layer) async {
    final db = await database;
    await db.insert(
      'annotation_layers',
      layer.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all annotation layers
  Future<List<AnnotationLayer>> getAnnotationLayers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('annotation_layers');
    
    return maps.map((map) => AnnotationLayer.fromJson(map)).toList();
  }

  /// Update annotation layer
  Future<void> updateAnnotationLayer(AnnotationLayer layer) async {
    final db = await database;
    await db.update(
      'annotation_layers',
      layer.toJson(),
      where: 'id = ?',
      whereArgs: [layer.id],
    );
  }

  /// Delete annotation layer
  Future<void> deleteAnnotationLayer(String layerId) async {
    final db = await database;
    await db.delete(
      'annotation_layers',
      where: 'id = ?',
      whereArgs: [layerId],
    );
  }

  /// Convert database map to Annotation
  Annotation _annotationFromMap(Map<String, dynamic> map) {
    // Parse JSON strings back to objects
    final pathData = map['path'] != null ? jsonDecode(map['path']) as List : <dynamic>[];
    final boundsData = map['bounds'] != null ? jsonDecode(map['bounds']) as Map<String, dynamic>? : null;
    final metadataData = map['metadata'] != null ? jsonDecode(map['metadata']) as Map<String, dynamic>? : null;
    
    return Annotation(
      id: map['id'],
      pieceId: map['piece_id'],
      page: map['page'],
      layerId: map['layer_id'],
      colorTag: ColorTag.values[map['color_tag']],
      tool: AnnotationTool.values[map['tool']],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      data: _buildAnnotationData(map, pathData), // Use new data field
      bounds: boundsData != null ? Rect.fromLTRB(
        boundsData['left'].toDouble(),
        boundsData['top'].toDouble(),
        boundsData['right'].toDouble(),
        boundsData['bottom'].toDouble(),
      ) : null,
      metadata: metadataData,
    );
  }
  
  /// Helper method to build annotation data based on tool type
  dynamic _buildAnnotationData(Map<String, dynamic> map, List<dynamic> pathData) {
    final tool = AnnotationTool.values[map['tool']];
    
    switch (tool) {
      case AnnotationTool.pen:
      case AnnotationTool.highlighter:
        return VectorPath(
          points: pathData.map((p) => Offset(p['x'].toDouble(), p['y'].toDouble())).toList(),
          strokeWidth: map['stroke_width']?.toDouble() ?? 2.0,
          color: Color(map['color'] ?? 0xFF000000),
          blendMode: tool == AnnotationTool.highlighter ? BlendMode.multiply : BlendMode.srcOver,
        );
      case AnnotationTool.text:
        return TextData(
          text: map['text'] ?? '',
          position: pathData.isNotEmpty 
            ? Offset(pathData[0]['x'].toDouble(), pathData[0]['y'].toDouble())
            : Offset.zero,
          fontSize: map['font_size']?.toDouble() ?? 12.0,
          color: Color(map['color'] ?? 0xFF000000),
        );
      case AnnotationTool.stamp:
        return StampData(
          type: StampType.values.firstWhere(
            (e) => e.toString().split('.').last == map['stamp_type'],
            orElse: () => StampType.fingering1,
          ),
          position: pathData.isNotEmpty 
            ? Offset(pathData[0]['x'].toDouble(), pathData[0]['y'].toDouble())
            : Offset.zero,
          size: map['stamp_size']?.toDouble() ?? 24.0,
          color: Color(map['color'] ?? 0xFF000000),
        );
      default:
        return VectorPath(
          points: pathData.map((p) => Offset(p['x'].toDouble(), p['y'].toDouble())).toList(),
          strokeWidth: 2.0,
          color: Colors.black,
          blendMode: BlendMode.srcOver,
        );
    }
  }
}

// Provider for DatabaseService
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});
