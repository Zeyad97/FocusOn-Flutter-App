import '../models/spot.dart';
import '../models/project.dart';
import '../models/practice_session.dart';
import 'musical_ai.dart';

/// AI-Powered Practice Selection Service
/// Uses real machine learning to optimize practice sessions for musicians
class AiPracticeSelector {
  
  /// Smart Practice: Uses AI to practice ALL spots with intelligent prioritization
  static List<Spot> selectAiPoweredSpots(
    List<Spot> allSpots, {
    int maxSpots = 15, // Increased to allow more spots in smart practice
    Duration? sessionDuration,
    Project? project,
    List<PracticeSession>? practiceHistory,
  }) {
    print('AiPracticeSelector: Smart Practice called with ${allSpots.length} spots');
    
    if (allSpots.isEmpty) return [];
    
    final activeSpots = allSpots.where((s) => s.isActive).toList();
    print('AiPracticeSelector: ${activeSpots.length} active spots available for smart practice');
    
    // Smart practice should include ALL active spots but prioritize them intelligently
    // Use REAL AI that learns from your practice patterns and prioritizes all spots
    final smartSpots = MusicalAI.selectIntelligentPracticeSpots(
      activeSpots, // Pass all active spots
      project: project ?? _createDefaultProject(),
      practiceHistory: practiceHistory ?? [],
      sessionDuration: sessionDuration ?? const Duration(minutes: 30),
      maxSpots: maxSpots >= activeSpots.length ? activeSpots.length : maxSpots, // Ensure we can get all spots
    );
    
    print('AiPracticeSelector: Smart Practice selected ${smartSpots.length} prioritized spots from all available spots');
    return smartSpots;
  }
  
  /// Critical Focus: Only red spots that need urgent attention  
  static List<Spot> selectCriticalSpots(List<Spot> allSpots, {int maxSpots = 10}) {
    print('AiPracticeSelector: selectCriticalSpots called with ${allSpots.length} spots');
    
    final activeSpots = allSpots.where((s) => s.isActive).toList();
    print('AiPracticeSelector: ${activeSpots.length} active spots found');
    
    // Only select RED spots for critical practice
    final criticalSpots = activeSpots
        .where((s) => s.color == SpotColor.red)
        .toList();
    
    print('AiPracticeSelector: ${criticalSpots.length} critical (red) spots found:');
    for (final spot in criticalSpots) {
      print('  - ${spot.title}: color=${spot.color.name}, priority=${spot.priority.name}, isActive=${spot.isActive}');
    }
    
    // If no red spots found, inform user
    if (criticalSpots.isEmpty) {
      print('AiPracticeSelector: No red (critical) spots found for critical practice');
      return [];
    }

    final now = DateTime.now();
    final result = criticalSpots
        ..sort((a, b) => _urgencyScore(b, now).compareTo(_urgencyScore(a, now)))
        ..take(maxSpots)
        .toList();
    
    print('AiPracticeSelector: Returning ${result.length} red spots for critical practice');
    return result;
  }
  
  /// Balanced Practice: Focus ONLY on medium spots (yellow/blue) for learning
  static List<Spot> selectBalancedSpots(List<Spot> allSpots, {
    int maxSpots = 10,
    double? criticalFrequency,
    double? reviewFrequency, 
    double? maintenanceFrequency,
  }) {
    print('AiPracticeSelector: selectBalancedSpots called with ${allSpots.length} spots');
    
    final activeSpots = allSpots.where((s) => s.isActive).toList();
    print('AiPracticeSelector: ${activeSpots.length} active spots found for balanced practice');
    
    if (activeSpots.isEmpty) {
      print('AiPracticeSelector: No active spots available');
      return [];
    }
    
    // Only select YELLOW and BLUE spots for balanced practice (medium difficulty)
    final mediumSpots = activeSpots.where((s) => 
      s.color == SpotColor.yellow || s.color == SpotColor.blue
    ).toList();
    
    print('AiPracticeSelector: Found ${mediumSpots.length} medium (yellow/blue) spots for balanced practice');
    
    if (mediumSpots.isEmpty) {
      print('AiPracticeSelector: No medium (yellow/blue) spots found for balanced practice');
      return [];
    }
    
    // Sort by learning priority - yellow first (in progress), then blue (learning)
    mediumSpots.sort((a, b) {
      // Prioritize yellow spots (more progress) over blue spots (newer)
      if (a.color == SpotColor.yellow && b.color == SpotColor.blue) return -1;
      if (a.color == SpotColor.blue && b.color == SpotColor.yellow) return 1;
      
      // Within same color, sort by priority
      return b.priority.index.compareTo(a.priority.index);
    });
    
    final selected = mediumSpots.take(maxSpots).toList();
    print('AiPracticeSelector: Returning ${selected.length} medium spots for balanced practice');
    return selected;
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
  
  /// Maintenance Practice: Focus ONLY on green spots (mastered) to maintain skills
  static List<Spot> selectRepertoireSpots(List<Spot> allSpots, {int maxSpots = 10}) {
    print('AiPracticeSelector: selectRepertoireSpots called with ${allSpots.length} spots');
    
    final activeSpots = allSpots.where((s) => s.isActive).toList();
    print('AiPracticeSelector: ${activeSpots.length} active spots found');
    
    // Only select GREEN spots for maintenance practice
    final greenSpots = activeSpots
        .where((s) => s.color == SpotColor.green)
        .toList();
    
    print('AiPracticeSelector: Found ${greenSpots.length} green (maintenance) spots');
    
    if (greenSpots.isEmpty) {
      print('AiPracticeSelector: No green (mastered) spots found for maintenance practice');
      return [];
    }
    
    final result = greenSpots
        ..sort((a, b) => _maintenanceScore(b).compareTo(_maintenanceScore(a)))
        ..take(maxSpots)
        .toList();
    
    print('AiPracticeSelector: Returning ${result.length} green spots for maintenance practice');
    return result;
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
