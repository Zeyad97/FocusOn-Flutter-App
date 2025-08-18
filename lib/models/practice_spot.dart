/// Simplified practice spot model - matches your exact requirements
/// while remaining extensible for advanced features
class PracticeSpot {
  // Core fields as requested
  final int? id; // auto-increment primary key
  final String piece; // name of the music piece
  final int page; // page number in the PDF
  final double x; // x coordinate of the spot in the PDF
  final double y; // y coordinate of the spot in the PDF
  final double width; // width of the spot in the PDF
  final double height; // height of the spot in the PDF
  final String color; // selected color (red/yellow/green)
  final String? lastPractice; // date/time of last practice
  final int repeatCount; // how many times this spot has been practiced
  final int readiness; // readiness score (0-100)

  // Extended fields for better functionality (optional)
  final String? title; // optional title for the spot
  final String? description; // optional description
  final String? notes; // user notes
  final String priority; // priority level (low/medium/high)
  final String createdAt; // when the spot was created
  final String updatedAt; // when the spot was last updated
  final bool isActive; // whether the spot is active
  
  // SRS fields (for advanced spaced repetition - can be ignored for basic usage)
  final String? nextDue; // when the spot is next due for practice
  final double easeFactor; // SRS ease factor
  final int intervalDays; // SRS interval in days
  final int repetitions; // SRS repetition count
  
  // Future sync support
  final String syncStatus; // local/syncing/synced
  final String? lastSynced; // last sync timestamp
  final String? cloudId; // cloud database ID

  const PracticeSpot({
    this.id,
    required this.piece,
    required this.page,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.color,
    this.lastPractice,
    this.repeatCount = 0,
    this.readiness = 0,
    this.title,
    this.description,
    this.notes,
    this.priority = 'medium',
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.nextDue,
    this.easeFactor = 2.5,
    this.intervalDays = 1,
    this.repetitions = 0,
    this.syncStatus = 'local',
    this.lastSynced,
    this.cloudId,
  });

  /// Create a practice spot with minimal required fields
  factory PracticeSpot.create({
    required String piece,
    required int page,
    required double x,
    required double y,
    required double width,
    required double height,
    required String color,
    String? title,
    String? description,
    String priority = 'medium',
  }) {
    final now = DateTime.now().toIso8601String();
    return PracticeSpot(
      piece: piece,
      page: page,
      x: x,
      y: y,
      width: width,
      height: height,
      color: color,
      title: title,
      description: description,
      priority: priority,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create a copy with updated fields
  PracticeSpot copyWith({
    int? id,
    String? piece,
    int? page,
    double? x,
    double? y,
    double? width,
    double? height,
    String? color,
    String? lastPractice,
    int? repeatCount,
    int? readiness,
    String? title,
    String? description,
    String? notes,
    String? priority,
    String? createdAt,
    String? updatedAt,
    bool? isActive,
    String? nextDue,
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
    String? syncStatus,
    String? lastSynced,
    String? cloudId,
  }) {
    return PracticeSpot(
      id: id ?? this.id,
      piece: piece ?? this.piece,
      page: page ?? this.page,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      color: color ?? this.color,
      lastPractice: lastPractice ?? this.lastPractice,
      repeatCount: repeatCount ?? this.repeatCount,
      readiness: readiness ?? this.readiness,
      title: title ?? this.title,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      nextDue: nextDue ?? this.nextDue,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSynced: lastSynced ?? this.lastSynced,
      cloudId: cloudId ?? this.cloudId,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'piece': piece,
      'page': page,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'color': color,
      'last_practice': lastPractice,
      'repeat_count': repeatCount,
      'readiness': readiness,
      'title': title,
      'description': description,
      'notes': notes,
      'priority': priority,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_active': isActive ? 1 : 0,
      'next_due': nextDue,
      'ease_factor': easeFactor,
      'interval_days': intervalDays,
      'repetitions': repetitions,
      'sync_status': syncStatus,
      'last_synced': lastSynced,
      'cloud_id': cloudId,
    };
  }

  /// Create from database map
  factory PracticeSpot.fromMap(Map<String, dynamic> map) {
    return PracticeSpot(
      id: map['id'],
      piece: map['piece'],
      page: map['page'],
      x: map['x'].toDouble(),
      y: map['y'].toDouble(),
      width: map['width'].toDouble(),
      height: map['height'].toDouble(),
      color: map['color'],
      lastPractice: map['last_practice'],
      repeatCount: map['repeat_count'] ?? 0,
      readiness: map['readiness'] ?? 0,
      title: map['title'],
      description: map['description'],
      notes: map['notes'],
      priority: map['priority'] ?? 'medium',
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      isActive: map['is_active'] == 1,
      nextDue: map['next_due'],
      easeFactor: map['ease_factor']?.toDouble() ?? 2.5,
      intervalDays: map['interval_days'] ?? 1,
      repetitions: map['repetitions'] ?? 0,
      syncStatus: map['sync_status'] ?? 'local',
      lastSynced: map['last_synced'],
      cloudId: map['cloud_id'],
    );
  }

  /// Convert to JSON (for API/cloud sync)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'piece': piece,
      'page': page,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'color': color,
      'lastPractice': lastPractice,
      'repeatCount': repeatCount,
      'readiness': readiness,
      'title': title,
      'description': description,
      'notes': notes,
      'priority': priority,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
      'nextDue': nextDue,
      'easeFactor': easeFactor,
      'intervalDays': intervalDays,
      'repetitions': repetitions,
      'syncStatus': syncStatus,
      'lastSynced': lastSynced,
      'cloudId': cloudId,
    };
  }

