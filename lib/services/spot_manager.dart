import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/db_helper.dart';
import '../models/practice_spot.dart';

/// Simple service for managing practice spots with UI integration
/// This provides a clean interface between the UI and the database
class SpotManager {
  
  // ====================================================================
  // BASIC SPOT OPERATIONS - Direct mapping to your requirements
  // ====================================================================

  /// Create a new practice spot when user marks the PDF
  static Future<int> createSpot({
    required String pieceName,
    required int pageNumber,
    required double x,
    required double y,
    required double width,
    required double height,
    required String color,
    String? title,
    String? description,
    String priority = 'medium',
  }) async {
    final spot = PracticeSpot.create(
      piece: pieceName,
      page: pageNumber,
      x: x,
      y: y,
      width: width,
      height: height,
      color: color,
      title: title,
      description: description,
      priority: priority,
    );

    final id = await DBHelper.insertSpot(spot);
    print('SpotManager: Created new spot "$title" on page $pageNumber');
    return id;
  }

  /// Update a practice spot
  static Future<bool> updateSpot(PracticeSpot spot) async {
    final updatedSpot = spot.copyWith(
      updatedAt: DateTime.now().toIso8601String(),
    );
    
    final rowsAffected = await DBHelper.updateSpot(updatedSpot);
    return rowsAffected > 0;
  }

  /// Delete a practice spot
  static Future<bool> deleteSpot(int spotId) async {
    final rowsAffected = await DBHelper.deleteSpot(spotId);
    return rowsAffected > 0;
  }

  /// Get all spots for a PDF piece (for loading and displaying)
  static Future<List<PracticeSpot>> getSpotsForPiece(String pieceName) async {
    return await DBHelper.getSpotsForPiece(pieceName);
  }

  /// Get spots for a specific page (for PDF viewer overlay)
  static Future<List<PracticeSpot>> getSpotsForPage(String pieceName, int pageNumber) async {
    return await DBHelper.getSpotsForPage(pieceName, pageNumber);
  }

  // ====================================================================
  // PRACTICE OPERATIONS
  // ====================================================================

