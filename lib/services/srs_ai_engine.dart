import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/spot.dart';
import '../services/spot_service.dart';

/// Result of SRS calculation
class SrsUpdateResult {
  final double easeFactor;
  final int interval;
  final int repetitions;
  final bool successful;

  SrsUpdateResult({
    required this.easeFactor,
    required this.interval,
    required this.repetitions,
    required this.successful,
  });
}

class SrsAiEngine {
  final SpotService _spotService;
  
  SrsAiEngine(this._spotService);
  
  /// Update spot after practice session using advanced SRS algorithm
  Future<Spot> updateSpotAfterPractice(Spot spot, SpotResult result) async {
    final now = DateTime.now();
    
    // Calculate new SRS parameters with improved algorithm
    final srsResult = _calculateAdvancedSrsUpdate(spot, result);
    
    // AI-driven readiness level calculation
    final newReadinessLevel = _calculateAiReadinessLevel(spot, result, srsResult);
    
    // AI-driven priority calculation
    final newPriority = _calculateAiPriority(spot, result, srsResult);
    
    // AI-driven color update
    final newColor = _calculateAiColor(spot, result, newReadinessLevel, newPriority);
    
    // Calculate next due date with smart intervals
    final nextDue = _calculateSmartDueDate(now, srsResult, result);
    
    return spot.copyWith(
      updatedAt: now,
      lastPracticed: now,
      nextDue: nextDue,
      practiceCount: spot.practiceCount + 1,
      successCount: spot.successCount + (srsResult.successful ? 1 : 0),
      failureCount: spot.failureCount + (srsResult.successful ? 0 : 1),
      easeFactor: srsResult.easeFactor,
      interval: srsResult.interval,
      repetitions: srsResult.repetitions,
      readinessLevel: newReadinessLevel,
      priority: newPriority,
      color: newColor,
      lastResult: result,
      lastResultAt: now,
    );
  }

  /// Advanced SRS calculation with AI improvements
  SrsUpdateResult _calculateAdvancedSrsUpdate(Spot spot, SpotResult result) {
    final currentEase = spot.easeFactor;
    final currentInterval = spot.interval;
    final currentReps = spot.repetitions;
    
    // Enhanced quality assessment
    double quality = _getQualityScore(result);
    
    // Adjust quality based on recent performance
    if (spot.practiceCount > 0) {
      final successRate = spot.successCount / spot.practiceCount;
      if (successRate < 0.3) quality *= 0.8; // Penalty for consistent struggles
      if (successRate > 0.8) quality *= 1.1; // Bonus for consistent success
    }
    
    // Calculate new ease factor with improvements
    double newEase = currentEase + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    newEase = newEase.clamp(1.3, 2.5);
    
    int newInterval;
    int newReps;
    bool successful = quality >= 3.0;
    
    if (successful) {
      if (currentReps == 0) {
        newInterval = 1;
      } else if (currentReps == 1) {
        newInterval = 6;
      } else {
        newInterval = (currentInterval * newEase).round();
      }
      newReps = currentReps + 1;
    } else {
      newInterval = 1;
      newReps = 0;
      newEase = (newEase - 0.2).clamp(1.3, 2.5);
    }
    
    return SrsUpdateResult(
      easeFactor: newEase,
      interval: newInterval,
      repetitions: newReps,
      successful: successful,
    );
  }

  /// AI-driven readiness level calculation
  ReadinessLevel _calculateAiReadinessLevel(Spot spot, SpotResult result, SrsUpdateResult srs) {
    // Consider multiple factors
    final successRate = spot.practiceCount > 0 ? spot.successCount / spot.practiceCount : 0.0;
    final repetitions = srs.repetitions;
    final recentResult = result;
    
    // Failed practice resets to learning
    if (result == SpotResult.failed) {
      return ReadinessLevel.learning;
    }
    
    // Advanced based on success rate and repetitions
    if (successRate >= 0.9 && repetitions >= 5) {
      return ReadinessLevel.mastered;
    } else if (successRate >= 0.7 && repetitions >= 3) {
      return ReadinessLevel.review;
    } else if (spot.practiceCount > 0) {
      return ReadinessLevel.learning;
    } else {
      return ReadinessLevel.newSpot;
    }
  }

  /// AI-driven priority calculation
  SpotPriority _calculateAiPriority(Spot spot, SpotResult result, SrsUpdateResult srs) {
    final now = DateTime.now();
    final isOverdue = spot.nextDue != null && now.isAfter(spot.nextDue!);
    final successRate = spot.practiceCount > 0 ? spot.successCount / spot.practiceCount : 0.0;
    
    // High priority conditions
    if (result == SpotResult.failed || 
        isOverdue || 
        (spot.practiceCount > 3 && successRate < 0.4)) {
      return SpotPriority.high;
    }
    
    // Medium priority conditions
    if (result == SpotResult.struggled || 
        (spot.practiceCount > 0 && successRate < 0.7) ||
        srs.repetitions < 3) {
      return SpotPriority.medium;
    }
    
    // Low priority for well-learned spots
    return SpotPriority.low;
  }

