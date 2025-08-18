import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/piece.dart';
import '../models/spot.dart';
import '../models/project.dart';
import 'srs_service.dart';

/// Readiness levels for performance preparation
enum ReadinessLevel {
  notReady(0, 'Not Ready'),
  learning(25, 'Learning'),
  practicing(50, 'Practicing'),
  polishing(75, 'Polishing'),
  performanceReady(100, 'Performance Ready');
  
  const ReadinessLevel(this.score, this.label);
  final int score;
  final String label;
  
  /// Color for UI display
  Color get color {
    switch (this) {
      case ReadinessLevel.notReady:
        return const Color(0xFFE53E3E); // Red
      case ReadinessLevel.learning:
        return const Color(0xFFED8936); // Orange
      case ReadinessLevel.practicing:
        return const Color(0xFFECC94B); // Yellow
      case ReadinessLevel.polishing:
        return const Color(0xFF38A169); // Green
      case ReadinessLevel.performanceReady:
        return const Color(0xFF3182CE); // Blue
    }
  }
}

/// Performance readiness scoring system
class ReadinessService {
  final SRSService _srsService;
  
  const ReadinessService({SRSService? srsService}) 
      : _srsService = srsService ?? const SRSService();
  
  /// Calculate overall readiness score for a piece (0-100)
  double calculatePieceReadiness(
    Piece piece, {
    DateTime? concertDate,
    Duration? availablePracticeTime,
  }) {
    if (piece.spots.isEmpty) {
      // No spots means piece is either too easy or not analyzed
      return piece.totalTimeSpent.inMinutes > 60 ? 85.0 : 45.0;
    }
    
    final spots = piece.spots;
    final now = DateTime.now();
    
    // Base score from spot completion rates
    double spotScore = 0.0;
    double weightSum = 0.0;
    
    for (final spot in spots) {
      final weight = spot.color.priorityWeight;
      final spotReadiness = _calculateSpotReadiness(spot, concertDate: concertDate);
      spotScore += spotReadiness * weight;
      weightSum += weight;
    }
    
    if (weightSum > 0) {
      spotScore /= weightSum;
    }
    
    // Practice time factor (diminishing returns)
    final practiceHours = piece.totalTimeSpent.inMinutes / 60.0;
    final practiceScore = math.min(100.0, practiceHours * 15.0); // 100% at ~6.7 hours
    final practiceMultiplier = 1.0 + (practiceScore / 100.0) * 0.3; // Up to 30% bonus
    
    // Tempo achievement factor
    double tempoMultiplier = 1.0;
    if (piece.targetTempo != null && piece.currentTempo != null) {
      final tempoRatio = piece.currentTempo! / piece.targetTempo!;
      if (tempoRatio >= 1.0) {
        tempoMultiplier = 1.2; // 20% bonus for reaching target tempo
      } else if (tempoRatio >= 0.8) {
        tempoMultiplier = 1.0 + (tempoRatio - 0.8) * 0.5; // Gradual bonus
      } else {
        tempoMultiplier = 0.8 + tempoRatio * 0.25; // Penalty for slow tempo
      }
    }
    
    // Recent practice consistency factor
    final recentPracticeMultiplier = _calculateRecentPracticeMultiplier(piece);
    
    // Concert pressure factor
    double pressureMultiplier = 1.0;
    if (concertDate != null) {
      final daysUntilConcert = concertDate.difference(now).inDays;
      if (daysUntilConcert <= 0) {
        pressureMultiplier = 0.5; // Major penalty for overdue
      } else if (daysUntilConcert <= 7) {
        pressureMultiplier = 0.7; // Need higher standards near concert
      } else if (daysUntilConcert <= 30) {
        pressureMultiplier = 0.85; // Moderate pressure
      }
    }
    
    final finalScore = spotScore * 
        practiceMultiplier * 
        tempoMultiplier * 
        recentPracticeMultiplier * 
        pressureMultiplier;
    
    return math.max(0.0, math.min(100.0, finalScore));
  }
  
  /// Calculate readiness for individual spot
  double _calculateSpotReadiness(Spot spot, {DateTime? concertDate}) {
    final successRate = spot.successRate;
    final history = spot.history;
    
    // Base score from success rate
    double baseScore = successRate * 100.0;
    
    // Recent performance trend
    if (history.length >= 3) {
      final recentHistory = history.take(5).toList();
      final recentSuccessRate = recentHistory
          .where((h) => h.result == SpotResult.success)
          .length / recentHistory.length;
      
      // Weight recent performance more heavily
      baseScore = (baseScore * 0.6) + (recentSuccessRate * 100.0 * 0.4);
    }
    
    // Consistency factor (lower variance = higher score)
    final consistencyMultiplier = _calculateConsistencyMultiplier(spot);
    
    // Overdue penalty
    final now = DateTime.now();
    double overdueMultiplier = 1.0;
    if (spot.nextDue.isBefore(now)) {
      final hoursOverdue = now.difference(spot.nextDue).inHours;
      overdueMultiplier = math.max(0.5, 1.0 - (hoursOverdue * 0.01));
    }
    
    // Difficulty adjustment
    final difficultyMultiplier = _getDifficultyMultiplier(spot.difficulty);
    
    return baseScore * consistencyMultiplier * overdueMultiplier * difficultyMultiplier;
  }
  
