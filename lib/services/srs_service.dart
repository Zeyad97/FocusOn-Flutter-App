import 'dart:math' as math;
import '../models/spot.dart';
import '../models/project.dart';

/// SRS difficulty profiles for different learning approaches
enum SRSProfile {
  aggressive, // Fast advancement, higher risk
  standard,   // Balanced approach
  gentle,     // Conservative, ensures mastery
}

extension SRSProfileExtension on SRSProfile {
  String get displayName {
    switch (this) {
      case SRSProfile.aggressive:
        return 'Aggressive';
      case SRSProfile.standard:
        return 'Standard';
      case SRSProfile.gentle:
        return 'Gentle';
    }
  }

  String get description {
    switch (this) {
      case SRSProfile.aggressive:
        return 'Fast progression, higher challenge';
      case SRSProfile.standard:
        return 'Balanced learning pace';
      case SRSProfile.gentle:
        return 'Slower, ensures mastery';
    }
  }

  /// Base interval multipliers for each profile
  double get baseMultiplier {
    switch (this) {
      case SRSProfile.aggressive:
        return 1.8;
      case SRSProfile.standard:
        return 1.5;
      case SRSProfile.gentle:
        return 1.2;
    }
  }

  /// Minimum interval between reviews (hours)
  int get minimumInterval {
    switch (this) {
      case SRSProfile.aggressive:
        return 4;
      case SRSProfile.standard:
        return 8;
      case SRSProfile.gentle:
        return 12;
    }
  }
}

/// SRS calculation settings
class SRSSettings {
  final SRSProfile profile;
  final double redSpotFrequency;    // % of concert timeline (8-25%)
  final double yellowSpotFrequency; // % of concert timeline (12-30%)
  final double greenSpotFrequency;  // % of concert timeline (15-35%)
  final Duration retryLag;          // Time before retry after failure
  final int sleepGateHour;          // Don't schedule reviews after this hour
  final Map<SpotColor, int> minWeeklyTouches; // Minimum weekly practice

  const SRSSettings({
    this.profile = SRSProfile.standard,
    this.redSpotFrequency = 0.15,
    this.yellowSpotFrequency = 0.20,
    this.greenSpotFrequency = 0.25,
    this.retryLag = const Duration(minutes: 30),
    this.sleepGateHour = 22,
    this.minWeeklyTouches = const {
      SpotColor.red: 3,
      SpotColor.yellow: 2,
      SpotColor.green: 1,
    },
  });

  SRSSettings copyWith({
    SRSProfile? profile,
    double? redSpotFrequency,
    double? yellowSpotFrequency,
    double? greenSpotFrequency,
    Duration? retryLag,
    int? sleepGateHour,
    Map<SpotColor, int>? minWeeklyTouches,
  }) {
    return SRSSettings(
      profile: profile ?? this.profile,
      redSpotFrequency: redSpotFrequency ?? this.redSpotFrequency,
      yellowSpotFrequency: yellowSpotFrequency ?? this.yellowSpotFrequency,
      greenSpotFrequency: greenSpotFrequency ?? this.greenSpotFrequency,
      retryLag: retryLag ?? this.retryLag,
      sleepGateHour: sleepGateHour ?? this.sleepGateHour,
      minWeeklyTouches: minWeeklyTouches ?? this.minWeeklyTouches,
    );
  }
}

/// Spaced Repetition System for intelligent spot scheduling
class SRSService {
  final SRSSettings settings;

  const SRSService({this.settings = const SRSSettings()});

  /// Calculate next due date for a spot based on practice result
  DateTime calculateNextDue(
    Spot spot,
    SpotResult result, {
    DateTime? concertDate,
    DateTime? customTime,
  }) {
    final now = customTime ?? DateTime.now();
    
    // Handle immediate retry for failures
    if (result == SpotResult.failed) {
      return now.add(settings.retryLag);
    }

    // Calculate base interval based on spot history and color
    final baseInterval = _calculateBaseInterval(spot, result, concertDate);
    
    // Apply result-based multiplier
    final adjustedInterval = Duration(
      milliseconds: (baseInterval.inMilliseconds * result.srsMultiplier).round(),
    );

    // Apply concert pressure if applicable
    final finalInterval = _applyConcertPressure(
      adjustedInterval, 
      spot.color, 
      concertDate,
      now,
    );

    // Ensure minimum interval
    final minimumDuration = Duration(hours: settings.profile.minimumInterval);
    final actualInterval = finalInterval.inMilliseconds > minimumDuration.inMilliseconds
        ? finalInterval
        : minimumDuration;

    // Apply sleep gate (don't schedule late at night)
    return _applySleepGate(now.add(actualInterval));
  }