  /// AI-driven color calculation
  SpotColor _calculateAiColor(Spot spot, SpotResult result, ReadinessLevel readiness, SpotPriority priority) {
    // Immediate color based on result
    if (result == SpotResult.failed || priority == SpotPriority.high) {
      return SpotColor.red; // Critical/urgent
    }
    
    if (result == SpotResult.struggled || readiness == ReadinessLevel.learning) {
      return SpotColor.yellow; // Needs practice
    }
    
    if (readiness == ReadinessLevel.mastered && priority == SpotPriority.low) {
      return SpotColor.green; // Well learned
    }
    
    // Default to yellow for active practice
    return SpotColor.yellow;
  }

  /// Smart due date calculation
  DateTime _calculateSmartDueDate(DateTime now, SrsUpdateResult srs, SpotResult result) {
    int days = srs.interval;
    
    // Adjust based on result quality
    switch (result) {
      case SpotResult.failed:
        days = 0; // Practice again immediately
        break;
      case SpotResult.struggled:
        days = (days * 0.5).round().clamp(1, 3); // Shorter interval
        break;
      case SpotResult.good:
        // Use calculated interval
        break;
      case SpotResult.excellent:
        days = (days * 1.2).round(); // Longer interval
        break;
    }
    
    return now.add(Duration(days: days));
  }

  /// Enhanced quality score mapping
  double _getQualityScore(SpotResult result) {
    switch (result) {
      case SpotResult.failed:
        return 1.0; // Complete failure
      case SpotResult.struggled:
        return 2.5; // Difficult recall
      case SpotResult.good:
        return 4.0; // Good recall
      case SpotResult.excellent:
        return 5.0; // Perfect recall
    }
  }
  
  /// Generate daily practice plan based on due spots and AI priority
  Future<List<Spot>> generateDailyPracticePlan({int maxSpots = 20}) async {
    // Debug: Check all active spots first
    final allSpots = await _spotService.getAllActiveSpots();
    print('SRS Engine: Found ${allSpots.length} total active spots');
    for (final spot in allSpots) {
      print('  - ${spot.title} (pieceId: ${spot.pieceId}, nextDue: ${spot.nextDue}, readiness: ${spot.readinessLevel})');
    }
    
    final dueSpots = await _spotService.getDueSpots();
    
    // Debug logging
    print('SRS Engine: Found ${dueSpots.length} due spots');
    for (final spot in dueSpots) {
      print('  - ${spot.title} (pieceId: ${spot.pieceId}, nextDue: ${spot.nextDue})');
    }
    
    // Sort by AI-calculated priority
    dueSpots.sort((a, b) => _calculatePriority(b).compareTo(_calculatePriority(a)));
    
    // Return limited number for manageable practice session
    return dueSpots.take(maxSpots).toList();
  }
  
  /// Get spots that need urgent attention
  Future<List<Spot>> getUrgentSpots() async {
    final allSpots = await _spotService.getAllActiveSpots();
    final now = DateTime.now();
    
    print('SRS Engine: Checking ${allSpots.length} total active spots for urgency');
    
    final urgentSpots = allSpots.where((spot) {
      // Overdue spots (more than 2 days late)
      if (spot.nextDue != null && now.isAfter(spot.nextDue!.add(Duration(days: 2)))) {
        print('  - ${spot.title} is overdue');
        return true;
      }
      
      // Struggling spots (low success rate after multiple attempts)
      if (spot.practiceCount > 5 && 
          spot.successCount / spot.practiceCount < 0.4) {
        print('  - ${spot.title} is struggling spot');
        return true;
      }
      
      // Learning spots that haven't been practiced in a week
      if (spot.readinessLevel == ReadinessLevel.learning && 
          spot.lastPracticed != null &&
          now.difference(spot.lastPracticed!).inDays > 7) {
        print('  - ${spot.title} is neglected learning spot');
        return true;
      }
      
      return false;
    }).toList();
    
    print('SRS Engine: Found ${urgentSpots.length} urgent spots');
    return urgentSpots;
  }
  
  /// Calculate SRS update based on SM-2 algorithm with modifications
  _SrsResult _calculateSrsUpdate(Spot spot, SpotResult result) {
    final isSuccess = result == SpotResult.good || result == SpotResult.excellent;
    
    if (isSuccess) {
      // Successful review
      final newRepetitions = spot.repetitions + 1;
      double newEaseFactor = spot.easeFactor;
      int newInterval;
      
      // Adjust ease factor based on result quality
      switch (result) {
        case SpotResult.excellent:
          newEaseFactor = (spot.easeFactor + 0.1).clamp(1.3, 3.0);
          break;
        case SpotResult.good:
          // Keep same ease factor
          break;
        case SpotResult.struggled:
        case SpotResult.failed:
          // Should not reach here for successful review
          break;
      }
      
      // Calculate new interval
      if (newRepetitions == 1) {
        newInterval = 1;
      } else if (newRepetitions == 2) {
        newInterval = 6;
      } else {
        newInterval = (spot.interval * newEaseFactor).round();
      }
      
      return _SrsResult(
        successful: true,
        easeFactor: newEaseFactor,
        interval: newInterval,
        repetitions: newRepetitions,
      );
    } else {
      // Failed review - reset repetitions but keep some progress
      double newEaseFactor = (spot.easeFactor - 0.2).clamp(1.3, 3.0);
      
      return _SrsResult(
        successful: false,
        easeFactor: newEaseFactor,
        interval: 1, // Reset to daily practice
        repetitions: 0, // Reset repetition count
      );
    }
  }
  
