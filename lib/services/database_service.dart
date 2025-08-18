import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/piece.dart';
import '../models/spot.dart';
import '../models/practice_session.dart';
import '../models/project.dart';

/// Core database service for FocusON Scores
/// Handles all data persistence with SQLite
class DatabaseService {
  static const String _databaseName = 'focuson_scores.db';
  static const int _databaseVersion = 1;

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
        concert_date INTEGER,
        last_opened INTEGER,
        pdf_file_path TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        project_id TEXT,
        metadata TEXT
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
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future schema migrations here
  }

  // ============================================================================
  // PIECES CRUD OPERATIONS
  // ============================================================================

  /// Insert a new piece
  Future<void> insertPiece(Piece piece) async {
    final db = await database;
    await db.insert(
      'pieces',
      piece.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
    await db.insert(
      'spots',
      spot.toJson(),
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

    return Future.wait(maps.map((map) async {
      final spot = Spot.fromJson(map);
      final history = await getSpotHistory(spot.id);
      return spot.copyWith(history: history);
    }));
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

    final spot = Spot.fromJson(maps.first);
    final history = await getSpotHistory(id);
    return spot.copyWith(history: history);
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

    return Future.wait(maps.map((map) async {
      final spot = Spot.fromJson(map);
      final history = await getSpotHistory(spot.id);
      return spot.copyWith(history: history);
    }));
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

    return Future.wait(maps.map((map) async {
      final spot = Spot.fromJson(map);
      final history = await getSpotHistory(spot.id);
      return spot.copyWith(history: history);
    }));
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
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'practice_sessions',
        session.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // Insert spot sessions
      for (final spotSession in session.spotSessions) {
        await txn.insert(
          'spot_sessions',
          spotSession.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
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
  Future<List<PracticeSession>> getRecentPracticeSessions({int limit = 10}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'practice_sessions',
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return Future.wait(maps.map((map) async {
      final session = PracticeSession.fromJson(map);
      final spotSessions = await getSpotSessionsForSession(session.id);
      return session.copyWith(spotSessions: spotSessions);
    }));
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
}
