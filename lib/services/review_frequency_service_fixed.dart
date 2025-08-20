import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/spot.dart';
import '../providers/app_settings_provider.dart';

// Provider for the review frequency service
final reviewFrequencyServiceProvider = Provider<ReviewFrequencyService>((ref) {
  return ReviewFrequencyService(ref);
});

class ReviewFrequencyService {
  final Ref ref;

  ReviewFrequencyService(this.ref);

  // Calculate optimal practice sessions based on SRS (Spaced Repetition System)
  List<PracticeSession> generateOptimalPracticeSessions(List<Spot> allSpots, Duration totalTime) {
    final settings = ref.read(appSettingsProvider);
    final dueSpots = getSpotsDueForReview(allSpots);
    final prioritizedSpots = _prioritizeSpotsBySRS(dueSpots);
    
    return _createPracticeSessions(prioritizedSpots, totalTime, settings);
  }

  // Get next review date for a spot based on SRS algorithm
  DateTime getNextReviewDate(Spot spot, bool wasSuccessful) {
    final now = DateTime.now();
    final difficulty = _getSpotDifficulty(spot);
    
    int intervalDays;
    switch (spot.readinessLevel) {
      case ReadinessLevel.newSpot:
        intervalDays = wasSuccessful ? 1 : 0; // Practice again today or tomorrow
        break;
      case ReadinessLevel.learning:
        intervalDays = wasSuccessful ? 3 : 1; // 3 days if successful, 1 if not
        break;
      case ReadinessLevel.review:
        intervalDays = wasSuccessful ? 7 : 3; // 1 week if successful, 3 days if not
        break;
      case ReadinessLevel.mastered:
      default:
        intervalDays = wasSuccessful ? 14 : 7; // 2 weeks if successful, 1 week if not
    }
    
    // Adjust based on difficulty and settings
    final adjustedInterval = (intervalDays * difficulty * _getFrequencyMultiplier(spot.readinessLevel)).round();
    return now.add(Duration(days: adjustedInterval));
  }

  double _getFrequencyMultiplier(ReadinessLevel level) {
    final settings = ref.read(appSettingsProvider);
    switch (level) {
      case ReadinessLevel.newSpot:
        return 2.0 - (settings.criticalSpotsFrequency / 100.0); // Higher frequency = shorter intervals
      case ReadinessLevel.learning:
        return 1.5 - (settings.reviewSpotsFrequency / 200.0);
      case ReadinessLevel.review:
        return 1.2 - (settings.maintenanceSpotsFrequency / 300.0);
      case ReadinessLevel.mastered:
      default:
        return 1.0;
    }
  }

  // Get spots that are due for review
  List<Spot> getSpotsDueForReview(List<Spot> allSpots) {
    final now = DateTime.now();
    final settings = ref.read(appSettingsProvider);
    
    return allSpots.where((spot) {
      if (spot.nextDue == null) return true;
      
      // Check if due based on frequency settings
      final daysSinceReview = now.difference(spot.nextDue!).inDays.abs();
      final requiredInterval = _getRequiredReviewInterval(spot.readinessLevel, settings);
      
      return daysSinceReview >= requiredInterval;
    }).toList();
  }

  int _getRequiredReviewInterval(ReadinessLevel level, AppSettings settings) {
    switch (level) {
      case ReadinessLevel.newSpot:
        // Higher frequency percentage = shorter interval
        return (10 - (settings.criticalSpotsFrequency / 10)).round().clamp(1, 10);
      case ReadinessLevel.learning:
        return (14 - (settings.reviewSpotsFrequency / 10)).round().clamp(2, 14);
      case ReadinessLevel.review:
        return (30 - (settings.maintenanceSpotsFrequency / 5)).round().clamp(7, 30);
      case ReadinessLevel.mastered:
      default:
        return 14;
    }
  }

  // Get practice priority weights based on frequency settings
  Map<ReadinessLevel, double> getPriorityWeights() {
    final settings = ref.read(appSettingsProvider);
    return {
      ReadinessLevel.newSpot: settings.criticalSpotsFrequency / 100.0,
      ReadinessLevel.learning: settings.reviewSpotsFrequency / 100.0,
      ReadinessLevel.review: settings.maintenanceSpotsFrequency / 100.0,
      ReadinessLevel.mastered: 0.1, // Low priority for mastered spots
    };
  }

  // Generate balanced practice session based on frequency settings
  List<Spot> generateBalancedPracticeSession(List<Spot> allSpots, int maxSpots) {
    final weights = getPriorityWeights();
    
    // Separate spots by readiness level
    final newSpots = allSpots.where((s) => s.readinessLevel == ReadinessLevel.newSpot).toList();
    final learningSpots = allSpots.where((s) => s.readinessLevel == ReadinessLevel.learning).toList();
    final reviewSpots = allSpots.where((s) => s.readinessLevel == ReadinessLevel.review).toList();
    
    // Calculate how many of each type to include
    final newCount = (maxSpots * weights[ReadinessLevel.newSpot]!).round();
    final learningCount = (maxSpots * weights[ReadinessLevel.learning]!).round();
    final reviewCount = (maxSpots * weights[ReadinessLevel.review]!).round();
    
    List<Spot> session = [];
    session.addAll(_selectTopSpots(newSpots, newCount));
    session.addAll(_selectTopSpots(learningSpots, learningCount));
    session.addAll(_selectTopSpots(reviewSpots, reviewCount));
    
    return session.take(maxSpots).toList();
  }

