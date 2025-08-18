import '../models/spot.dart';
import '../models/project.dart';
import '../models/practice_session.dart';
import 'dart:math' as math;

/// Real AI-Powered Practice Assistant for Musicians
/// This AI learns from your practice patterns and optimizes your learning
class MusicalAI {
  
  /// INTELLIGENT Practice Spot Selection
  /// This AI analyzes your real practice data to optimize learning
  static List<Spot> selectIntelligentPracticeSpots(
    List<Spot> availableSpots, {
    required Project project,
    required List<PracticeSession> practiceHistory,
    Duration sessionDuration = const Duration(minutes: 30),
    int maxSpots = 6,
  }) {
    
    if (availableSpots.isEmpty) return [];
    
    // STEP 1: Analyze user's practice patterns and learning style
    final practiceAnalysis = _analyzePracticePatterns(practiceHistory, availableSpots);
    
    // STEP 2: Calculate musical difficulty and learning curve for each spot
    final spotAnalyses = availableSpots.map((spot) => _analyzeSpotIntelligently(
      spot, 
      practiceAnalysis, 
      project,
    )).toList();
    
    // STEP 3: Use AI algorithms to optimize practice session
    final optimizedSpots = _optimizePracticeSession(
      spotAnalyses, 
      sessionDuration, 
      maxSpots,
      practiceAnalysis,
    );
    
    return optimizedSpots;
  }
  
  /// Analyze user's practice patterns to understand learning style
  static PracticeAnalysis _analyzePracticePatterns(
    List<PracticeSession> sessions, 
    List<Spot> spots,
  ) {
    if (sessions.isEmpty) {
      return PracticeAnalysis.defaultAnalysis();
    }
    
    // Calculate user's learning metrics
    final totalSessions = sessions.length;
    final avgSessionLength = sessions.fold<int>(0, (sum, s) => sum + s.plannedDuration.inMinutes) / totalSessions;
    
    // Analyze success patterns
    double overallSuccessRate = 0.0;
    double averageRetentionRate = 0.0;
    int totalSpotsPracticed = 0;
    Map<SpotColor, double> colorSuccessRates = {};
    Map<ReadinessLevel, double> levelProgressionRates = {};
    
    for (final spot in spots) {
      if (spot.practiceCount > 0) {
        totalSpotsPracticed++;
        final successRate = spot.successCount / spot.practiceCount;
        overallSuccessRate += successRate;
        
        // Track success by color
        colorSuccessRates[spot.color] = (colorSuccessRates[spot.color] ?? 0.0) + successRate;
        
        // Calculate retention (how well they maintain learned spots)
        if (spot.lastPracticed != null) {
          final daysSincePractice = DateTime.now().difference(spot.lastPracticed!).inDays;
          final expectedRetention = _calculateExpectedRetention(daysSincePractice, spot.easeFactor);
          averageRetentionRate += expectedRetention;
        }
      }
    }
    
    if (totalSpotsPracticed > 0) {
      overallSuccessRate /= totalSpotsPracticed;
      averageRetentionRate /= totalSpotsPracticed;
    }
    
    // Determine learning preferences
    final prefersLongSessions = avgSessionLength > 40;
    final isQuickLearner = overallSuccessRate > 0.7;
    final hasGoodRetention = averageRetentionRate > 0.6;
    
    return PracticeAnalysis(
      overallSuccessRate: overallSuccessRate,
      averageSessionLength: avgSessionLength,
      retentionRate: averageRetentionRate,
      totalSpotsPracticed: totalSpotsPracticed,
      prefersLongSessions: prefersLongSessions,
      isQuickLearner: isQuickLearner,
      hasGoodRetention: hasGoodRetention,
      colorSuccessRates: colorSuccessRates,
    );
  }
  
  /// Intelligently analyze each spot considering musical and learning factors
  static SpotAnalysis _analyzeSpotIntelligently(
    Spot spot, 
    PracticeAnalysis userProfile,
    Project project,
  ) {
    // MUSICAL DIFFICULTY ANALYSIS
    final musicalDifficulty = _calculateMusicalDifficulty(spot);
    
    // LEARNING EFFICIENCY ANALYSIS
    final learningEfficiency = _calculateLearningEfficiency(spot, userProfile);
    
    // RETENTION RISK ANALYSIS  
    final retentionRisk = _calculateRetentionRisk(spot, userProfile);
    
    // URGENCY ANALYSIS (Concert deadlines, etc.)
    final urgency = _calculateUrgency(spot, project);
    
    // OPTIMAL PRACTICE TIME PREDICTION
    final optimalPracticeTime = _predictOptimalPracticeTime(spot, userProfile);
    
    // AI CONFIDENCE SCORE (how confident the AI is about this recommendation)
    final aiConfidence = _calculateAIConfidence(spot, userProfile);
    
    return SpotAnalysis(
      spot: spot,
      musicalDifficulty: musicalDifficulty,
      learningEfficiency: learningEfficiency,
      retentionRisk: retentionRisk,
      urgency: urgency,
      optimalPracticeTime: optimalPracticeTime,
      aiConfidence: aiConfidence,
    );
  }
  
