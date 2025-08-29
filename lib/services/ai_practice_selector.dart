import '../models/spot.dart';
import '../models/project.dart';
import '../models/practice_session.dart';
import 'musical_ai.dart';

/// AI-Powered Practice Selection Service
/// Uses real machine learning to optimize practice sessions for musicians
class AiPracticeSelector {
  
  /// REAL AI-Powered Session: Uses machine learning to analyze your practice patterns
  static List<Spot> selectAiPoweredSpots(
    List<Spot> allSpots, {
    int maxSpots = 5,
    Duration? sessionDuration,
    Project? project,
    List<PracticeSession>? practiceHistory,
  }) {
    
    if (allSpots.isEmpty) return [];
    
    // Use REAL AI that learns from your practice patterns
    return MusicalAI.selectIntelligentPracticeSpots(
      allSpots,
      project: project ?? _createDefaultProject(),
      practiceHistory: practiceHistory ?? [],
      sessionDuration: sessionDuration ?? const Duration(minutes: 30),
      maxSpots: maxSpots,
    );
  }
  
  /// Critical Focus: Only red spots and urgent deadlines  
  static List<Spot> selectCriticalSpots(List<Spot> allSpots, {int maxSpots = 5}) {
    print('AiPracticeSelector: selectCriticalSpots called with ${allSpots.length} spots');
    
    final now = DateTime.now();
    final activeSpots = allSpots.where((s) => s.isActive).toList();
    print('AiPracticeSelector: ${activeSpots.length} active spots found');
    
    // Expand criteria to include more spots since readiness is low
    final criticalSpots = activeSpots
        .where((s) => 
          s.color == SpotColor.red ||
          s.color == SpotColor.blue ||  // Include blue spots (new/unpracticed)
          s.priority == SpotPriority.high ||
          s.priority == SpotPriority.medium ||  // Include medium priority
          (s.nextDue != null && s.nextDue!.isBefore(now))
        )
        .toList();
    
    print('AiPracticeSelector: ${criticalSpots.length} critical spots found:');
    for (final spot in criticalSpots) {
      print('  - ${spot.title}: color=${spot.color.name}, priority=${spot.priority.name}, isActive=${spot.isActive}');
    }
    
    // If still no spots found, just take any active spots
    if (criticalSpots.isEmpty && activeSpots.isNotEmpty) {
      print('AiPracticeSelector: No critical spots found, taking any active spots');
      final result = activeSpots.take(maxSpots).toList();
      print('AiPracticeSelector: Returning ${result.length} any active spots');
      return result;
    }
    
    final result = criticalSpots
        ..sort((a, b) => _urgencyScore(b, now).compareTo(_urgencyScore(a, now)))
        ..take(maxSpots)
        .toList();
    
    print('AiPracticeSelector: Returning ${result.length} spots for critical practice');
    return result;
  }
  
  /// Balanced Practice: Mix of all readiness levels
  static List<Spot> selectBalancedSpots(List<Spot> allSpots, {int maxSpots = 5}) {
    print('AiPracticeSelector: selectBalancedSpots called with ${allSpots.length} spots');
    
    final activeSpots = allSpots.where((s) => s.isActive).toList();
    print('AiPracticeSelector: ${activeSpots.length} active spots found for balanced practice');
    
    // Aim for balanced distribution - include blue spots too
    final redSpots = activeSpots.where((s) => s.color == SpotColor.red).take(2);
    final blueSpots = activeSpots.where((s) => s.color == SpotColor.blue).take(2);  // Include blue spots
    final yellowSpots = activeSpots.where((s) => s.color == SpotColor.yellow).take(2);
    final greenSpots = activeSpots.where((s) => s.color == SpotColor.green).take(1);
    
    final balanced = [...redSpots, ...blueSpots, ...yellowSpots, ...greenSpots];
    
    // Fill remaining slots with any remaining active spots
    final remaining = maxSpots - balanced.length;
    if (remaining > 0) {
      final used = balanced.map((s) => s.id).toSet();
      final additional = activeSpots.where((s) => !used.contains(s.id)).take(remaining);
      balanced.addAll(additional);
    }
    
    print('AiPracticeSelector: Returning ${balanced.length} balanced spots (red: ${redSpots.length}, blue: ${blueSpots.length}, yellow: ${yellowSpots.length}, green: ${greenSpots.length})');
    return balanced.take(maxSpots).toList();
  }
  
