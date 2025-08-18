import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/spot.dart';
import '../services/srs_ai_engine.dart';
import '../services/spot_service.dart';

class PracticeNotifier extends StateNotifier<PracticeState> {
  final Ref ref;
  
  PracticeNotifier(this.ref) : super(PracticeState.loading()) {
    loadPracticeData();
  }
  
  Future<void> loadPracticeData() async {
    state = PracticeState.loading();
    
    try {
      final srsEngine = ref.read(srsAiEngineProvider);
      
      final results = await Future.wait([
        srsEngine.generateDailyPracticePlan(),
        srsEngine.getUrgentSpots(),
        srsEngine.getPracticeStats(),
      ]);
      
      state = PracticeState.loaded(
        dailyPlan: results[0] as List<Spot>,
        urgentSpots: results[1] as List<Spot>,
        stats: results[2] as PracticeStats,
      );
    } catch (e) {
      state = PracticeState.error(e.toString());
    }
  }
  
  Future<void> refresh() async {
    await loadPracticeData();
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