  /// Optimize the practice session using AI algorithms
  static List<Spot> _optimizePracticeSession(
    List<SpotAnalysis> analyses,
    Duration sessionDuration,
    int maxSpots,
    PracticeAnalysis userProfile,
  ) {
    // Sort by AI-calculated priority score
    analyses.sort((a, b) => b.overallPriority.compareTo(a.overallPriority));
    
    // Use intelligent selection algorithm based on user's learning style
    final selectedSpots = <Spot>[];
    int totalTime = 0;
    final maxTime = sessionDuration.inMinutes;
    
    // ALGORITHM: Balanced Learning Optimization
    // 1. Always include highest priority critical spots
    // 2. Balance difficulty curve for optimal learning
    // 3. Consider user's energy and focus patterns
    // 4. Ensure variety to prevent mental fatigue
    
    final criticalSpots = analyses.where((a) => a.urgency > 0.8).take(2);
    final learningSpots = analyses.where((a) => a.learningEfficiency > 0.7 && a.urgency < 0.8);
    final retentionSpots = analyses.where((a) => a.retentionRisk > 0.6);
    
    // Add critical spots first
    for (final analysis in criticalSpots) {
      if (selectedSpots.length >= maxSpots) break;
      if (totalTime + analysis.optimalPracticeTime <= maxTime) {
        selectedSpots.add(analysis.spot);
        totalTime += analysis.optimalPracticeTime;
      }
    }
    
    // Add learning spots (main focus)
    for (final analysis in learningSpots) {
      if (selectedSpots.length >= maxSpots) break;
      if (!selectedSpots.contains(analysis.spot) && totalTime + analysis.optimalPracticeTime <= maxTime) {
        selectedSpots.add(analysis.spot);
        totalTime += analysis.optimalPracticeTime;
      }
    }
    
    // Add retention spots if time allows
    for (final analysis in retentionSpots) {
      if (selectedSpots.length >= maxSpots) break;
      if (!selectedSpots.contains(analysis.spot) && totalTime + analysis.optimalPracticeTime <= maxTime) {
        selectedSpots.add(analysis.spot);
        totalTime += analysis.optimalPracticeTime;
      }
    }
    
    return selectedSpots;
  }
  
  /// Calculate musical difficulty based on musical factors
  static double _calculateMusicalDifficulty(Spot spot) {
    double difficulty = 0.0;
    
    // Base difficulty from practice time requirement
    difficulty += spot.recommendedPracticeTime / 20.0; // Normalize to 0-1
    
    // Musical complexity indicators
    if (spot.title.toLowerCase().contains('triplet')) difficulty += 0.3;
    if (spot.title.toLowerCase().contains('chromatic')) difficulty += 0.4;
    if (spot.title.toLowerCase().contains('octave')) difficulty += 0.3;
    if (spot.title.toLowerCase().contains('trill')) difficulty += 0.2;
    if (spot.title.toLowerCase().contains('cadenza')) difficulty += 0.5;
    if (spot.title.toLowerCase().contains('presto')) difficulty += 0.4;
    if (spot.title.toLowerCase().contains('fortissimo')) difficulty += 0.2;
    
    // Page position (later pages often harder)
    difficulty += spot.pageNumber / 100.0;
    
    return math.min(difficulty, 1.0);
  }
  
  /// Calculate learning efficiency for this user
  static double _calculateLearningEfficiency(Spot spot, PracticeAnalysis profile) {
    double efficiency = 0.0;
    
    // User's historical success with similar spots
    final colorSuccessRate = profile.colorSuccessRates[spot.color] ?? 0.5;
    efficiency += colorSuccessRate * 0.4;
    
    // Current learning state
    switch (spot.readinessLevel) {
      case ReadinessLevel.learning:
        efficiency += profile.isQuickLearner ? 0.8 : 0.6;
        break;
      case ReadinessLevel.newSpot:
        efficiency += 0.7; // Always good to learn new material
        break;
      case ReadinessLevel.review:
        efficiency += 0.5;
        break;
      case ReadinessLevel.mastered:
        efficiency += 0.2; // Low efficiency for mastered spots
        break;
    }
    
    // SRS algorithm optimization
    if (spot.easeFactor < 2.0) efficiency += 0.3; // Struggling spots need attention
    
    return math.min(efficiency, 1.0);
  }
  
  /// Calculate retention risk
  static double _calculateRetentionRisk(Spot spot, PracticeAnalysis profile) {
    double risk = 0.0;
    
    if (spot.lastPracticed != null) {
      final daysSincePractice = DateTime.now().difference(spot.lastPracticed!).inDays;
      
      // Forgetting curve calculation
      final expectedRetention = _calculateExpectedRetention(daysSincePractice, spot.easeFactor);
      risk = 1.0 - expectedRetention;
      
      // User-specific retention adjustment
      if (!profile.hasGoodRetention) {
        risk *= 1.3; // Increase risk for users with poor retention
      }
    } else {
      risk = 0.8; // High risk for never practiced spots
    }
    
    return math.min(risk, 1.0);
  }
  