  List<Spot> _selectTopSpots(List<Spot> spots, int count) {
    if (spots.isEmpty) return [];
    
    final now = DateTime.now();
    // Sort by priority: overdue spots first, then by last practiced
    spots.sort((a, b) {
      final aPriority = _calculateSpotPriority(a, now);
      final bPriority = _calculateSpotPriority(b, now);
      return bPriority.compareTo(aPriority);
    });
    
    return spots.take(count).toList();
  }

  double _calculateSpotPriority(Spot spot, DateTime now) {
    final levelMultipliers = {
      ReadinessLevel.newSpot: 10.0,
      ReadinessLevel.learning: 5.0,
      ReadinessLevel.review: 2.0,
      ReadinessLevel.mastered: 1.0,
    };
    
    final basePriority = levelMultipliers[spot.readinessLevel] ?? 1.0;
    final daysSinceLastPractice = spot.lastPracticed != null 
        ? now.difference(spot.lastPracticed!).inDays 
        : 30; // Assume 30 days if never practiced
    
    return basePriority * (1 + daysSinceLastPractice * 0.1);
  }

  // Get practice statistics for the current frequency settings
  Map<String, dynamic> getPracticeStatistics(List<Spot> allSpots, Duration period) {
    final now = DateTime.now();
    final periodStart = now.subtract(period);
    
    final spotsInPeriod = allSpots.where((spot) {
      return spot.lastPracticed != null && 
             spot.lastPracticed!.isAfter(periodStart);
    }).toList();
    
    // Count by readiness level
    final newSpotsPracticed = 
      spotsInPeriod.where((s) => s.readinessLevel == ReadinessLevel.newSpot).toList()
        .length;
    final learningSpotsPracticed = 
      spotsInPeriod.where((s) => s.readinessLevel == ReadinessLevel.learning).toList()
        .length;
    final reviewSpotsPracticed = 
      spotsInPeriod.where((s) => s.readinessLevel == ReadinessLevel.review).toList()
        .length;
    
    final totalPracticed = spotsInPeriod.length;
    final averageSessionLength = totalPracticed > 0 
        ? period.inMinutes / totalPracticed 
        : 0;
    
    return {
      'totalSpotsPracticed': totalPracticed,
      'newSpotsPracticed': newSpotsPracticed,
      'learningSpotsPracticed': learningSpotsPracticed,
      'reviewSpotsPracticed': reviewSpotsPracticed,
      'averageSessionLength': averageSessionLength,
      'practiceFrequency': totalPracticed / period.inDays,
    };
  }

  // Helper methods for SRS algorithm
  List<Spot> _prioritizeSpotsBySRS(List<Spot> spots) {
    final now = DateTime.now();
    spots.sort((a, b) {
      final aPriority = _calculateSRSPriority(a, now);
      final bPriority = _calculateSRSPriority(b, now);
      return bPriority.compareTo(aPriority);
    });
    return spots;
  }

  double _calculateSRSPriority(Spot spot, DateTime now) {
    final overdueDays = spot.nextDue != null 
        ? now.difference(spot.nextDue!).inDays.clamp(0, 365)
        : 0;
    final difficulty = _getSpotDifficulty(spot);
    final levelMultiplier = _getLevelMultiplier(spot.readinessLevel);
    
    return (overdueDays * difficulty * levelMultiplier);
  }

  double _getSpotDifficulty(Spot spot) {
    // Could be enhanced with actual practice history
    return 1.0; // Default difficulty
  }

  double _getLevelMultiplier(ReadinessLevel level) {
    switch (level) {
      case ReadinessLevel.newSpot: return 3.0;
      case ReadinessLevel.learning: return 2.0;
      case ReadinessLevel.review: return 1.5;
      case ReadinessLevel.mastered: return 1.0;
    }
  }

  List<PracticeSession> _createPracticeSessions(List<Spot> spots, Duration totalTime, AppSettings settings) {
    // Implementation would create actual practice sessions
    // For now, return a simple session structure
    return [
      PracticeSession(
        spots: spots,
        duration: totalTime,
        breakInterval: Duration(minutes: settings.microBreakInterval),
      ),
    ];
  }
}

// Data classes for practice sessions
class PracticeSession {
  final List<Spot> spots;
  final Duration duration;
  final Duration breakInterval;

  PracticeSession({
    required this.spots,
    required this.duration,
    required this.breakInterval,
  });
}