  /// Calculate recent practice consistency multiplier
  double _calculateRecentPracticeMultiplier(Piece piece) {
    final now = DateTime.now();
    final recentDays = 7;
    final startDate = now.subtract(Duration(days: recentDays));
    
    // Count days with practice in last week
    final practiceDays = <int>{};
    
    for (final spot in piece.spots) {
      for (final history in spot.history) {
        if (history.timestamp.isAfter(startDate)) {
          practiceDays.add(history.timestamp.day);
        }
      }
    }
    
    final practiceFrequency = practiceDays.length / recentDays;
    
    // Return multiplier between 0.7 and 1.3
    return 0.7 + (practiceFrequency * 0.6);
  }
  
  /// Calculate consistency multiplier based on performance variance
  double _calculateConsistencyMultiplier(Spot spot) {
    final history = spot.history;
    if (history.length < 3) return 1.0;
    
    // Calculate variance in recent performance
    final recentResults = history.take(10).map((h) => 
        h.result == SpotResult.success ? 1.0 : 0.0).toList();
    
    if (recentResults.isEmpty) return 1.0;
    
    final mean = recentResults.reduce((a, b) => a + b) / recentResults.length;
    final variance = recentResults
        .map((x) => math.pow(x - mean, 2))
        .reduce((a, b) => a + b) / recentResults.length;
    
    // Lower variance = higher consistency = higher multiplier
    return math.max(0.8, 1.0 - variance * 0.3);
  }
  
  /// Get difficulty multiplier for readiness calculation
  double _getDifficultyMultiplier(int difficulty) {
    // Harder pieces need higher success rates for same readiness
    switch (difficulty) {
      case 1:
        return 1.2; // Easy pieces ready faster
      case 2:
        return 1.1;
      case 3:
        return 1.0; // Baseline
      case 4:
        return 0.9;
      case 5:
        return 0.8; // Hard pieces need more work
      default:
        return 1.0;
    }
  }
  
  /// Get readiness level from score
  ReadinessLevel getReadinessLevel(double score) {
    if (score >= 90) return ReadinessLevel.performanceReady;
    if (score >= 75) return ReadinessLevel.polishing;
    if (score >= 50) return ReadinessLevel.practicing;
    if (score >= 25) return ReadinessLevel.learning;
    return ReadinessLevel.notReady;
  }
  
  /// Calculate project readiness for concerts
  Map<String, dynamic> calculateProjectReadiness(
    Project project,
    List<Piece> pieces,
  ) {
    if (pieces.isEmpty) {
      return {
        'overallScore': 0.0,
        'level': ReadinessLevel.notReady,
        'pieceScores': <Map<String, dynamic>>[],
        'recommendations': ['Add pieces to your project'],
        'timeNeeded': Duration.zero,
        'feasible': false,
      };
    }
    
    final concertDate = project.concertDate;
    final pieceScores = <Map<String, dynamic>>[];
    double totalScore = 0.0;
    Duration totalTimeNeeded = Duration.zero;
    
    for (final piece in pieces) {
      final score = calculatePieceReadiness(
        piece, 
        concertDate: concertDate,
      );
      
      final timeNeeded = estimateTimeToReadiness(piece, targetScore: 85.0);
      
      pieceScores.add({
        'piece': piece,
        'score': score,
        'level': getReadinessLevel(score),
        'timeNeeded': timeNeeded,
      });
      
      totalScore += score;
      totalTimeNeeded = Duration(
        milliseconds: totalTimeNeeded.inMilliseconds + timeNeeded.inMilliseconds,
      );
    }
    
    final averageScore = totalScore / pieces.length;
    final overallLevel = getReadinessLevel(averageScore);
    
    // Generate recommendations
    final recommendations = _generateProjectRecommendations(
      project,
      pieceScores,
      averageScore,
    );
    
    // Check feasibility
    final daysUntilConcert = concertDate?.difference(DateTime.now()).inDays ?? 365;
    final dailyTimeAvailable = project.dailyPracticeGoal.inMinutes;
    final totalTimeAvailable = Duration(minutes: dailyTimeAvailable * daysUntilConcert);
    final feasible = totalTimeNeeded.inMilliseconds <= totalTimeAvailable.inMilliseconds;
    
    return {
      'overallScore': averageScore,
      'level': overallLevel,
      'pieceScores': pieceScores,
      'recommendations': recommendations,
      'timeNeeded': totalTimeNeeded,
      'feasible': feasible,
      'daysUntilConcert': daysUntilConcert,
    };
  }
  
