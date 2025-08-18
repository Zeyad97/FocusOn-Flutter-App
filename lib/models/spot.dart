import 'package:flutter/material.dart';

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
  red('Red'),
  yellow('Yellow'), 
  green('Green'),
  blue('Blue');

  const SpotColor(this.displayName);
  final String displayName;
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
  final int recommendedPracticeTime; // in minutes
  final bool isActive;
  final Map<String, dynamic>? metadata;
  // ScoreRead Pro SRS enhancements
  final int progressIndex; // SRS progress counter (0+)
  final double? lastGapDays; // Last gap between reviews
  final bool manualOverride; // Manual reschedule flag
  final bool retryToday; // Same-day retry flag
  final String? lastResult; // 'pass' | 'fail' | null
  final DateTime? lastResultAt; // When last result was recorded
  final List<SpotHistory> history; // Practice history

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
    this.recommendedPracticeTime = 5,
    this.isActive = true,
    this.metadata,
    this.progressIndex = 0,
    this.lastGapDays,
    this.manualOverride = false,
    this.retryToday = false,
    this.lastResult,
    this.lastResultAt,
    this.history = const [],
  });

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
      recommendedPracticeTime: recommendedPracticeTime ?? this.recommendedPracticeTime,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
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
      recommendedPracticeTime: json['recommendedPracticeTime'] ?? 5,
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
    double priorityWeight = switch (priority) {
      SpotPriority.high => 3.0,
      SpotPriority.medium => 2.0,
      SpotPriority.low => 1.0,
    };

    double readinessWeight = switch (readinessLevel) {
      ReadinessLevel.newSpot => 3.0,
      ReadinessLevel.learning => 2.5,
      ReadinessLevel.review => 1.5,
      ReadinessLevel.mastered => 1.0,
    };

    double overdueMultiplier = 1.0;
    if (nextDue != null && DateTime.now().isAfter(nextDue!)) {
      final daysPastDue = DateTime.now().difference(nextDue!).inDays;
      overdueMultiplier = 1.0 + (daysPastDue * 0.1);
    }

    return priorityWeight * readinessWeight * overdueMultiplier;
  }

  /// Get display color for UI
  Color get displayColor {
    return switch (color) {
      SpotColor.red => Colors.red,
      SpotColor.yellow => Colors.orange,
      SpotColor.green => Colors.green,
      SpotColor.blue => Colors.blue,
    };
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
