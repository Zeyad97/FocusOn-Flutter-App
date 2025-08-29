import 'spot.dart';

/// Status of a practice session
enum SessionStatus {
  planned,    // Session created but not started
  active,     // Currently in progress
  paused,     // Temporarily paused
  completed,  // Successfully finished
  cancelled,  // Stopped before completion
}

extension SessionStatusExtension on SessionStatus {
  String get displayName {
    switch (this) {
      case SessionStatus.planned:
        return 'Planned';
      case SessionStatus.active:
        return 'Active';
      case SessionStatus.paused:
        return 'Paused';
      case SessionStatus.completed:
        return 'Completed';
      case SessionStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get name {
    switch (this) {
      case SessionStatus.planned:
        return 'planned';
      case SessionStatus.active:
        return 'active';
      case SessionStatus.paused:
        return 'paused';
      case SessionStatus.completed:
        return 'completed';
      case SessionStatus.cancelled:
        return 'cancelled';
    }
  }

  static SessionStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'planned':
        return SessionStatus.planned;
      case 'active':
        return SessionStatus.active;
      case 'paused':
        return SessionStatus.paused;
      case 'completed':
        return SessionStatus.completed;
      case 'cancelled':
        return SessionStatus.cancelled;
      default:
        throw ArgumentError('Invalid session status: $value');
    }
  }
}

/// Type of practice session
enum SessionType {
  smart,      // AI-selected spots based on urgency
  custom,     // User-selected spots
  critical,   // Red spots only
  balanced,   // Mix of red and yellow spots
  maintenance, // Green spots only
  warmup,     // Short 5-10 minute session
}

extension SessionTypeExtension on SessionType {
  String get displayName {
    switch (this) {
      case SessionType.smart:
        return 'Smart Practice';
      case SessionType.custom:
        return 'Custom Selection';
      case SessionType.critical:
        return 'Critical Focus';
      case SessionType.balanced:
        return 'Balanced Practice';
      case SessionType.maintenance:
        return 'Maintenance Session';
      case SessionType.warmup:
        return 'Quick Warmup';
    }
  }

  String get description {
    switch (this) {
      case SessionType.smart:
        return 'AI selects the most urgent spots';
      case SessionType.custom:
        return 'Practice your chosen spots';
      case SessionType.critical:
        return 'Focus on struggling areas only';
      case SessionType.balanced:
        return 'Mix of critical and practice spots';
      case SessionType.maintenance:
        return 'Review confident areas';
      case SessionType.warmup:
        return 'Short 5-10 minute session';
    }
  }

  static SessionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'smart':
        return SessionType.smart;
      case 'custom':
        return SessionType.custom;
      case 'critical':
        return SessionType.critical;
      case 'balanced':
        return SessionType.balanced;
      case 'maintenance':
        return SessionType.maintenance;
      case 'warmup':
        return SessionType.warmup;
      case 'sight reading':
        return SessionType.smart; // Default mapping
      case 'technique':
        return SessionType.critical;
      case 'repertoire':
        return SessionType.balanced;
      default:
        return SessionType.smart;
    }
  }
}