  /// Estimate time needed to reach target readiness
  Duration estimateTimeToReadiness(Piece piece, {double targetScore = 85.0}) {
    final currentScore = calculatePieceReadiness(piece);
    
    if (currentScore >= targetScore) {
      return Duration.zero;
    }
    
    final scoreGap = targetScore - currentScore;
    final difficulty = piece.difficulty;
    
    // Base time estimation (minutes per score point)
    double minutesPerPoint = 2.0;
    
    // Adjust for difficulty
    switch (difficulty) {
      case 1:
        minutesPerPoint = 1.0;
        break;
      case 2:
        minutesPerPoint = 1.5;
        break;
      case 3:
        minutesPerPoint = 2.0;
        break;
      case 4:
        minutesPerPoint = 3.0;
        break;
      case 5:
        minutesPerPoint = 4.0;
        break;
    }
    
    // Adjust for current progress (diminishing returns)
    if (currentScore > 50) {
      minutesPerPoint *= 1.5; // Harder to improve at higher levels
    }
    
    final totalMinutes = scoreGap * minutesPerPoint;
    return Duration(minutes: totalMinutes.round());
  }
  
  /// Generate recommendations for project improvement
  List<String> _generateProjectRecommendations(
    Project project,
    List<Map<String, dynamic>> pieceScores,
    double averageScore,
  ) {
    final recommendations = <String>[];
    final concertDate = project.concertDate;
    
    // Overall readiness recommendations
    if (averageScore < 50) {
      recommendations.add('Focus on fundamental practice - your pieces need significant work');
    } else if (averageScore < 75) {
      recommendations.add('Good progress! Focus on consistency and tempo building');
    } else if (averageScore < 90) {
      recommendations.add('Nearly ready! Polish dynamics and musical expression');
    }
    
    // Concert timing recommendations
    if (concertDate != null) {
      final daysUntilConcert = concertDate.difference(DateTime.now()).inDays;
      
      if (daysUntilConcert <= 7 && averageScore < 80) {
        recommendations.add('URGENT: Concert is soon! Focus only on critical spots');
      } else if (daysUntilConcert <= 30 && averageScore < 70) {
        recommendations.add('Concert approaching - increase practice intensity');
      }
    }
    
    // Piece-specific recommendations
    final lowScorePieces = pieceScores
        .where((p) => p['score'] < 60)
        .map((p) => (p['piece'] as Piece).title)
        .take(3)
        .toList();
    
    if (lowScorePieces.isNotEmpty) {
      recommendations.add('Pieces needing attention: ${lowScorePieces.join(', ')}');
    }
    
    // Critical spots recommendation
    final totalCriticalSpots = pieceScores
        .map((p) => (p['piece'] as Piece).spots.where((s) => s.color == SpotColor.red).length)
        .reduce((a, b) => a + b);
    
    if (totalCriticalSpots > 10) {
      recommendations.add('High number of critical spots ($totalCriticalSpots) - consider reducing repertoire');
    }
    
    return recommendations;
  }
  
  /// Calculate practice priority for smart session planning
  double calculatePracticePriority(
    Piece piece, {
    DateTime? concertDate,
    List<String>? focusTags,
  }) {
    double priority = calculatePieceReadiness(piece);
    
    // Invert score (lower readiness = higher priority)
    priority = 100.0 - priority;
    
    // Concert pressure boost
    if (concertDate != null) {
      final daysUntilConcert = concertDate.difference(DateTime.now()).inDays;
      if (daysUntilConcert <= 7) {
        priority *= 1.5;
      } else if (daysUntilConcert <= 30) {
        priority *= 1.2;
      }
    }
    
    // Tag focus boost
    if (focusTags != null && focusTags.isNotEmpty) {
      final hasMatchingTag = piece.tags.any((tag) => focusTags.contains(tag));
      if (hasMatchingTag) {
        priority *= 1.3;
      }
    }
    
    // Recent practice recency penalty
    final daysSinceLastPractice = _getDaysSinceLastPractice(piece);
    if (daysSinceLastPractice > 3) {
      priority *= 1.0 + (daysSinceLastPractice * 0.1);
    }
    
    return priority;
  }
  
  /// Get days since last practice session
  int _getDaysSinceLastPractice(Piece piece) {
    final now = DateTime.now();
    DateTime? lastPractice;
    
    for (final spot in piece.spots) {
      for (final history in spot.history) {
        if (lastPractice == null || history.timestamp.isAfter(lastPractice)) {
          lastPractice = history.timestamp;
        }
      }
    }
    
    if (lastPractice == null) return 999; // Never practiced
    
    return now.difference(lastPractice).inDays;
  }
}

/// Extension for color coding readiness scores
extension ReadinessScoreExtension on double {
  /// Get color for readiness score
  Color get readinessColor {
    if (this >= 90) return const Color(0xFF3182CE); // Blue
    if (this >= 75) return const Color(0xFF38A169); // Green
    if (this >= 50) return const Color(0xFFECC94B); // Yellow
    if (this >= 25) return const Color(0xFFED8936); // Orange
    return const Color(0xFFE53E3E); // Red
  }
  
  /// Get readiness level from score
  ReadinessLevel get readinessLevel {
    if (this >= 90) return ReadinessLevel.performanceReady;
    if (this >= 75) return ReadinessLevel.polishing;
    if (this >= 50) return ReadinessLevel.practicing;
    if (this >= 25) return ReadinessLevel.learning;
    return ReadinessLevel.notReady;
  }
}
