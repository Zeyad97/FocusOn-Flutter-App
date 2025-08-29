import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';

/// Priority levels for practice spots
enum SpotPriority {
  low('Low'),
  medium('Medium'),
  high('High');

  const SpotPriority(this.displayName);
  final String displayName;
}

/// Readiness levels based on SRS progression
enum ReadinessLevel {
  newSpot('New'),
  learning('Learning'),
  review('Review'),
  mastered('Mastered');

  const ReadinessLevel(this.displayName);
  final String displayName;
}

/// Color coding for visual spot management
enum SpotColor {
  red('Critical', 4),     // Highest priority - Urgent practice needed
  yellow('Practice', 3),  // Needs active work
  green('Maintenance', 2), // Needs occasional review
  blue('Solved', 1);      // Nearly complete

  const SpotColor(this.displayName, this.priority);
  final String displayName;
  final int priority;

  /// Get the corresponding visual color
  Color get visualColor {
    switch (this) {
      case red: return Colors.red;
      case yellow: return Colors.orange;
      case green: return Colors.green;
      case blue: return Colors.blue;
    }
  }

  /// Get priority weight for scheduling (higher = more urgent)
  double get priorityWeight {
    switch (this) {
      case red: return 1.0;     // Highest priority
      case yellow: return 0.7;  // High priority
      case green: return 0.4;   // Medium priority
      case blue: return 0.2;    // Low priority
    }
  }

  /// Get a readable description of the color's meaning
  String get description {
    switch (this) {
      case red: return 'Urgent spots requiring immediate attention';
      case yellow: return 'Spots in active practice that need work';
      case green: return 'Spots that are becoming stable';
      case blue: return 'Spots that are nearly mastered';
    }
  }
}

/// Practice spot model for SRS-based music practice management
class Spot {
  final String id;
  final String pieceId;
  final String title;
  final String? description;
  final String? notes;
  final int pageNumber;
  final double x; // Relative position 0.0-1.0
  final double y; // Relative position 0.0-1.0
  final double width; // Relative size 0.0-1.0
  final double height; // Relative size 0.0-1.0
  final SpotPriority priority;
  final ReadinessLevel readinessLevel;
  final SpotColor color;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastPracticed;
  final DateTime? nextDue;
  final int practiceCount;
  final int successCount;
  final int failureCount;
  final double easeFactor; // SRS ease factor (1.3+)
  final int interval; // SRS interval in days
  final int repetitions; // SRS repetition count
  final bool isActive;
  final Map<String, dynamic>? metadata;
  // ScoreRead Pro SRS enhancements
  final int progressIndex; // SRS progress counter (0+)
  final double? lastGapDays; // Last gap between reviews
  final bool manualOverride; // Manual reschedule flag
  final bool retryToday; // Same-day retry flag
  final SpotResult? lastResult; // Last practice result
  final DateTime? lastResultAt; // When last result was recorded
  final List<SpotHistory> history; // Practice history
  
  // Private field to store explicit practice time
  final int? _recommendedPracticeTime;

  const Spot({
    required this.id,
    required this.pieceId,
    required this.title,
    this.description,
    this.notes,
    required this.pageNumber,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.priority,
    required this.readinessLevel,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    this.lastPracticed,
    this.nextDue,
    this.practiceCount = 0,
    this.successCount = 0,
    this.failureCount = 0,
    this.easeFactor = 2.5,
    this.interval = 1,
    this.repetitions = 0,
    int? recommendedPracticeTime,
    this.isActive = true,
    this.metadata,
    this.progressIndex = 0,
    this.lastGapDays,
    this.manualOverride = false,
    this.retryToday = false,
    this.lastResult,
    this.lastResultAt,
    this.history = const [],
  }) : _recommendedPracticeTime = recommendedPracticeTime;

  /// Calculate success rate as a percentage (0.0 to 1.0)
  double get successRate {
    if (practiceCount == 0) return 0.0;
    return successCount / practiceCount;
  }

  /// Get difficulty level (1-5 scale, based on failure rate and other factors)
  int get difficulty {
    if (practiceCount == 0) return 3; // Default medium difficulty
    
    final failureRate = failureCount / practiceCount;
    if (failureRate > 0.7) return 5; // Very hard
    if (failureRate > 0.5) return 4; // Hard
    if (failureRate > 0.3) return 3; // Medium
    if (failureRate > 0.1) return 2; // Easy
    return 1; // Very easy
  }

