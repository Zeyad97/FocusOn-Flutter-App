import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/piece.dart';
import '../models/spot.dart';
import 'spot_service.dart';
import 'database_service.dart';

class PieceService {
  final DatabaseService _databaseService;
  
  PieceService(this._databaseService);
  
  Future<void> savePiece(Piece piece) async {
    // Debug logging
    print('PieceService: Saving piece "${piece.title}" (id: ${piece.id})');
    
    try {
      await _databaseService.insertPiece(piece);
      print('PieceService: Piece saved successfully to database');
      
      // Don't auto-create spots - let users create them manually
    } catch (e) {
      if (e.toString().contains('has no column named')) {
        print('PieceService: Database schema mismatch, recreating database...');
        await _databaseService.recreateDatabase();
        // Retry the insert
        await _databaseService.insertPiece(piece);
        print('PieceService: Piece saved successfully after database recreation');
      } else {
        rethrow;
      }
    }
  }
  
  // Removed _createDefaultSpot method - no longer auto-creating spots
  
  Future<Piece?> getPiece(String id) async {
    return await _databaseService.getPieceById(id);
  }
  
  Future<List<Piece>> getAllPieces() async {
    return await _databaseService.getAllPieces();
  }
  
  Future<List<Piece>> getPiecesForProject(String projectId) async {
    final allPieces = await _databaseService.getAllPieces();
    return allPieces.where((piece) => piece.projectId == projectId).toList();
  }
  
  Future<void> deletePiece(String id) async {
    await _databaseService.deletePiece(id);
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
      
      // Don't auto-create spots - pieces can exist without spots
      piecesWithProgress.add(piece.copyWith(spots: spots));
    }
    
    return piecesWithProgress;
  }
  
  /// Initialize piece service
  Future<void> initializeService() async {
    final pieces = await getAllPieces();
    debugPrint('PieceService: Initialized with ${pieces.length} pieces from database');
  }
}

final pieceServiceProvider = Provider<PieceService>((ref) {
  final databaseService = ref.read(databaseServiceProvider);
  return PieceService(databaseService);
});