  /// Calculate base interval between reviews
  Duration _calculateBaseInterval(
    Spot spot, 
    SpotResult result, 
    DateTime? concertDate,
  ) {
    // Start with color-based frequency
    double frequency;
    switch (spot.color) {
      case SpotColor.red:
        frequency = settings.redSpotFrequency;
        break;
      case SpotColor.yellow:
        frequency = settings.yellowSpotFrequency;
        break;
      case SpotColor.green:
        frequency = settings.greenSpotFrequency;
        break;
      case SpotColor.blue:
        frequency = settings.yellowSpotFrequency; // Use yellow frequency for blue
        break;
    }

    // Calculate base interval from frequency
    Duration baseInterval;
    if (concertDate != null) {
      final timeUntilConcert = concertDate.difference(DateTime.now());
      baseInterval = Duration(
        milliseconds: (timeUntilConcert.inMilliseconds * frequency).round(),
      );
    } else {
      // Default intervals without concert pressure
      final baseDays = _getDefaultInterval(spot.color);
      baseInterval = Duration(days: baseDays);
    }

    // Apply difficulty multiplier (harder spots reviewed more frequently)
    final difficultyMultiplier = 1.0 - (spot.difficulty - 1) * 0.15; // 1.0 to 0.4
    baseInterval = Duration(
      milliseconds: (baseInterval.inMilliseconds * difficultyMultiplier).round(),
    );

    // Apply success rate adjustment
    final successRate = spot.successRate;
    final successMultiplier = math.max(0.5, 0.5 + successRate); // 0.5 to 1.5
    baseInterval = Duration(
      milliseconds: (baseInterval.inMilliseconds * successMultiplier).round(),
    );

    // Apply profile multiplier
    baseInterval = Duration(
      milliseconds: (baseInterval.inMilliseconds * settings.profile.baseMultiplier).round(),
    );

    return baseInterval;
  }

  /// Get default interval in days for each color without concert pressure
  int _getDefaultInterval(SpotColor color) {
    switch (color) {
      case SpotColor.red:
        return 1; // Daily for critical spots
      case SpotColor.yellow:
        return 2; // Every 2 days for practice spots
      case SpotColor.green:
        return 4; // Every 4 days for maintenance spots
      case SpotColor.blue:
        return 3; // Every 3 days for blue spots
    }
  }

  /// Apply concert deadline pressure to interval
  Duration _applyConcertPressure(
    Duration baseInterval,
    SpotColor color,
    DateTime? concertDate,
    DateTime now,
  ) {
    if (concertDate == null) return baseInterval;

    final daysUntilConcert = concertDate.difference(now).inDays;
    if (daysUntilConcert <= 0) return baseInterval;

    // Increase frequency (decrease interval) as concert approaches
    double pressureMultiplier = 1.0;
    
    if (daysUntilConcert <= 3) {
      pressureMultiplier = 0.3; // 3x more frequent
    } else if (daysUntilConcert <= 7) {
      pressureMultiplier = 0.5; // 2x more frequent
    } else if (daysUntilConcert <= 14) {
      pressureMultiplier = 0.7; // 1.5x more frequent
    } else if (daysUntilConcert <= 30) {
      pressureMultiplier = 0.85; // Slight increase
    }

    // Critical spots get even more pressure
    if (color == SpotColor.red) {
      pressureMultiplier *= 0.8;
    }

    return Duration(
      milliseconds: (baseInterval.inMilliseconds * pressureMultiplier).round(),
    );
  }