  /// Technique Focus: Spots with high failure rate and technical difficulty
  static List<Spot> selectTechniqueSpots(List<Spot> allSpots, {int maxSpots = 5}) {
    return allSpots
        .where((s) => s.isActive && (
          s.color == SpotColor.red || 
          s.failureCount > s.successCount ||
          s.readinessLevel == ReadinessLevel.learning
        ))
        .toList()
        ..sort((a, b) => _technicalDifficultyScore(b).compareTo(_technicalDifficultyScore(a)))
        ..take(maxSpots);
  }
  
  /// Repertoire Review: Focus on mastered/review spots to maintain skills
  static List<Spot> selectRepertoireSpots(List<Spot> allSpots, {int maxSpots = 5}) {
    return allSpots
        .where((s) => s.isActive && (
          s.readinessLevel == ReadinessLevel.mastered ||
          s.readinessLevel == ReadinessLevel.review ||
          s.color == SpotColor.green
        ))
        .toList()
        ..sort((a, b) => _maintenanceScore(b).compareTo(_maintenanceScore(a)))
        ..take(maxSpots);
  }
  
  /// Quick Warmup: Easy, familiar spots for confidence building
  static List<Spot> selectWarmupSpots(List<Spot> allSpots, {int maxSpots = 3}) {
    return allSpots
        .where((s) => s.isActive && (
          s.readinessLevel == ReadinessLevel.mastered ||
          s.successCount > s.failureCount * 2 ||
          s.color == SpotColor.green
        ))
        .toList()
        ..sort((a, b) => _confidenceScore(b).compareTo(_confidenceScore(a)))
        ..take(maxSpots);
  }
  
  // Helper methods for scoring
  static double _urgencyScore(Spot spot, DateTime now) {
    double score = 0.0;
    
    // Color priority
    switch (spot.color) {
      case SpotColor.red: score += 10.0; break;
      case SpotColor.yellow: score += 6.0; break;
      case SpotColor.green: score += 2.0; break;
      case SpotColor.blue: score += 4.0; break; // Medium priority for blue
    }
    
    // Priority level
    switch (spot.priority) {
      case SpotPriority.high: score += 8.0; break;
      case SpotPriority.medium: score += 5.0; break;
      case SpotPriority.low: score += 2.0; break;
    }
    
    // Overdue spots
    if (spot.nextDue != null && spot.nextDue!.isBefore(now)) {
      final daysOverdue = now.difference(spot.nextDue!).inDays;
      score += daysOverdue * 2.0;
    }
    
    return score;
  }
  
  static double _technicalDifficultyScore(Spot spot) {
    double score = 0.0;
    score += spot.failureCount * 2.0;
    score += spot.recommendedPracticeTime * 0.5;
    score += (2.5 - spot.easeFactor) * 3.0;
    if (spot.readinessLevel == ReadinessLevel.learning) score += 5.0;
    return score;
  }
  
  static double _maintenanceScore(Spot spot) {
    double score = 0.0;
    score += spot.successCount * 1.0;
    score += spot.repetitions * 1.5;
    if (spot.readinessLevel == ReadinessLevel.mastered) score += 8.0;
    if (spot.color == SpotColor.green) score += 5.0;
    
    // Bonus for spots not practiced recently (maintenance needed)
    if (spot.lastPracticed != null) {
      final daysSince = DateTime.now().difference(spot.lastPracticed!).inDays;
      if (daysSince > 7) score += daysSince * 0.3;
    }
    
    return score;
  }
  
  static double _confidenceScore(Spot spot) {
    double score = 0.0;
    if (spot.practiceCount > 0) {
      final successRate = spot.successCount / spot.practiceCount;
      score += successRate * 10.0;
    }
    score += spot.easeFactor * 2.0;
    if (spot.readinessLevel == ReadinessLevel.mastered) score += 8.0;
    return score;
  }
  
  static double _overallPriorityScore(Spot spot) {
    return _urgencyScore(spot, DateTime.now()) + 
           _technicalDifficultyScore(spot);
  }
  
  // Create default project if none provided
  static Project _createDefaultProject() {
    return Project(
      id: 'default',
      name: 'Practice Session',
      pieceIds: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
