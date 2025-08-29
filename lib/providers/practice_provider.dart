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
      
      // Get ALL active spots from database (not just unified library pieces)
      final allActiveSpots = await spotService.getAllActiveSpots();
      print('PracticeProvider: Found ${allActiveSpots.length} total active spots in database');
      
      // Also get pieces from unified library for additional context
      final asyncPieces = ref.read(unifiedLibraryProvider);
      List<Spot> librarySpots = [];
      
      await asyncPieces.when(
        data: (pieces) async {
          print('PracticeProvider: Found ${pieces.length} pieces in unified library');
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
      
      print('PracticeProvider: Library spots: ${librarySpots.length}, Database spots: ${allActiveSpots.length}');
      print('PracticeProvider: Using database spots for accurate counts: ${allActiveSpots.length}');
      
      // Use ALL database spots for accurate counts
      final dailyPlan = _generateDailyPlanFromSpots(allActiveSpots);
      final urgentSpots = _getUrgentSpotsFromSpots(allActiveSpots);
      final stats = await _getRealPracticeStats(databaseService, allActiveSpots);
      
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
    // Filter spots that are due for practice
    final dueSpots = allSpots.where((spot) => spot.isDue).toList();
    
    // Sort by urgency (highest priority first)
    dueSpots.sort((a, b) => b.urgencyScore.compareTo(a.urgencyScore));
    
    // Return up to 20 spots for manageable daily practice
    final dailyPlan = dueSpots.take(20).toList();
    print('PracticeProvider: Generated daily plan with ${dailyPlan.length} spots');
    
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