  /// Apply sleep gate to avoid late night scheduling
  DateTime _applySleepGate(DateTime scheduledTime) {
    if (scheduledTime.hour >= settings.sleepGateHour || scheduledTime.hour < 6) {
      // Move to next morning at 8 AM
      final nextMorning = DateTime(
        scheduledTime.year,
        scheduledTime.month,
        scheduledTime.day + (scheduledTime.hour >= settings.sleepGateHour ? 1 : 0),
        8,
        0,
      );
      return nextMorning;
    }
    return scheduledTime;
  }

  /// Calculate urgency score for smart practice selection (0.0-1.0)
  double calculateUrgencyScore(
    Spot spot, {
    DateTime? concertDate,
    DateTime? currentTime,
  }) {
    final now = currentTime ?? DateTime.now();
    
    // Base urgency from color and overdue status
    double urgency = spot.color.priorityWeight;
    
    // Overdue penalty
    if (spot.nextDue.isBefore(now)) {
      final hoursSinceOverdue = now.difference(spot.nextDue).inHours;
      urgency += math.min(0.3, hoursSinceOverdue * 0.01); // Max 30% penalty
    }
    
    // Concert pressure
    if (concertDate != null) {
      final daysUntilConcert = concertDate.difference(now).inDays;
      if (daysUntilConcert > 0 && daysUntilConcert <= 30) {
        final concertPressure = 1.0 - (daysUntilConcert / 30.0); // 0 to 1
        urgency += concertPressure * 0.4; // Up to 40% bonus
      }
    }
    
    // Difficulty factor (harder spots are more urgent)
    urgency += (spot.difficulty / 5.0) * 0.2; // Up to 20% bonus
    
    // Success rate factor (struggling spots are more urgent)
    final successRate = spot.successRate;
    if (successRate < 0.7) {
      urgency += (0.7 - successRate) * 0.3; // Up to 30% bonus for low success
    }
    
    return math.min(1.0, urgency);
  }

  /// Select spots for smart practice session
  List<Spot> selectSpotsForSmartPractice(
    List<Spot> allSpots, {
    Duration? targetDuration,
    int? maxSpots,
    DateTime? concertDate,
    List<String>? projectIds,
  }) {
    // Filter spots by project if specified
    var candidateSpots = allSpots;
    if (projectIds != null && projectIds.isNotEmpty) {
      candidateSpots = allSpots.where((spot) => 
          projectIds.contains(spot.pieceId)).toList();
    }

    // Calculate urgency scores for all spots
    final spotsWithUrgency = candidateSpots.map((spot) => {
      'spot': spot,
      'urgency': calculateUrgencyScore(spot, concertDate: concertDate),
    }).toList();

    // Sort by urgency (highest first)
    spotsWithUrgency.sort((a, b) => 
        (b['urgency'] as double).compareTo(a['urgency'] as double));

    // Select spots based on constraints
    final selectedSpots = <Spot>[];
    Duration totalTime = Duration.zero;
    final maxSpotsToSelect = maxSpots ?? 20;
    final targetTime = targetDuration ?? const Duration(minutes: 30);

    for (final item in spotsWithUrgency) {
      if (selectedSpots.length >= maxSpotsToSelect) break;
      
      final spot = item['spot'] as Spot;
      final spotTime = spot.recommendedPracticeTime;
      
      if (targetDuration != null && 
          totalTime + spotTime > targetTime &&
          selectedSpots.isNotEmpty) {
        break; // Don't exceed target duration
      }
      
      selectedSpots.add(spot);
      totalTime += spotTime;
    }

    return selectedSpots;
  }