  /// Record a practice session for a spot
  static Future<void> recordPractice({
    required int spotId,
    required int durationMinutes,
    int? qualityScore, // 1-5 rating
    String? notes,
  }) async {
    await DBHelper.recordPractice(
      spotId: spotId,
      durationMinutes: durationMinutes,
      qualityScore: qualityScore,
      notes: notes,
    );

    // Update readiness based on practice quality
    final spot = await DBHelper.getSpot(spotId);
    if (spot != null) {
      int newReadiness = spot.readiness;
      
      if (qualityScore != null) {
        // Simple readiness calculation based on quality
        switch (qualityScore) {
          case 5: newReadiness = (newReadiness + 20).clamp(0, 100); break;
          case 4: newReadiness = (newReadiness + 10).clamp(0, 100); break;
          case 3: newReadiness = (newReadiness + 5).clamp(0, 100); break;
          case 2: newReadiness = (newReadiness - 5).clamp(0, 100); break;
          case 1: newReadiness = (newReadiness - 10).clamp(0, 100); break;
        }
      } else {
        // Default improvement for any practice
        newReadiness = (newReadiness + 5).clamp(0, 100);
      }

      // Calculate next due date based on readiness
      final now = DateTime.now();
      DateTime? nextDue;
      
      if (newReadiness < 30) {
        // Struggling - practice again tomorrow
        nextDue = now.add(const Duration(days: 1));
      } else if (newReadiness < 60) {
        // Learning - practice in 3 days
        nextDue = now.add(const Duration(days: 3));
      } else if (newReadiness < 90) {
        // Good - practice in a week
        nextDue = now.add(const Duration(days: 7));
      } else {
        // Mastered - practice in 2 weeks
        nextDue = now.add(const Duration(days: 14));
      }

      final updatedSpot = spot.copyWith(
        readiness: newReadiness,
        nextDue: nextDue.toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      await DBHelper.updateSpot(updatedSpot);
      print('SpotManager: Updated spot readiness to $newReadiness, next due: ${nextDue.toString().split(' ')[0]}');
    }
  }

  /// Get spots that are due for practice
  static Future<List<PracticeSpot>> getDueSpots() async {
    return await DBHelper.getDueSpots();
  }

  /// Get all active spots
  static Future<List<PracticeSpot>> getAllActiveSpots() async {
    return await DBHelper.getAllActiveSpots();
  }

  /// Get practice history for a spot
  static Future<List<Map<String, dynamic>>> getPracticeHistory(int spotId) async {
    return await DBHelper.getPracticeHistory(spotId);
  }

  // ====================================================================
  // UTILITY METHODS
  // ====================================================================

  /// Get summary statistics
  static Future<Map<String, dynamic>> getStatistics() async {
    final dbStats = await DBHelper.getStats();
    final dueSpots = await getDueSpots();
    
    return {
      ...dbStats,
      'dueForPractice': dueSpots.length,
      'readinessAverage': await _calculateAverageReadiness(),
    };
  }

  /// Calculate average readiness across all spots
  static Future<double> _calculateAverageReadiness() async {
    final spots = await getAllActiveSpots();
    if (spots.isEmpty) return 0.0;
    
    final totalReadiness = spots.fold<int>(0, (sum, spot) => sum + spot.readiness);
    return totalReadiness / spots.length;
  }

  /// Search spots by text
  static Future<List<PracticeSpot>> searchSpots(String query) async {
    final allSpots = await getAllActiveSpots();
    final lowercaseQuery = query.toLowerCase();
    
    return allSpots.where((spot) {
      return spot.piece.toLowerCase().contains(lowercaseQuery) ||
             (spot.title?.toLowerCase().contains(lowercaseQuery) ?? false) ||
             (spot.description?.toLowerCase().contains(lowercaseQuery) ?? false) ||
             (spot.notes?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  /// Get spots by priority
  static Future<List<PracticeSpot>> getSpotsByPriority(String priority) async {
    final allSpots = await getAllActiveSpots();
    return allSpots.where((spot) => spot.priority == priority).toList();
  }

  /// Get spots by color
  static Future<List<PracticeSpot>> getSpotsByColor(String color) async {
    final allSpots = await getAllActiveSpots();
    return allSpots.where((spot) => spot.color == color).toList();
  }

  /// Update spot color (when user changes it in UI)
  static Future<bool> updateSpotColor(int spotId, String newColor) async {
    final spot = await DBHelper.getSpot(spotId);
    if (spot == null) return false;
    
    final updatedSpot = spot.copyWith(
      color: newColor,
      updatedAt: DateTime.now().toIso8601String(),
    );
    
    return await updateSpot(updatedSpot);
  }

  /// Update spot readiness manually
  static Future<bool> updateSpotReadiness(int spotId, int newReadiness) async {
    final spot = await DBHelper.getSpot(spotId);
    if (spot == null) return false;
    
    final updatedSpot = spot.copyWith(
      readiness: newReadiness.clamp(0, 100),
      updatedAt: DateTime.now().toIso8601String(),
    );
    
    return await updateSpot(updatedSpot);
  }

  // ====================================================================
  // FUTURE SYNC SUPPORT
  // ====================================================================

  /// Prepare for future cloud sync
  static Future<List<PracticeSpot>> getSpotsNeedingSync() async {
    return await DBHelper.getSpotsNeedingSync();
  }

  /// Mark spots as synced (for future cloud integration)
  static Future<void> markAsSynced(List<int> spotIds, List<String> cloudIds) async {
    for (int i = 0; i < spotIds.length; i++) {
      final spot = await DBHelper.getSpot(spotIds[i]);
      if (spot != null) {
        final syncedSpot = spot.copyWith(
          syncStatus: 'synced',
          lastSynced: DateTime.now().toIso8601String(),
          cloudId: cloudIds.isNotEmpty ? cloudIds[i] : null,
        );
        await DBHelper.updateSpot(syncedSpot);
      }
    }
  }
}

/// Riverpod providers for state management
final spotManagerProvider = Provider<SpotManager>((ref) => SpotManager());

/// Provider for spots of a specific piece
final spotsForPieceProvider = FutureProvider.family<List<PracticeSpot>, String>((ref, pieceName) {
  return SpotManager.getSpotsForPiece(pieceName);
});

/// Provider for due spots
final dueSpotsProvider = FutureProvider<List<PracticeSpot>>((ref) {
  return SpotManager.getDueSpots();
});

/// Provider for all active spots
final allActiveSpotsProvider = FutureProvider<List<PracticeSpot>>((ref) {
  return SpotManager.getAllActiveSpots();
});

/// Provider for statistics
final spotStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return SpotManager.getStatistics();
});

/// Provider for spots on a specific page
final spotsForPageProvider = FutureProvider.family<List<PracticeSpot>, ({String piece, int page})>((ref, params) {
  return SpotManager.getSpotsForPage(params.piece, params.page);
});
