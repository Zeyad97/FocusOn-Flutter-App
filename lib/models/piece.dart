import 'dart:io';
import 'package:collection/collection.dart';
import 'spot.dart';

/// Core data model representing a musical piece/sheet music - ScoreRead Pro
class Piece {
  final String id;
  final String title;
  final String composer;
  final String? keySignature;
  final int difficulty; // 1-5 stars
  final List<String> tags; // Tags for categorization
  final DateTime? concertDate;
  final DateTime? lastOpened;
  final int? lastViewedPage;
  final double? lastZoom; // PDF zoom level
  final String? viewMode; // single, two-page, vertical, half-page
  final String pdfFilePath;
  final List<Spot> spots;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? projectId;
  final Map<String, dynamic>? metadata;
  final Duration totalTimeSpent; // Time tracking
  final String? thumbnailPath; // PDF thumbnail
  final int totalPages; // PDF page count
  final double? targetTempo; // Optional tempo target for readiness
  final double? currentTempo; // Current achieved tempo

  const Piece({
    required this.id,
    required this.title,
    required this.composer,
    this.keySignature,
    required this.difficulty,
    this.tags = const [],
    this.concertDate,
    this.lastOpened,
    this.lastViewedPage,
    this.lastZoom,
    this.viewMode,
    required this.pdfFilePath,
    required this.spots,
    required this.createdAt,
    required this.updatedAt,
    this.projectId,
    this.metadata,
    this.totalTimeSpent = Duration.zero,
    this.thumbnailPath,
    this.totalPages = 0,
    this.targetTempo,
    this.currentTempo,
  });

  /// Get PDF file handle
  File get pdfFile => File(pdfFilePath);

  /// Check if PDF file exists
  bool get pdfExists => pdfFile.existsSync();

  /// Get spots grouped by color/urgency
  Map<SpotColor, List<Spot>> get spotsByColor => 
      spots.groupListsBy((spot) => spot.color);

  /// Get spots due today
  List<Spot> get spotsDueToday {
    final today = DateTime.now();
    return spots.where((spot) => 
        spot.nextDue?.isBefore(today.add(const Duration(days: 1))) ?? false
    ).toList();
  }

  /// Get critical spots (red spots)
  List<Spot> get criticalSpots => 
      spots.where((spot) => spot.color == SpotColor.red).toList();

  /// Get practice spots (yellow spots)  
  List<Spot> get practiceSpots => 
      spots.where((spot) => spot.color == SpotColor.yellow).toList();

  /// Get maintenance spots (green spots)
  List<Spot> get maintenanceSpots => 
      spots.where((spot) => spot.color == SpotColor.green).toList();

  /// Calculate overall readiness percentage (0-100)
  double get readinessPercentage {
    if (spots.isEmpty) return 100.0;
    
    final greenCount = maintenanceSpots.length;
    return (greenCount / spots.length) * 100;
  }

  /// Get urgency score for smart practice selection (0.0-1.0)
  double get urgencyScore {
    if (spots.isEmpty) return 0.0;
    
    final criticalCount = criticalSpots.length;
    final practiceCount = practiceSpots.length;
    final overduePenalty = _calculateOverduePenalty();
    final concertPressure = _calculateConcertPressure();
    
    return ((criticalCount * 0.8 + practiceCount * 0.5) / spots.length) + 
           overduePenalty + concertPressure;
  }

  /// Check if piece has upcoming concert deadline
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

  double _calculateOverduePenalty() {
    final now = DateTime.now();
    final overdueSpots = spots.where((spot) => spot.nextDue?.isBefore(now) ?? false);
    if (overdueSpots.isEmpty) return 0.0;
    
    return (overdueSpots.length / spots.length) * 0.3;
  }

  double _calculateConcertPressure() {
    if (concertDate == null) return 0.0;
    
    final daysUntil = daysUntilConcert;
    if (daysUntil == null || daysUntil < 0) return 0.0;
    
    // Exponential pressure as concert approaches
    if (daysUntil <= 7) return 0.5;
    if (daysUntil <= 14) return 0.3;
    if (daysUntil <= 30) return 0.2;
    return 0.0;
  }

  /// Create copy with updated fields
  Piece copyWith({
    String? title,
    String? composer,
    String? keySignature,
    int? difficulty,
    DateTime? concertDate,
    DateTime? lastOpened,
    int? lastViewedPage,
    String? pdfFilePath,
    List<Spot>? spots,
    DateTime? updatedAt,
    String? projectId,
    Map<String, dynamic>? metadata,
  }) {
    return Piece(
      id: id,
      title: title ?? this.title,
      composer: composer ?? this.composer,
      keySignature: keySignature ?? this.keySignature,
      difficulty: difficulty ?? this.difficulty,
      concertDate: concertDate ?? this.concertDate,
      lastOpened: lastOpened ?? this.lastOpened,
      lastViewedPage: lastViewedPage ?? this.lastViewedPage,
      pdfFilePath: pdfFilePath ?? this.pdfFilePath,
      spots: spots ?? this.spots,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      projectId: projectId ?? this.projectId,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'composer': composer,
      'key_signature': keySignature,
      'difficulty': difficulty,
      'concert_date': concertDate?.millisecondsSinceEpoch,
      'last_opened': lastOpened?.millisecondsSinceEpoch,
      'pdf_file_path': pdfFilePath,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'project_id': projectId,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory Piece.fromJson(Map<String, dynamic> json) {
    return Piece(
      id: json['id'],
      title: json['title'],
      composer: json['composer'],
      keySignature: json['key_signature'],
      difficulty: json['difficulty'],
      concertDate: json['concert_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['concert_date'])
          : null,
      lastOpened: json['last_opened'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['last_opened'])
          : null,
      pdfFilePath: json['pdf_file_path'],
      spots: [], // Spots loaded separately for performance
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at']),
      projectId: json['project_id'],
      metadata: json['metadata']?.cast<String, dynamic>(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Piece && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Piece(id: $id, title: $title, composer: $composer, '
           'difficulty: $difficulty, spots: ${spots.length})';
  }
}
