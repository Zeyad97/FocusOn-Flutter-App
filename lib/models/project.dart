import 'piece.dart';
import 'spot.dart';

/// A project/setlist containing multiple pieces for a performance or goal
class Project {
  final String id;
  final String name;
  final String? description;
  final DateTime? concertDate;
  final List<String> pieceIds; // References to pieces
  final Duration dailyPracticeGoal;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const Project({
    required this.id,
    required this.name,
    this.description,
    this.concertDate,
    required this.pieceIds,
    this.dailyPracticeGoal = const Duration(minutes: 30),
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  /// Check if project has upcoming concert deadline
  bool get hasUpcomingConcert {
    if (concertDate == null) return false;
    final daysUntilConcert = concertDate!.difference(DateTime.now()).inDays;
    return daysUntilConcert <= 30 && daysUntilConcert >= 0;
  }

  /// Days until concert (null if no concert date)
  int? get daysUntilConcert {
    if (concertDate == null) return null;
    return concertDate!.difference(DateTime.now()).inDays;
  }

  /// Get urgency level for the entire project
  ProjectUrgency get urgency {
    final days = daysUntilConcert;
    if (days == null) return ProjectUrgency.none;
    
    if (days <= 3) return ProjectUrgency.critical;
    if (days <= 7) return ProjectUrgency.high;
    if (days <= 14) return ProjectUrgency.medium;
    if (days <= 30) return ProjectUrgency.low;
    return ProjectUrgency.none;
  }

  /// Calculate overall readiness based on pieces (requires pieces list)
  double calculateReadiness(List<Piece> pieces) {
    final projectPieces = pieces.where((p) => pieceIds.contains(p.id)).toList();
    if (projectPieces.isEmpty) return 0.0;
    
    final totalReadiness = projectPieces.fold<double>(
        0.0, 
        (sum, piece) => sum + piece.readinessPercentage
    );
    // Convert from percentage (0-100) to decimal (0.0-1.0) for progress bar
    return (totalReadiness / projectPieces.length) / 100.0;
  }

  /// Get total spots across all pieces
  int getTotalSpots(List<Piece> pieces) {
    final projectPieces = pieces.where((p) => pieceIds.contains(p.id)).toList();
    return projectPieces.fold<int>(0, (sum, piece) => sum + piece.spots.length);
  }

  /// Get spots due today across all pieces
  List<Spot> getSpotsDueToday(List<Piece> pieces) {
    final projectPieces = pieces.where((p) => pieceIds.contains(p.id)).toList();
    final allSpots = <Spot>[];
    
    for (final piece in projectPieces) {
      allSpots.addAll(piece.spotsDueToday);
    }
    
    return allSpots;
  }

  /// Get critical spots across all pieces
  List<Spot> getCriticalSpots(List<Piece> pieces) {
    final projectPieces = pieces.where((p) => pieceIds.contains(p.id)).toList();
    final criticalSpots = <Spot>[];
    
    for (final piece in projectPieces) {
      criticalSpots.addAll(piece.criticalSpots);
    }
    
    return criticalSpots;
  }

  /// Estimate total practice time needed based on current spot status
  Duration estimateRemainingPracticeTime(List<Piece> pieces) {
    final projectPieces = pieces.where((p) => pieceIds.contains(p.id)).toList();
    Duration totalTime = Duration.zero;
    
    for (final piece in projectPieces) {
      for (final spot in piece.spots) {
        if (spot.color != SpotColor.green) {
          totalTime += Duration(minutes: spot.recommendedPracticeTime);
        }
      }
    }
    
    return totalTime;
  }

  /// Check if daily practice goal is achievable given concert timeline
  bool isDailyGoalRealistic(List<Piece> pieces) {
    final days = daysUntilConcert;
    if (days == null || days <= 0) return true;
    
    final totalPracticeNeeded = estimateRemainingPracticeTime(pieces);
    final availablePracticeTime = Duration(
        milliseconds: (dailyPracticeGoal.inMilliseconds * days).round()
    );
    
    return totalPracticeNeeded <= availablePracticeTime;
  }

  /// Create copy with updated fields
  Project copyWith({
    String? name,
    String? description,
    DateTime? concertDate,
    List<String>? pieceIds,
    Duration? dailyPracticeGoal,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      concertDate: concertDate ?? this.concertDate,
      pieceIds: pieceIds ?? this.pieceIds,
      dailyPracticeGoal: dailyPracticeGoal ?? this.dailyPracticeGoal,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'concert_date': concertDate?.millisecondsSinceEpoch,
      'piece_ids': pieceIds.join(','),
      'daily_practice_goal': dailyPracticeGoal.inMilliseconds,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      concertDate: json['concert_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['concert_date'])
          : null,
      pieceIds: json['piece_ids']?.split(',') ?? <String>[],
      dailyPracticeGoal: Duration(milliseconds: json['daily_practice_goal'] ?? 1800000), // 30 min default
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at']),
      metadata: json['metadata']?.cast<String, dynamic>(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Project && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Project(id: $id, name: $name, pieces: ${pieceIds.length}, '
           'concert: $concertDate)';
  }
}

/// Urgency level for project deadlines
enum ProjectUrgency {
  none,     // No deadline or far future
  low,      // 2-4 weeks away
  medium,   // 1-2 weeks away
  high,     // 3-7 days away
  critical, // 1-3 days away
}

extension ProjectUrgencyExtension on ProjectUrgency {
  String get displayName {
    switch (this) {
      case ProjectUrgency.none:
        return 'No Deadline';
      case ProjectUrgency.low:
        return 'Low Priority';
      case ProjectUrgency.medium:
        return 'Medium Priority';
      case ProjectUrgency.high:
        return 'High Priority';
      case ProjectUrgency.critical:
        return 'Critical';
    }
  }

  /// Get color for UI display
  String get colorCode {
    switch (this) {
      case ProjectUrgency.none:
        return '#6B7280';     // Gray
      case ProjectUrgency.low:
        return '#10B981';     // Green
      case ProjectUrgency.medium:
        return '#F59E0B';     // Yellow
      case ProjectUrgency.high:
        return '#F97316';     // Orange
      case ProjectUrgency.critical:
        return '#EF4444';     // Red
    }
  }

  /// Get priority weight for scheduling (higher = more urgent)
  double get priorityWeight {
    switch (this) {
      case ProjectUrgency.none:
        return 0.1;
      case ProjectUrgency.low:
        return 0.3;
      case ProjectUrgency.medium:
        return 0.5;
      case ProjectUrgency.high:
        return 0.8;
      case ProjectUrgency.critical:
        return 1.0;
    }
  }
}