/// A planned or completed practice session
class PracticeSession {
  final String id;
  final String name;
  final SessionType type;
  final SessionStatus status;
  final DateTime? startTime;
  final DateTime? endTime;
  final Duration plannedDuration;
  final List<SpotSession> spotSessions;
  final bool microBreaksEnabled;
  final Duration microBreakInterval;
  final Duration microBreakDuration;
  final int breaksTaken;
  final String? projectId;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PracticeSession({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    this.startTime,
    this.endTime,
    required this.plannedDuration,
    required this.spotSessions,
    this.microBreaksEnabled = true,
    this.microBreakInterval = const Duration(minutes: 30),
    this.microBreakDuration = const Duration(minutes: 5),
    this.breaksTaken = 0,
    this.projectId,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get actual session duration (if completed)
  Duration? get actualDuration {
    if (startTime == null || endTime == null) return null;
    return endTime!.difference(startTime!);
  }

  /// Get total time spent on spots (excluding breaks)
  Duration get totalSpotTime {
    return spotSessions.fold<Duration>(
      Duration.zero,
      (sum, spotSession) => sum + (spotSession.actualDuration ?? Duration.zero),
    );
  }

  /// Get completion percentage (0.0-1.0)
  double get completionPercentage {
    if (spotSessions.isEmpty) return 0.0;
    
    final completedSpots = spotSessions.where((s) => s.isCompleted).length;
    return completedSpots / spotSessions.length;
  }

  /// Get success rate for completed spots (0.0-1.0)
  double get successRate {
    final completedSpots = spotSessions.where((s) => s.isCompleted).toList();
    if (completedSpots.isEmpty) return 0.0;
    
    final successfulSpots = completedSpots.where((s) => 
        s.result == SpotResult.good || s.result == SpotResult.excellent).length;
    return successfulSpots / completedSpots.length;
  }

  /// Get current spot being practiced (if session is active)
  SpotSession? get currentSpot {
    if (status != SessionStatus.active) return null;
    return spotSessions.firstWhere(
      (s) => s.status == SpotSessionStatus.active,
      orElse: () => spotSessions.firstWhere(
        (s) => s.status == SpotSessionStatus.pending,
        orElse: () => throw StateError('No active or pending spots'),
      ),
    );
  }

  /// Get next spot to practice
  SpotSession? get nextSpot {
    final pendingSpots = spotSessions.where((s) => 
        s.status == SpotSessionStatus.pending).toList();
    return pendingSpots.isNotEmpty ? pendingSpots.first : null;
  }

  /// Check if session is in progress
  bool get isInProgress => status == SessionStatus.active || 
                          status == SessionStatus.paused;

  /// Check if session can be started
  bool get canStart => status == SessionStatus.planned && 
                      spotSessions.isNotEmpty;

  /// Check if session can be resumed
  bool get canResume => status == SessionStatus.paused;

  /// Create copy with updated fields
  PracticeSession copyWith({
    String? name,
    SessionStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    Duration? plannedDuration,
    List<SpotSession>? spotSessions,
    bool? microBreaksEnabled,
    Duration? microBreakInterval,
    Duration? microBreakDuration,
    int? breaksTaken,
    String? projectId,
    Map<String, dynamic>? metadata,
    DateTime? updatedAt,
  }) {
    return PracticeSession(
      id: id,
      name: name ?? this.name,
      type: type,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      plannedDuration: plannedDuration ?? this.plannedDuration,
      spotSessions: spotSessions ?? this.spotSessions,
      microBreaksEnabled: microBreaksEnabled ?? this.microBreaksEnabled,
      microBreakInterval: microBreakInterval ?? this.microBreakInterval,
      microBreakDuration: microBreakDuration ?? this.microBreakDuration,
      breaksTaken: breaksTaken ?? this.breaksTaken,
      projectId: projectId ?? this.projectId,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'status': status.name,
      'start_time': startTime?.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'planned_duration': plannedDuration.inMilliseconds,
      'micro_breaks_enabled': microBreaksEnabled ? 1 : 0,
      'micro_break_interval': microBreakInterval.inMilliseconds,
      'micro_break_duration': microBreakDuration.inMilliseconds,
      'breaks_taken': breaksTaken,
      'project_id': projectId,
      'metadata': metadata,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Create from JSON
  factory PracticeSession.fromJson(Map<String, dynamic> json) {
    return PracticeSession(
      id: json['id'],
      name: json['name'],
      type: SessionTypeExtension.fromString(json['type']),
      status: SessionStatusExtension.fromString(json['status']),
      startTime: json['start_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['start_time'])
          : null,
      endTime: json['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['end_time'])
          : null,
      plannedDuration: Duration(milliseconds: json['planned_duration']),
      spotSessions: [], // Loaded separately for performance
      microBreaksEnabled: json['micro_breaks_enabled'] == 1,
      microBreakInterval: Duration(milliseconds: json['micro_break_interval']),
      microBreakDuration: Duration(milliseconds: json['micro_break_duration']),
      breaksTaken: json['breaks_taken'] ?? 0,
      projectId: json['project_id'],
      metadata: json['metadata']?.cast<String, dynamic>(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at']),
    );
  }

  @override
  String toString() {
    return 'PracticeSession(id: $id, name: $name, type: ${type.displayName}, '
           'status: ${status.displayName}, spots: ${spotSessions.length})';
  }
}

/// Status of practicing an individual spot within a session
enum SpotSessionStatus {
  pending,    // Not yet started
  active,     // Currently being practiced
  completed,  // Finished practicing
  skipped,    // Skipped this spot
}

/// Individual spot practice within a session
class SpotSession {
  final String id;
  final String sessionId;
  final String spotId;
  final int orderIndex; // Order within the session
  final Duration allocatedTime;
  final SpotSessionStatus status;
  final DateTime? startTime;
  final DateTime? endTime;
  final SpotResult? result;
  final String? notes;
  final Map<String, dynamic>? metadata;

  const SpotSession({
    required this.id,
    required this.sessionId,
    required this.spotId,
    required this.orderIndex,
    required this.allocatedTime,
    required this.status,
    this.startTime,
    this.endTime,
    this.result,
    this.notes,
    this.metadata,
  });

  /// Get actual time spent on this spot
  Duration? get actualDuration {
    if (startTime == null || endTime == null) return null;
    return endTime!.difference(startTime!);
  }

  /// Check if spot practice is completed
  bool get isCompleted => status == SpotSessionStatus.completed;

  /// Check if spot practice is active
  bool get isActive => status == SpotSessionStatus.active;

  /// Check if this spot can be started
  bool get canStart => status == SpotSessionStatus.pending;

  /// Create copy with updated fields
  SpotSession copyWith({
    SpotSessionStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    SpotResult? result,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return SpotSession(
      id: id,
      sessionId: sessionId,
      spotId: spotId,
      orderIndex: orderIndex,
      allocatedTime: allocatedTime,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      result: result ?? this.result,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'spot_id': spotId,
      'order_index': orderIndex,
      'allocated_time': allocatedTime.inMilliseconds,
      'status': status.name,
      'start_time': startTime?.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'result': result?.name,
      'notes': notes,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory SpotSession.fromJson(Map<String, dynamic> json) {
    return SpotSession(
      id: json['id'],
      sessionId: json['session_id'],
      spotId: json['spot_id'],
      orderIndex: json['order_index'],
      allocatedTime: Duration(milliseconds: json['allocated_time']),
      status: SpotSessionStatusExtension.fromString(json['status']),
      startTime: json['start_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['start_time'])
          : null,
      endTime: json['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['end_time'])
          : null,
      result: json['result'] != null 
          ? SpotResultExtension.fromString(json['result'])
          : null,
      notes: json['notes'],
      metadata: json['metadata']?.cast<String, dynamic>(),
    );
  }

  @override
  String toString() {
    return 'SpotSession(spotId: $spotId, status: ${status.name}, '
           'allocated: $allocatedTime)';
  }
}

extension SpotSessionStatusExtension on SpotSessionStatus {
  String get name {
    switch (this) {
      case SpotSessionStatus.pending:
        return 'pending';
      case SpotSessionStatus.active:
        return 'active';
      case SpotSessionStatus.completed:
        return 'completed';
      case SpotSessionStatus.skipped:
        return 'skipped';
    }
  }

  static SpotSessionStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return SpotSessionStatus.pending;
      case 'active':
        return SpotSessionStatus.active;
      case 'completed':
        return SpotSessionStatus.completed;
      case 'skipped':
        return SpotSessionStatus.skipped;
      default:
        throw ArgumentError('Invalid spot session status: $value');
    }
  }
}

extension SpotResultExtension on SpotResult {
  String get name {
    switch (this) {
      case SpotResult.failed:
        return 'failed';
      case SpotResult.struggled:
        return 'struggled';
      case SpotResult.good:
        return 'good';
      case SpotResult.excellent:
        return 'excellent';
    }
  }

  static SpotResult fromString(String value) {
    switch (value.toLowerCase()) {
      case 'failed':
        return SpotResult.failed;
      case 'struggled':
        return SpotResult.struggled;
      case 'good':
        return SpotResult.good;
      case 'excellent':
        return SpotResult.excellent;
      default:
        throw ArgumentError('Invalid spot result: $value');
    }
  }
}
