import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/piece.dart';
import '../services/piece_service.dart';
import '../services/spot_service.dart';

class UnifiedLibraryNotifier extends StateNotifier<AsyncValue<List<Piece>>> {
  final PieceService _pieceService;
  final SpotService _spotService;
  
  UnifiedLibraryNotifier(this._pieceService, this._spotService) : super(const AsyncValue.loading()) {
    _loadLibrary();
  }
  
  Future<void> _loadLibrary() async {
    try {
      // Load all pieces with real progress from spots
      final pieces = await _pieceService.getAllPiecesWithProgress(_spotService);
      
      state = AsyncValue.data(pieces);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadLibrary();
  }
  
  Future<void> addPiece(Piece piece) async {
    print('UnifiedLibraryProvider: addPiece called for "${piece.title}" (id: ${piece.id})');
    await _pieceService.savePiece(piece);
    print('UnifiedLibraryProvider: piece saved, reloading library...');
    await _loadLibrary();
    print('UnifiedLibraryProvider: library reloaded');
  }
  
  Future<void> updatePiece(Piece piece) async {
    await _pieceService.savePiece(piece);
    await _loadLibrary();
  }
  
  Future<void> deletePiece(String pieceId) async {
    await _pieceService.deletePiece(pieceId);
    await _loadLibrary();
  }
  
  Future<void> updateLastOpened(String pieceId) async {
    final piece = await _pieceService.getPiece(pieceId);
    if (piece != null) {
      final updatedPiece = piece.copyWith(
        lastOpened: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _pieceService.savePiece(updatedPiece);
      await _loadLibrary();
    }
  }
  
  Future<void> toggleFavorite(String pieceId) async {
    print('UnifiedLibraryProvider: toggleFavorite called for piece $pieceId');
    
    // Update the database first
    final piece = await _pieceService.getPiece(pieceId);
    if (piece != null) {
      final newFavoriteStatus = !piece.isFavorite;
      final updatedPiece = piece.copyWith(
        isFavorite: newFavoriteStatus,
        updatedAt: DateTime.now(),
      );
      print('UnifiedLibraryProvider: Saving piece ${piece.title} with favorite status: ${newFavoriteStatus}');
      await _pieceService.savePiece(updatedPiece);
      
      // Force immediate state update
      print('UnifiedLibraryProvider: Forcing state reload');
      await _loadLibrary();
      print('UnifiedLibraryProvider: State reloaded');
    }
  }
}

final unifiedLibraryProvider = StateNotifierProvider<UnifiedLibraryNotifier, AsyncValue<List<Piece>>>((ref) {
  final pieceService = ref.watch(pieceServiceProvider);
  final spotService = ref.watch(spotServiceProvider);
  return UnifiedLibraryNotifier(pieceService, spotService);
});