  /// Calculate recommended practice time based on spot properties
  int get recommendedPracticeTime {
    if (_recommendedPracticeTime != null) return _recommendedPracticeTime!;
    
    // Base time starts with difficulty level
    int baseTime = 3 + difficulty; // 4-8 minutes base
    
    // Adjust based on color priority
    switch (color) {
      case SpotColor.red:
        baseTime += 4; // Critical spots need more time
        break;
      case SpotColor.yellow:
        baseTime += 2; // Learning spots need moderate time
        break;
      case SpotColor.green:
        baseTime += 1; // Maintenance spots need less time
        break;
      case SpotColor.blue:
        baseTime -= 1; // Nearly mastered spots need minimal time
        break;
    }
    
    // Adjust based on readiness level
    switch (readinessLevel) {
      case ReadinessLevel.newSpot:
        baseTime += 3; // New spots need exploration time
        break;
      case ReadinessLevel.learning:
        baseTime += 2; // Active learning needs time
        break;
      case ReadinessLevel.review:
        baseTime += 0; // Review is standard
        break;
      case ReadinessLevel.mastered:
        baseTime -= 2; // Mastered spots need quick review only
        break;
    }
    
    // Adjust based on recent practice success
    if (practiceCount > 0) {
      final successRate = successCount / practiceCount;
      if (successRate < 0.4) {
        baseTime += 3; // Struggling spots need more time
      } else if (successRate > 0.8) {
        baseTime -= 1; // Successful spots need less time
      }
    }
    
    // Ensure reasonable bounds (3-15 minutes)
    return baseTime.clamp(3, 15);
  }