  /// Suggest optimal practice plan for a project
  Map<String, dynamic> suggestPracticePlan(
    Project project,
    List<Spot> projectSpots, {
    Duration? dailyTimeAvailable,
  }) {
    final daysUntilConcert = project.daysUntilConcert ?? 365;
    final dailyTime = dailyTimeAvailable ?? project.dailyPracticeGoal;
    
    // Categorize spots by color
    final redSpots = projectSpots.where((s) => s.color == SpotColor.red).toList();
    final yellowSpots = projectSpots.where((s) => s.color == SpotColor.yellow).toList();
    final greenSpots = projectSpots.where((s) => s.color == SpotColor.green).toList();
    
    // Calculate recommended daily allocations
    final totalSpots = projectSpots.length;
    if (totalSpots == 0) {
      return {
        'feasible': true,
        'redTime': Duration.zero,
        'yellowTime': Duration.zero,
        'greenTime': Duration.zero,
        'recommendations': <String>[],
      };
    }
    
    // Time allocation based on urgency and concert timeline
    double redRatio, yellowRatio, greenRatio;
    
    if (daysUntilConcert <= 7) {
      // Concert mode: focus heavily on critical spots
      redRatio = 0.7;
      yellowRatio = 0.25;
      greenRatio = 0.05;
    } else if (daysUntilConcert <= 30) {
      // Preparation mode: balanced focus
      redRatio = 0.5;
      yellowRatio = 0.35;
      greenRatio = 0.15;
    } else {
      // Learning mode: more balanced
      redRatio = 0.4;
      yellowRatio = 0.4;
      greenRatio = 0.2;
    }
    
    final redTime = Duration(milliseconds: (dailyTime.inMilliseconds * redRatio).round());
    final yellowTime = Duration(milliseconds: (dailyTime.inMilliseconds * yellowRatio).round());
    final greenTime = Duration(milliseconds: (dailyTime.inMilliseconds * greenRatio).round());
    
    // Generate recommendations
    final recommendations = <String>[];
    
    if (redSpots.length > 10) {
      recommendations.add('High number of critical spots detected. Consider extending daily practice time.');
    }
    
    if (daysUntilConcert <= 14 && redSpots.isNotEmpty) {
      recommendations.add('Concert approaching! Focus primarily on critical (red) spots.');
    }
    
    if (yellowSpots.length > redSpots.length * 2) {
      recommendations.add('Many practice spots could be promoted to maintenance with consistent work.');
    }
    
    // Check feasibility
    final totalNeededTime = redSpots.fold<Duration>(Duration.zero, (sum, spot) => 
        sum + spot.recommendedPracticeTime) +
      yellowSpots.fold<Duration>(Duration.zero, (sum, spot) => 
        sum + spot.recommendedPracticeTime);
    
    final isFeasible = totalNeededTime.inMilliseconds <= 
        (dailyTime.inMilliseconds * daysUntilConcert * 0.8); // 80% utilization
    
    if (!isFeasible) {
      recommendations.add('Current practice goal may not be sufficient for concert readiness. Consider increasing daily time or reducing piece difficulty.');
    }
    
    return {
      'feasible': isFeasible,
      'redTime': redTime,
      'yellowTime': yellowTime,
      'greenTime': greenTime,
      'recommendations': recommendations,
      'totalEstimatedTime': totalNeededTime,
      'daysRequired': totalNeededTime.inDays,
    };
  }

  /// Update spot color based on recent performance
  SpotColor suggestColorUpdate(Spot spot) {
    if (spot.history.length < 3) return spot.color; // Need more data
    
    // Look at recent performance (last 5 sessions)
    final recentHistory = spot.history.take(5).toList();
    final successCount = recentHistory.where((h) => 
        h.result == SpotResult.success).length;
    final failCount = recentHistory.where((h) => 
        h.result == SpotResult.failed).length;
    
    final successRate = successCount / recentHistory.length;
    
    // Promotion thresholds
    if (successRate >= 0.8 && failCount == 0) {
      // Very good performance - consider promotion
      switch (spot.color) {
        case SpotColor.red:
          return SpotColor.yellow;
        case SpotColor.yellow:
          return SpotColor.green;
        case SpotColor.green:
          return SpotColor.green; // Already at top
        case SpotColor.blue:
          return SpotColor.green; // Blue promotes to green
      }
    }
    
    // Demotion thresholds
    if (successRate <= 0.4 || failCount >= 2) {
      // Poor performance - consider demotion
      switch (spot.color) {
        case SpotColor.green:
          return SpotColor.yellow;
        case SpotColor.yellow:
          return SpotColor.red;
        case SpotColor.red:
          return SpotColor.red; // Already at bottom
        case SpotColor.blue:
          return SpotColor.yellow; // Blue demotes to yellow
      }
    }
    
    return spot.color; // No change needed
  }
}