  /// Create from JSON (for API/cloud sync)
  factory PracticeSpot.fromJson(Map<String, dynamic> json) {
    return PracticeSpot(
      id: json['id'],
      piece: json['piece'],
      page: json['page'],
      x: json['x'].toDouble(),
      y: json['y'].toDouble(),
      width: json['width'].toDouble(),
      height: json['height'].toDouble(),
      color: json['color'],
      lastPractice: json['lastPractice'],
      repeatCount: json['repeatCount'] ?? 0,
      readiness: json['readiness'] ?? 0,
      title: json['title'],
      description: json['description'],
      notes: json['notes'],
      priority: json['priority'] ?? 'medium',
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      isActive: json['isActive'] ?? true,
      nextDue: json['nextDue'],
      easeFactor: json['easeFactor']?.toDouble() ?? 2.5,
      intervalDays: json['intervalDays'] ?? 1,
      repetitions: json['repetitions'] ?? 0,
      syncStatus: json['syncStatus'] ?? 'local',
      lastSynced: json['lastSynced'],
      cloudId: json['cloudId'],
    );
  }

  /// Check if spot is due for practice
  bool get isDue {
    if (nextDue == null) return true;
    return DateTime.now().isAfter(DateTime.parse(nextDue!));
  }

  /// Get urgency score for prioritization
  double get urgencyScore {
    double priorityWeight = switch (priority.toLowerCase()) {
      'high' => 3.0,
      'medium' => 2.0,
      'low' => 1.0,
      _ => 2.0,
    };

    // Lower readiness = higher urgency
    double readinessWeight = (100 - readiness) / 100.0;

    double overdueMultiplier = 1.0;
    if (nextDue != null) {
      final due = DateTime.parse(nextDue!);
      if (DateTime.now().isAfter(due)) {
        final daysPastDue = DateTime.now().difference(due).inDays;
        overdueMultiplier = 1.0 + (daysPastDue * 0.1);
      }
    }

    return priorityWeight * (1.0 + readinessWeight) * overdueMultiplier;
  }

  /// Get display information
  String get displayTitle => title ?? 'Spot ${id ?? 'New'}';
  String get displayColor => color.toLowerCase();
  
  /// Practice spot colors
  static const List<String> availableColors = ['red', 'yellow', 'green'];
  static const List<String> availablePriorities = ['low', 'medium', 'high'];

  @override
  String toString() {
    return 'PracticeSpot(id: $id, piece: $piece, page: $page, color: $color, readiness: $readiness)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PracticeSpot && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