  /// Create a copy with updated fields
  Spot copyWith({
    String? id,
    String? pieceId,
    String? title,
    String? description,
    String? notes,
    int? pageNumber,
    double? x,
    double? y,
    double? width,
    double? height,
    SpotPriority? priority,
    ReadinessLevel? readinessLevel,
    SpotColor? color,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastPracticed,
    DateTime? nextDue,
    int? practiceCount,
    int? successCount,
    int? failureCount,
    double? easeFactor,
    int? interval,
    int? repetitions,
    int? recommendedPracticeTime,
    bool? isActive,
    Map<String, dynamic>? metadata,
    SpotResult? lastResult,
    DateTime? lastResultAt,
  }) {
    return Spot(
      id: id ?? this.id,
      pieceId: pieceId ?? this.pieceId,
      title: title ?? this.title,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      pageNumber: pageNumber ?? this.pageNumber,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      priority: priority ?? this.priority,
      readinessLevel: readinessLevel ?? this.readinessLevel,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastPracticed: lastPracticed ?? this.lastPracticed,
      nextDue: nextDue ?? this.nextDue,
      practiceCount: practiceCount ?? this.practiceCount,
      successCount: successCount ?? this.successCount,
      failureCount: failureCount ?? this.failureCount,
      easeFactor: easeFactor ?? this.easeFactor,
      interval: interval ?? this.interval,
      repetitions: repetitions ?? this.repetitions,
      recommendedPracticeTime: recommendedPracticeTime ?? this._recommendedPracticeTime,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
      lastResult: lastResult ?? this.lastResult,
      lastResultAt: lastResultAt ?? this.lastResultAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pieceId': pieceId,
      'title': title,
      'description': description,
      'notes': notes,
      'pageNumber': pageNumber,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'priority': priority.name,
      'readinessLevel': readinessLevel.name,
      'color': color.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastPracticed': lastPracticed?.toIso8601String(),
      'nextDue': nextDue?.toIso8601String(),
      'practiceCount': practiceCount,
      'successCount': successCount,
      'failureCount': failureCount,
      'easeFactor': easeFactor,
      'interval': interval,
      'repetitions': repetitions,
      'recommendedPracticeTime': recommendedPracticeTime,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory Spot.fromJson(Map<String, dynamic> json) {
    return Spot(
      id: json['id'],
      pieceId: json['pieceId'],
      title: json['title'],
      description: json['description'],
      notes: json['notes'],
      pageNumber: json['pageNumber'],
      x: json['x'],
      y: json['y'],
      width: json['width'],
      height: json['height'],
      priority: SpotPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => SpotPriority.medium,
      ),
      readinessLevel: ReadinessLevel.values.firstWhere(
        (r) => r.name == json['readinessLevel'],
        orElse: () => ReadinessLevel.newSpot,
      ),
      color: SpotColor.values.firstWhere(
        (c) => c.name == json['color'],
        orElse: () => SpotColor.red,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      lastPracticed: json['lastPracticed'] != null 
          ? DateTime.parse(json['lastPracticed']) 
          : null,
      nextDue: json['nextDue'] != null 
          ? DateTime.parse(json['nextDue']) 
          : null,
      practiceCount: json['practiceCount'] ?? 0,
      successCount: json['successCount'] ?? 0,
      failureCount: json['failureCount'] ?? 0,
      easeFactor: json['easeFactor'] ?? 2.5,
      interval: json['interval'] ?? 1,
      repetitions: json['repetitions'] ?? 0,
      isActive: json['isActive'] ?? true,
      metadata: json['metadata'],
    );
  }

  /// Check if spot is due for practice
  bool get isDue {
    if (nextDue == null) return true;
    return DateTime.now().isAfter(nextDue!);
  }
  
  /// Calculate urgency score for prioritization
  double get urgencyScore {
    // Prioritize based on color priority
    double colorWeight = color.priority * 3.0;

    // Additional weights based on readiness
    double readinessWeight = switch (readinessLevel) {
      ReadinessLevel.newSpot => 3.0,
      ReadinessLevel.learning => 2.5,
      ReadinessLevel.review => 1.5,
      ReadinessLevel.mastered => 1.0,
    };

    // Overdue multiplier
    double overdueMultiplier = 1.0;
    if (nextDue != null && DateTime.now().isAfter(nextDue!)) {
      final daysPastDue = DateTime.now().difference(nextDue!).inDays;
      overdueMultiplier = 1.0 + (daysPastDue * 0.2);
    }

    return colorWeight * readinessWeight * overdueMultiplier;
  }
  
  /// Get display color for UI
  Color get displayColor => color.visualColor;

  /// Get updated color based on practice results
  SpotColor getUpdatedColorBasedOnResult(SpotResult result) {
    switch (result) {
      case SpotResult.failed:
        return SpotColor.red; // Reset to critical if failed
      case SpotResult.struggled:
        return SpotColor.yellow; // Maintain active practice status
      case SpotResult.good:
        return color == SpotColor.red ? SpotColor.yellow : SpotColor.green;
      case SpotResult.excellent:
        return SpotColor.blue; // Nearly solved
    }
  }

  @override
  String toString() {
    return 'Spot(id: $id, title: $title, priority: $priority, readiness: $readinessLevel, color: $color)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Spot && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Practice session result for SRS updates
enum SpotResult {
  failed('Failed'),
  struggled('Struggled'),
  good('Good'),
  excellent('Excellent');

  const SpotResult(this.displayName);
  final String displayName;
  
  /// Get SRS multiplier for interval calculation
  double get srsMultiplier {
    switch (this) {
      case SpotResult.failed:
        return 0.5; // Reduce interval significantly
      case SpotResult.struggled:
        return 0.8; // Reduce interval moderately
      case SpotResult.good:
        return 1.0; // Maintain interval
      case SpotResult.excellent:
        return 1.3; // Increase interval
    }
  }
}

/// History record for spot practice
class SpotHistory {
  final String id;
  final String spotId;
  final DateTime timestamp;
  final SpotResult result;
  final int practiceTimeMinutes;
  final String? notes;
  final Map<String, dynamic>? metadata;

  const SpotHistory({
    required this.id,
    required this.spotId,
    required this.timestamp,
    required this.result,
    required this.practiceTimeMinutes,
    this.notes,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'spotId': spotId,
      'timestamp': timestamp.toIso8601String(),
      'result': result.name,
      'practiceTimeMinutes': practiceTimeMinutes,
      'notes': notes,
      'metadata': metadata,
    };
  }

  factory SpotHistory.fromJson(Map<String, dynamic> json) {
    return SpotHistory(
      id: json['id'],
      spotId: json['spotId'],
      timestamp: DateTime.parse(json['timestamp']),
      result: SpotResult.values.firstWhere(
        (r) => r.name == json['result'],
        orElse: () => SpotResult.good,
      ),
      practiceTimeMinutes: json['practiceTimeMinutes'],
      notes: json['notes'],
      metadata: json['metadata'],
    );
  }
}
