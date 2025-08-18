import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/piece.dart';
import '../models/spot.dart';
import 'spot_service.dart';

class PieceService {
  static Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pieces.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }
  
  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pieces (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        composer TEXT NOT NULL,
        keySignature TEXT,
        difficulty INTEGER NOT NULL,
        tags TEXT,
        concertDate TEXT,
        lastOpened TEXT,
        lastViewedPage INTEGER,
        lastZoom REAL,
        viewMode TEXT,
        pdfFilePath TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        projectId TEXT,
        metadata TEXT,
        totalTimeSpent INTEGER DEFAULT 0,
        thumbnailPath TEXT,
        totalPages INTEGER DEFAULT 0,
        targetTempo REAL,
        currentTempo REAL
      )
    ''');
    
    await db.execute('CREATE INDEX idx_pieces_project ON pieces(projectId)');
    await db.execute('CREATE INDEX idx_pieces_updated ON pieces(updatedAt)');
  }
  
  Future<void> savePiece(Piece piece) async {
    final db = await database;
    
    // Debug logging
    print('PieceService: Saving piece "${piece.title}" (id: ${piece.id})');
    
    await db.insert(
      'pieces',
      _pieceToMap(piece),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    print('PieceService: Piece saved successfully');
  }
  
  Future<Piece?> getPiece(String id) async {
    final db = await database;
    final maps = await db.query(
      'pieces',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return _mapToPiece(maps.first);
  }
  
  Future<List<Piece>> getAllPieces() async {
    final db = await database;
    final maps = await db.query(
      'pieces',
      orderBy: 'updatedAt DESC',
    );
    
    return maps.map((map) => _mapToPiece(map)).toList();
  }
  
  Future<List<Piece>> getPiecesForProject(String projectId) async {
    final db = await database;
    final maps = await db.query(
      'pieces',
      where: 'projectId = ?',
      whereArgs: [projectId],
      orderBy: 'updatedAt DESC',
    );
    
    return maps.map((map) => _mapToPiece(map)).toList();
  }
  
  Future<void> deletePiece(String id) async {
    final db = await database;
    await db.delete(
      'pieces',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  /// Get piece with calculated progress from spots
  Future<Piece?> getPieceWithProgress(String id, SpotService spotService) async {
    final piece = await getPiece(id);
    if (piece == null) return null;
    
    // Get spots for this piece
    final spots = await spotService.getSpotsForPiece(id);
    
    // Create piece with real spots data
    return piece.copyWith(
      spots: spots,
    );
  }
  
  /// Get all pieces with real progress calculated from spots
  Future<List<Piece>> getAllPiecesWithProgress(SpotService spotService) async {
    final pieces = await getAllPieces();
    final piecesWithProgress = <Piece>[];
    
    for (final piece in pieces) {
      final spots = await spotService.getSpotsForPiece(piece.id);
      piecesWithProgress.add(piece.copyWith(spots: spots));
    }
    
    return piecesWithProgress;
  }
  
  /// Create initial sample pieces if database is empty
  Future<void> createSamplePiecesIfEmpty() async {
    final pieces = await getAllPieces();
    if (pieces.isNotEmpty) return;
    
    final now = DateTime.now();
    final samplePieces = [
      Piece(
        id: '1',
        title: 'Nocturne in E-flat major',
        composer: 'Frédéric Chopin',
        keySignature: 'Eb major',
        difficulty: 4,
        tags: ['Classical', 'Romantic', 'Piano'],
        pdfFilePath: 'assets/pdfs/chopin_nocturne.pdf',
        spots: [],
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
        totalPages: 4,
      ),
      Piece(
        id: '2',
        title: 'Clair de Lune',
        composer: 'Claude Debussy',
        keySignature: 'Db major',
        difficulty: 5,
        tags: ['Classical', 'Impressionist', 'Piano'],
        pdfFilePath: 'assets/pdfs/debussy_clair.pdf',
        spots: [],
        createdAt: now.subtract(const Duration(days: 12)),
        updatedAt: now.subtract(const Duration(days: 12)),
        totalPages: 6,
      ),
      Piece(
        id: '3',
        title: 'Autumn Leaves',
        composer: 'Joseph Kosma',
        keySignature: 'Bb major',
        difficulty: 2,
        tags: ['Jazz', 'Standards', 'Piano'],
        pdfFilePath: 'assets/pdfs/autumn_leaves.pdf',
        spots: [],
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
        totalPages: 3,
      ),
      Piece(
        id: '4',
        title: 'Moonlight Sonata',
        composer: 'Ludwig van Beethoven',
        keySignature: 'C# minor',
        difficulty: 4,
        tags: ['Classical', 'Piano', 'Sonata'],
        pdfFilePath: 'assets/pdfs/beethoven_moonlight.pdf',
        spots: [],
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 20)),
        totalPages: 8,
      ),
      Piece(
        id: '5',
        title: 'The Girl from Ipanema',
        composer: 'Antonio Carlos Jobim',
        keySignature: 'F major',
        difficulty: 1,
        tags: ['Bossa Nova', 'Jazz', 'Piano'],
        pdfFilePath: 'assets/pdfs/girl_ipanema.pdf',
        spots: [],
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 7)),
        totalPages: 2,
      ),
      Piece(
        id: '6',
        title: 'Imagine',
        composer: 'John Lennon',
        keySignature: 'C major',
        difficulty: 1,
        tags: ['Pop', 'Piano', 'Ballad'],
        pdfFilePath: 'assets/pdfs/imagine.pdf',
        spots: [],
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
        totalPages: 3,
      ),
    ];
    
    for (final piece in samplePieces) {
      await savePiece(piece);
    }
  }
  
  Map<String, dynamic> _pieceToMap(Piece piece) {
    return {
      'id': piece.id,
      'title': piece.title,
      'composer': piece.composer,
      'keySignature': piece.keySignature,
      'difficulty': piece.difficulty,
      'tags': piece.tags.join(','),
      'concertDate': piece.concertDate?.toIso8601String(),
      'lastOpened': piece.lastOpened?.toIso8601String(),
      'lastViewedPage': piece.lastViewedPage,
      'lastZoom': piece.lastZoom,
      'viewMode': piece.viewMode,
      'pdfFilePath': piece.pdfFilePath,
      'createdAt': piece.createdAt.toIso8601String(),
      'updatedAt': piece.updatedAt.toIso8601String(),
      'projectId': piece.projectId,
      'metadata': piece.metadata?.toString(),
      'totalTimeSpent': piece.totalTimeSpent.inMinutes,
      'thumbnailPath': piece.thumbnailPath,
      'totalPages': piece.totalPages,
      'targetTempo': piece.targetTempo,
      'currentTempo': piece.currentTempo,
    };
  }
  
  Piece _mapToPiece(Map<String, dynamic> map) {
    return Piece(
      id: map['id'],
      title: map['title'],
      composer: map['composer'],
      keySignature: map['keySignature'],
      difficulty: map['difficulty'],
      tags: map['tags'] != null ? map['tags'].split(',') : [],
      concertDate: map['concertDate'] != null 
          ? DateTime.parse(map['concertDate']) 
          : null,
      lastOpened: map['lastOpened'] != null 
          ? DateTime.parse(map['lastOpened']) 
          : null,
      lastViewedPage: map['lastViewedPage'],
      lastZoom: map['lastZoom'],
      viewMode: map['viewMode'],
      pdfFilePath: map['pdfFilePath'],
      spots: [], // Loaded separately for performance
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      projectId: map['projectId'],
      metadata: map['metadata'] != null ? {} : null,
      totalTimeSpent: Duration(minutes: map['totalTimeSpent'] ?? 0),
      thumbnailPath: map['thumbnailPath'],
      totalPages: map['totalPages'] ?? 0,
      targetTempo: map['targetTempo'],
      currentTempo: map['currentTempo'],
    );
  }
}

final pieceServiceProvider = Provider<PieceService>((ref) => PieceService());
