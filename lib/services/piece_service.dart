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
      
      // Create a default practice spot if the piece has no spots
      if (piece.spots.isEmpty) {
        await _createDefaultSpot(piece);
      }
    } catch (e) {
      if (e.toString().contains('has no column named')) {
        print('PieceService: Database schema mismatch, recreating database...');
        await _databaseService.recreateDatabase();
        // Retry the insert
        await _databaseService.insertPiece(piece);
        print('PieceService: Piece saved successfully after database recreation');
        
        // Create default spot after successful save
        if (piece.spots.isEmpty) {
          await _createDefaultSpot(piece);
        }
      } else {
        rethrow;
      }
    }
  }
  
  Future<void> _createDefaultSpot(Piece piece) async {
    try {
      // Create a default "Full Piece" spot
      final defaultSpot = Spot(
        id: 'default_${piece.id}_${DateTime.now().millisecondsSinceEpoch}',
        pieceId: piece.id,
        title: 'Full Piece',
        description: 'Practice the entire piece',
        pageNumber: 1,
        x: 0.0,
        y: 0.0,
        width: 1.0,
        height: 1.0,
        priority: SpotPriority.medium,
        readinessLevel: ReadinessLevel.learning,
        color: SpotColor.blue, // Default to practice (blue)
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Save the spot to database using DatabaseService
      await _databaseService.insertSpot(defaultSpot);
      print('PieceService: Created default practice spot for piece "${piece.title}"');
    } catch (e) {
      print('PieceService: Failed to create default spot: $e');
      // Don't throw - spot creation is optional
    }
  }
  
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
    final spots = await _databaseService.getSpotsForPiece(id);
    
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
      final spots = await _databaseService.getSpotsForPiece(piece.id);
      
      // If piece has no spots, create a default one
      if (spots.isEmpty) {
        await _createDefaultSpot(piece);
        // Reload spots after creating default spot
        final updatedSpots = await _databaseService.getSpotsForPiece(piece.id);
        piecesWithProgress.add(piece.copyWith(spots: updatedSpots));
      } else {
        piecesWithProgress.add(piece.copyWith(spots: spots));
      }
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