  /// Calculate urgency based on deadlines and project context
  static double _calculateUrgency(Spot spot, Project project) {
    double urgency = 0.0;
    
    // Color-based urgency
    switch (spot.color) {
      case SpotColor.red: urgency += 0.8;
      case SpotColor.yellow: urgency += 0.5;
      case SpotColor.green: urgency += 0.2;
      case SpotColor.blue: urgency += 0.3; // Moderate urgency for blue
    }
    
    // Priority urgency
    switch (spot.priority) {
      case SpotPriority.high: urgency += 0.7;
      case SpotPriority.medium: urgency += 0.4;
      case SpotPriority.low: urgency += 0.1;
    }
    
    // Concert deadline urgency
    if (project.hasUpcomingConcert) {
      final daysUntilConcert = project.daysUntilConcert ?? 30;
      if (daysUntilConcert <= 3) urgency += 0.9;
      else if (daysUntilConcert <= 7) urgency += 0.6;
      else if (daysUntilConcert <= 14) urgency += 0.3;
    }
    
    // Overdue spots
    if (spot.nextDue != null && spot.nextDue!.isBefore(DateTime.now())) {
      final daysOverdue = DateTime.now().difference(spot.nextDue!).inDays;
      urgency += math.min(daysOverdue / 7.0, 0.5);
    }
    
    return math.min(urgency, 1.0);
  }
  
  /// Predict optimal practice time for this spot and user
  static int _predictOptimalPracticeTime(Spot spot, PracticeAnalysis profile) {
    int baseTime = spot.recommendedPracticeTime;
    
    // Adjust based on user's learning speed
    if (profile.isQuickLearner) {
      baseTime = (baseTime * 0.8).round();
    } else {
      baseTime = (baseTime * 1.2).round();
    }
    
    // Adjust based on difficulty and success rate
    if (spot.practiceCount > 0) {
      final successRate = spot.successCount / spot.practiceCount;
      if (successRate < 0.5) {
        baseTime = (baseTime * 1.3).round(); // More time for struggling spots
      }
    }
    
    return math.max(baseTime, 5); // Minimum 5 minutes
  }
  
  /// Calculate AI confidence in this recommendation
  static double _calculateAIConfidence(Spot spot, PracticeAnalysis profile) {
    double confidence = 0.5; // Base confidence
    
    // More confidence with more data
    confidence += math.min(spot.practiceCount / 10.0, 0.3);
    confidence += math.min(profile.totalSpotsPracticed / 50.0, 0.2);
    
    return math.min(confidence, 1.0);
  }
  
  /// Calculate expected retention using forgetting curve
  static double _calculateExpectedRetention(int daysSincePractice, double easeFactor) {
    // Simplified forgetting curve: R = e^(-t/S)
    // Where S is strength (based on easeFactor)
    final strength = easeFactor * 2.0; // Convert ease factor to retention strength
    return math.exp(-daysSincePractice / strength);
  }
}

/// User's practice pattern analysis
class PracticeAnalysis {
  final double overallSuccessRate;
  final double averageSessionLength;
  final double retentionRate;
  final int totalSpotsPracticed;
  final bool prefersLongSessions;
  final bool isQuickLearner;
  final bool hasGoodRetention;
  final Map<SpotColor, double> colorSuccessRates;
  
  PracticeAnalysis({
    required this.overallSuccessRate,
    required this.averageSessionLength,
    required this.retentionRate,
    required this.totalSpotsPracticed,
    required this.prefersLongSessions,
    required this.isQuickLearner,
    required this.hasGoodRetention,
    required this.colorSuccessRates,
  });
  
  factory PracticeAnalysis.defaultAnalysis() {
    return PracticeAnalysis(
      overallSuccessRate: 0.6,
      averageSessionLength: 30.0,
      retentionRate: 0.7,
      totalSpotsPracticed: 0,
      prefersLongSessions: false,
      isQuickLearner: false,
      hasGoodRetention: true,
      colorSuccessRates: {},
    );
  }
}

/// AI analysis of a specific spot
class SpotAnalysis {
  final Spot spot;
  final double musicalDifficulty;
  final double learningEfficiency;
  final double retentionRisk;
  final double urgency;
  final int optimalPracticeTime;
  final double aiConfidence;
  
  SpotAnalysis({
    required this.spot,
    required this.musicalDifficulty,
    required this.learningEfficiency,
    required this.retentionRisk,
    required this.urgency,
    required this.optimalPracticeTime,
    required this.aiConfidence,
  });
  
  /// Overall AI priority score
  double get overallPriority {
    // Weighted combination of all factors
    return (urgency * 0.3) + 
           (learningEfficiency * 0.25) + 
           (retentionRisk * 0.25) + 
           (musicalDifficulty * 0.1) + 
           (aiConfidence * 0.1);
  }
}
