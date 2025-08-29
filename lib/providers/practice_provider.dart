import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/spot.dart';
import '../models/practice_session.dart';
import '../services/srs_ai_engine.dart';
import '../services/spot_service.dart';
import '../services/database_service.dart';
import 'unified_library_provider.dart';

class PracticeNotifier extends StateNotifier<PracticeState> {
  final Ref ref;
  
  PracticeNotifier(this.ref) : super(PracticeState.loading()) {
    loadPracticeData();
  }
  
  Future<void> loadPracticeData() async {
    state = PracticeState.loading();
    
    try {
      final databaseService = ref.read(databaseServiceProvider);
      final spotService = ref.read(spotServiceProvider);
      
      // Get pieces from unified library (only imported pieces in music library)
      final asyncPieces = ref.read(unifiedLibraryProvider);
      List<Spot> librarySpots = [];
      
      await asyncPieces.when(
        data: (pieces) async {
          print('PracticeProvider: Found ${pieces.length} pieces in music library');
          for (final piece in pieces) {
            print('  - ${piece.title} (${piece.spots.length} spots)');
            librarySpots.addAll(piece.spots);
          }
        },
        loading: () async {},
        error: (error, stack) async {
          print('PracticeProvider: Error loading pieces: $error');
        },
      );
      
      print('PracticeProvider: Using only library spots for AI-optimized practice plan: ${librarySpots.length}');
      
      // Use ONLY library spots (from imported pieces) for AI-optimized practice plan
      final dailyPlan = _generateDailyPlanFromSpots(librarySpots);
      final urgentSpots = _getUrgentSpotsFromSpots(librarySpots);
      final stats = await _getRealPracticeStats(databaseService, librarySpots);
      
      state = PracticeState.loaded(
        dailyPlan: dailyPlan,
        urgentSpots: urgentSpots,
        stats: stats,
      );
    } catch (e) {
      print('PracticeProvider: Error loading practice data: $e');
      state = PracticeState.error(e.toString());
    }
  }
  
  List<Spot> _generateDailyPlanFromSpots(List<Spot> allSpots) {
    print('PracticeProvider: Generating daily plan from ${allSpots.length} spots');
    for (final spot in allSpots) {
      print('  Spot: ${spot.title} - isDue: ${spot.isDue}, nextDue: ${spot.nextDue}, readinessLevel: ${spot.readinessLevel}, color: ${spot.color}, urgencyScore: ${spot.urgencyScore}');
    }
    
    // For newly imported pieces: include ALL spots in daily plan
    // This ensures new pieces show up in "Today's Practice Plan"
    
    if (allSpots.isEmpty) {
      print('PracticeProvider: No spots to generate daily plan from');
      return [];
    }
    
    // Sort by urgency (highest priority first) 
    allSpots.sort((a, b) => b.urgencyScore.compareTo(a.urgencyScore));
    
    print('PracticeProvider: After sorting by urgency:');
    for (final spot in allSpots) {
      print('  Sorted spot: ${spot.title} - urgencyScore: ${spot.urgencyScore}');
    }
    
    // Return up to 20 spots for manageable daily practice
    final dailyPlan = allSpots.take(20).toList();
    print('PracticeProvider: Generated daily plan with ${dailyPlan.length} spots from ${allSpots.length} total');
    for (final spot in dailyPlan) {
      print('  Daily plan spot: ${spot.title}');
    }
    
    return dailyPlan;
  }
  
  List<Spot> _getUrgentSpotsFromSpots(List<Spot> allSpots) {
    final now = DateTime.now();
    
    final urgentSpots = allSpots.where((spot) {
      // Spot is urgent if it's overdue by more than 1 day or critical priority
      final isOverdue = spot.nextDue != null && 
          now.difference(spot.nextDue!).inDays > 1;
      final isCritical = spot.priority == SpotPriority.high || 
          spot.color == SpotColor.red;
      
      return isOverdue || isCritical;
    }).toList();
    
    // Sort by urgency
    urgentSpots.sort((a, b) => b.urgencyScore.compareTo(a.urgencyScore));
    
    print('PracticeProvider: Found ${urgentSpots.length} urgent spots');
    return urgentSpots.take(10).toList(); // Limit to 10 urgent spots
  }
  