  /// Calculate AI priority score for spot ordering
  double _calculatePriority(Spot spot) {
    double score = 0.0;
    
    // Base priority weight
    switch (spot.priority) {
      case SpotPriority.low:
        score += 1.0;
        break;
      case SpotPriority.medium:
        score += 2.0;
        break;
      case SpotPriority.high:
        score += 3.0;
        break;
    }
    
    // Readiness level weight
    switch (spot.readinessLevel) {
      case ReadinessLevel.newSpot:
        score += 3.0;
        break;
      case ReadinessLevel.learning:
        score += 2.5;
        break;
      case ReadinessLevel.review:
        score += 1.5;
        break;
      case ReadinessLevel.mastered:
        score += 1.0;
        break;
    }
    
    // Overdue multiplier
    if (spot.nextDue != null) {
      final now = DateTime.now();
      if (now.isAfter(spot.nextDue!)) {
        final daysOverdue = now.difference(spot.nextDue!).inDays;
        score *= (1.0 + (daysOverdue * 0.1));
      }
    }
    
    // Struggling spot multiplier
    if (spot.practiceCount > 2) {
      final successRate = spot.successCount / spot.practiceCount;
      if (successRate < 0.6) {
        score *= 1.5; // Boost struggling spots
      }
    }
    
    return score;
  }
  
  /// Calculate new readiness level based on progress
  ReadinessLevel _calculateReadinessLevel(
    ReadinessLevel current,
    SpotResult result,
    int totalRepetitions,
  ) {
    final isSuccess = result == SpotResult.good || result == SpotResult.excellent;
    
    if (!isSuccess) {
      // Failed practice - may demote or stay same
      switch (current) {
        case ReadinessLevel.review:
          return ReadinessLevel.learning;
        case ReadinessLevel.mastered:
          return ReadinessLevel.review;
        default:
          return current;
      }
    }
    
    // Successful practice - may promote
    switch (current) {
      case ReadinessLevel.newSpot:
        return totalRepetitions >= 2 ? ReadinessLevel.learning : current;
      case ReadinessLevel.learning:
        return totalRepetitions >= 5 ? ReadinessLevel.review : current;
      case ReadinessLevel.review:
        return totalRepetitions >= 10 ? ReadinessLevel.mastered : current;
      case ReadinessLevel.mastered:
        return current;
    }
  }
  
  /// Get recommended daily practice time based on current spots
  Future<int> getRecommendedDailyPracticeTime() async {
    final dueSpots = await _spotService.getDueSpots();
    
    int totalTime = 0;
    for (final spot in dueSpots.take(15)) { // Limit to manageable amount
      totalTime += spot.recommendedPracticeTime;
    }
    
    // Add 20% buffer time for breaks and transitions
    return (totalTime * 1.2).round();
  }
  
  /// Get practice statistics
  Future<PracticeStats> getPracticeStats() async {
    final allSpots = await _spotService.getAllActiveSpots();
    final history = await _spotService.getAllHistory();
    
    final dueCount = allSpots.where((s) => s.isDue).length;
    final masteredCount = allSpots.where((s) => s.readinessLevel == ReadinessLevel.mastered).length;
    final learningCount = allSpots.where((s) => s.readinessLevel == ReadinessLevel.learning).length;
    
    final recentHistory = history.where((h) => 
      h.timestamp.isAfter(DateTime.now().subtract(Duration(days: 7)))
    ).toList();
    
    final weeklyPracticeTime = recentHistory.fold<int>(
      0, 
      (sum, h) => sum + h.practiceTimeMinutes,
    );
    
    return PracticeStats(
      totalSpots: allSpots.length,
      dueSpots: dueCount,
      masteredSpots: masteredCount,
      learningSpots: learningCount,
      weeklyPracticeMinutes: weeklyPracticeTime,
      weeklySessionCount: recentHistory.length,
    );
  }
}

class _SrsResult {
  final bool successful;
  final double easeFactor;
  final int interval;
  final int repetitions;
  
  _SrsResult({
    required this.successful,
    required this.easeFactor,
    required this.interval,
    required this.repetitions,
  });
}

class PracticeStats {
  final int totalSpots;
  final int dueSpots;
  final int masteredSpots;
  final int learningSpots;
  final int weeklyPracticeMinutes;
  final int weeklySessionCount;
  
  PracticeStats({
    required this.totalSpots,
    required this.dueSpots,
    required this.masteredSpots,
    required this.learningSpots,
    required this.weeklyPracticeMinutes,
    required this.weeklySessionCount,
  });
}

final srsAiEngineProvider = Provider<SrsAiEngine>((ref) {
  final spotService = ref.watch(spotServiceProvider);
  return SrsAiEngine(spotService);
});