  Future<PracticeStats> _getRealPracticeStats(DatabaseService databaseService, List<Spot> activeSpots) async {
    // Get real data from database
    final recentSessions = await databaseService.getRecentPracticeSessions(days: 7);
    final todaySessions = await databaseService.getTodayPracticeSessions();
    
    print('[PracticeProvider] DEBUG: Found ${todaySessions.length} today sessions');
    for (final session in todaySessions) {
      print('[PracticeProvider] DEBUG: Session ${session.id} - Status: ${session.status}, Duration: ${session.actualDuration?.inMinutes ?? 0} min, Spots: ${session.spotSessions.length}');
      for (final spotSession in session.spotSessions) {
        print('[PracticeProvider] DEBUG:   Spot ${spotSession.spotId} - Status: ${spotSession.status}, Duration: ${spotSession.actualDuration?.inMinutes ?? 0} min');
      }
    }
    
    // Calculate real statistics using the ACTIVE spots
    final totalSpots = activeSpots.length;
    final dueSpots = activeSpots.where((s) => s.isDue).length;
    final masteredSpots = activeSpots.where((s) => s.readinessLevel == ReadinessLevel.mastered).length;
    final learningSpots = activeSpots.where((s) => s.readinessLevel == ReadinessLevel.learning).length;
    
    print('PracticeProvider: Stats calculated - Total: $totalSpots, Due: $dueSpots, Mastered: $masteredSpots, Learning: $learningSpots');
    
    // Today's real practice data
    final todayPracticeTime = todaySessions.fold<int>(
      0, 
      (sum, session) => sum + (session.actualDuration?.inMinutes ?? 0),
    );
    
    final todaySpotsPracticed = todaySessions.fold<Set<String>>(
      <String>{},
      (spots, session) => spots..addAll(session.spotSessions.map((s) => s.spotId)),
    ).length;
    
    print('[PracticeProvider] DEBUG: Calculated today practice time: $todayPracticeTime min, spots practiced: $todaySpotsPracticed');
    
    // Weekly real practice data
    final weeklyPracticeTime = recentSessions.fold<int>(
      0, 
      (sum, session) => sum + (session.actualDuration?.inMinutes ?? 0),
    );
    
    final weeklySessions = recentSessions.length;
    
    // Calculate improved spots (spots with recent progress)
    final improvedSpots = await _getImprovedSpotsThisWeek(databaseService);
    
    return PracticeStats(
      totalSpots: totalSpots,
      dueSpots: dueSpots,
      masteredSpots: masteredSpots,
      learningSpots: learningSpots,
      weeklyPracticeMinutes: weeklyPracticeTime,
      weeklySessionCount: weeklySessions,
      todayPracticeTime: todayPracticeTime,
      todaySpotsPracticed: todaySpotsPracticed,
      weeklyPracticeTime: weeklyPracticeTime,
      weeklySessions: weeklySessions,
      weeklyImprovedSpots: improvedSpots,
    );
  }
  
  Future<int> _getImprovedSpotsThisWeek(DatabaseService databaseService) async {
    final weekAgo = DateTime.now().subtract(Duration(days: 7));
    final spotHistory = await databaseService.getSpotHistorySince(weekAgo);
    
    // Count spots that had successful practice sessions this week
    final improvedSpotIds = spotHistory
        .where((h) => h.result == SpotResult.excellent || h.result == SpotResult.good)
        .map((h) => h.spotId)
        .toSet();
    
    return improvedSpotIds.length;
  }
  
  Future<void> refresh() async {
    print('PracticeProvider: Refreshing practice data...');
    await loadPracticeData();
  }
  
  // Add method to invalidate and refresh when spots change
  void invalidateAndRefresh() {
    print('PracticeProvider: Invalidating and refreshing due to spot changes...');
    // Force reload from database
    loadPracticeData();
  }
}

class PracticeState {
  final List<Spot>? dailyPlan;
  final List<Spot>? urgentSpots;
  final PracticeStats? stats;
  final bool isLoading;
  final String? error;
  
  const PracticeState._({
    this.dailyPlan,
    this.urgentSpots,
    this.stats,
    this.isLoading = false,
    this.error,
  });
  
  factory PracticeState.loading() => const PracticeState._(isLoading: true);
  
  factory PracticeState.loaded({
    required List<Spot> dailyPlan,
    required List<Spot> urgentSpots,
    required PracticeStats stats,
  }) => PracticeState._(
    dailyPlan: dailyPlan,
    urgentSpots: urgentSpots,
    stats: stats,
  );
  
  factory PracticeState.error(String error) => PracticeState._(error: error);
}

final practiceProvider = StateNotifierProvider<PracticeNotifier, PracticeState>((ref) {
  return PracticeNotifier(ref);
});

// Provider to trigger practice refresh from anywhere
final practiceRefreshProvider = Provider<void Function()>((ref) {
  return () {
    ref.read(practiceProvider.notifier).refresh();
  };
});
