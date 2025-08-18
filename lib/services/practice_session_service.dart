import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/piece.dart';
import '../models/spot.dart';
import '../models/project.dart';
import '../services/srs_service.dart';
import '../services/readiness_service.dart';

/// Practice session types for different learning goals
enum PracticeSessionType {
  smartPractice('Smart Practice'),
  criticalSpots('Critical Spots'),
  newPiece('New Piece'),
  warmup('Warmup'),
  quickReview('Quick Review'),
  performance('Performance Run'),
  interleavedMixed('Mixed Practice'),
  interleavedBlocked('Blocked Practice'),
  customSession('Custom Session');
  
  const PracticeSessionType(this.displayName);
  final String displayName;
  
  /// Get icon for session type
  IconData get icon {
    switch (this) {
      case PracticeSessionType.smartPractice:
        return Icons.psychology;
      case PracticeSessionType.criticalSpots:
        return Icons.priority_high;
      case PracticeSessionType.newPiece:
        return Icons.fiber_new;
      case PracticeSessionType.warmup:
        return Icons.wb_sunny;
      case PracticeSessionType.quickReview:
        return Icons.speed;
      case PracticeSessionType.performance:
        return Icons.play_circle;
      case PracticeSessionType.interleavedMixed:
        return Icons.shuffle;
      case PracticeSessionType.interleavedBlocked:
        return Icons.view_module;
      case PracticeSessionType.customSession:
        return Icons.tune;
    }
  }
  
  /// Get description for session type
  String get description {
    switch (this) {
      case PracticeSessionType.smartPractice:
        return 'AI-selected spots based on SRS algorithm';
      case PracticeSessionType.criticalSpots:
        return 'Focus on red (critical) spots only';
      case PracticeSessionType.newPiece:
        return 'Learn new pieces with guided introduction';
      case PracticeSessionType.warmup:
        return 'Easy spots for warming up';
      case PracticeSessionType.quickReview:
        return 'Fast review of well-learned material';
      case PracticeSessionType.performance:
        return 'Full piece run-through for concerts';
      case PracticeSessionType.interleavedMixed:
        return 'Random practice order (optimal for retention)';
      case PracticeSessionType.interleavedBlocked:
        return 'Grouped practice blocks (easier but less effective)';
      case PracticeSessionType.customSession:
        return 'Manually selected spots and pieces';
    }
  }
}

/// Practice session configuration
class PracticeSessionConfig {
  final PracticeSessionType type;
  final Duration targetDuration;
  final List<String> pieceIds;
  final List<String> projectIds;
  final List<SpotColor> spotColors;
  final List<String> tags;
  final bool includeWarmup;
  final bool includeCooldown;
  final double minSuccessRate;
  final double maxSuccessRate;
  final int? maxSpots;
  final DateTime? concertDate;
  
  const PracticeSessionConfig({
    required this.type,
    this.targetDuration = const Duration(minutes: 30),
    this.pieceIds = const [],
    this.projectIds = const [],
    this.spotColors = const [],
    this.tags = const [],
    this.includeWarmup = false,
    this.includeCooldown = false,
    this.minSuccessRate = 0.0,
    this.maxSuccessRate = 1.0,
    this.maxSpots,
    this.concertDate,
  });
  
  PracticeSessionConfig copyWith({
    PracticeSessionType? type,
    Duration? targetDuration,
    List<String>? pieceIds,
    List<String>? projectIds,
    List<SpotColor>? spotColors,
    List<String>? tags,
    bool? includeWarmup,
    bool? includeCooldown,
    double? minSuccessRate,
    double? maxSuccessRate,
    int? maxSpots,
    DateTime? concertDate,
  }) {
    return PracticeSessionConfig(
      type: type ?? this.type,
      targetDuration: targetDuration ?? this.targetDuration,
      pieceIds: pieceIds ?? this.pieceIds,
      projectIds: projectIds ?? this.projectIds,
      spotColors: spotColors ?? this.spotColors,
      tags: tags ?? this.tags,
      includeWarmup: includeWarmup ?? this.includeWarmup,
      includeCooldown: includeCooldown ?? this.includeCooldown,
      minSuccessRate: minSuccessRate ?? this.minSuccessRate,
      maxSuccessRate: maxSuccessRate ?? this.maxSuccessRate,
      maxSpots: maxSpots ?? this.maxSpots,
      concertDate: concertDate ?? this.concertDate,
    );
  }
}

/// Individual practice item in a session
class PracticeItem {
  final String id;
  final Spot spot;
  final String pieceTitle;
  final Duration recommendedTime;
  final String instructions;
  final int repetitions;
  final double urgencyScore;
  final bool isWarmup;
  final bool isCooldown;
  
  const PracticeItem({
    required this.id,
    required this.spot,
    required this.pieceTitle,
    required this.recommendedTime,
    required this.instructions,
    this.repetitions = 3,
    this.urgencyScore = 0.5,
    this.isWarmup = false,
    this.isCooldown = false,
  });
}

/// Complete practice session with optimized ordering
class PracticeSession {
  final String id;
  final PracticeSessionType type;
  final List<PracticeItem> items;
  final Duration estimatedDuration;
  final DateTime createdAt;
  final String? projectId;
  final Map<String, dynamic> metadata;
  
  const PracticeSession({
    required this.id,
    required this.type,
    required this.items,
    required this.estimatedDuration,
    required this.createdAt,
    this.projectId,
    this.metadata = const {},
  });
  
  /// Get warmup items
  List<PracticeItem> get warmupItems => 
      items.where((item) => item.isWarmup).toList();
  
  /// Get main practice items
  List<PracticeItem> get mainItems => 
      items.where((item) => !item.isWarmup && !item.isCooldown).toList();
  
  /// Get cooldown items
  List<PracticeItem> get cooldownItems => 
      items.where((item) => item.isCooldown).toList();
  
  /// Get total estimated duration
  Duration get totalDuration => Duration(
      milliseconds: items.fold(0, (sum, item) => 
          sum + item.recommendedTime.inMilliseconds));
}

/// Service for generating intelligent practice sessions
class PracticeSessionService {
  final SRSService _srsService;
  final ReadinessService _readinessService;
  
  const PracticeSessionService({
    SRSService? srsService,
    ReadinessService? readinessService,
  }) : _srsService = srsService ?? const SRSService(),
       _readinessService = readinessService ?? const ReadinessService();
  
  /// Generate optimized practice session
  Future<PracticeSession> generateSession(
    PracticeSessionConfig config,
    List<Piece> pieces,
    List<Project> projects,
  ) async {
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Filter pieces based on config
    final filteredPieces = _filterPieces(pieces, config);
    
    // Generate practice items based on session type
    final items = await _generatePracticeItems(config, filteredPieces);
    
    // Optimize ordering for learning effectiveness
    final optimizedItems = _optimizeItemOrder(items, config.type);
    
    // Calculate estimated duration
    final estimatedDuration = Duration(
      milliseconds: optimizedItems.fold(0, (sum, item) => 
          sum + item.recommendedTime.inMilliseconds),
    );
    
    return PracticeSession(
      id: sessionId,
      type: config.type,
      items: optimizedItems,
      estimatedDuration: estimatedDuration,
      createdAt: DateTime.now(),
      projectId: config.projectIds.isNotEmpty ? config.projectIds.first : null,
      metadata: {
        'targetDuration': config.targetDuration.inMinutes,
        'actualDuration': estimatedDuration.inMinutes,
        'pieceCount': filteredPieces.length,
        'spotCount': optimizedItems.length,
        'concertDate': config.concertDate?.toIso8601String(),
      },
    );
  }
  
  /// Filter pieces based on configuration
  List<Piece> _filterPieces(List<Piece> pieces, PracticeSessionConfig config) {
    var filtered = pieces;
    
    // Filter by piece IDs
    if (config.pieceIds.isNotEmpty) {
      filtered = filtered.where((p) => config.pieceIds.contains(p.id)).toList();
    }
    
    // Filter by project IDs (assuming pieces have projectId field)
    if (config.projectIds.isNotEmpty) {
      // TODO: Add projectId to Piece model or use different filtering method
    }
    
    // Filter by tags
    if (config.tags.isNotEmpty) {
      filtered = filtered.where((p) => 
          p.tags.any((tag) => config.tags.contains(tag))).toList();
    }
    
    return filtered;
  }
  
  /// Generate practice items based on session type
  Future<List<PracticeItem>> _generatePracticeItems(
    PracticeSessionConfig config,
    List<Piece> pieces,
  ) async {
    final items = <PracticeItem>[];
    
    switch (config.type) {
      case PracticeSessionType.smartPractice:
        items.addAll(await _generateSmartPracticeItems(config, pieces));
        break;
        
      case PracticeSessionType.criticalSpots:
        items.addAll(await _generateCriticalSpotItems(config, pieces));
        break;
        
      case PracticeSessionType.newPiece:
        items.addAll(await _generateNewPieceItems(config, pieces));
        break;
        
      case PracticeSessionType.warmup:
        items.addAll(await _generateWarmupItems(config, pieces));
        break;
        
      case PracticeSessionType.quickReview:
        items.addAll(await _generateQuickReviewItems(config, pieces));
        break;
        
      case PracticeSessionType.performance:
        items.addAll(await _generatePerformanceItems(config, pieces));
        break;
        
      case PracticeSessionType.interleavedMixed:
      case PracticeSessionType.interleavedBlocked:
        items.addAll(await _generateInterleavedItems(config, pieces));
        break;
        
      case PracticeSessionType.customSession:
        items.addAll(await _generateCustomItems(config, pieces));
        break;
    }
    
    // Add warmup/cooldown if requested
    if (config.includeWarmup) {
      final warmupItems = await _generateWarmupItems(
        config.copyWith(targetDuration: const Duration(minutes: 5)),
        pieces,
      );
      items.insertAll(0, warmupItems.map((item) => PracticeItem(
        id: item.id,
        spot: item.spot,
        pieceTitle: item.pieceTitle,
        recommendedTime: item.recommendedTime,
        instructions: item.instructions,
        repetitions: item.repetitions,
        urgencyScore: item.urgencyScore,
        isWarmup: true,
      )));
    }
    
    if (config.includeCooldown) {
      final cooldownItems = await _generateQuickReviewItems(
        config.copyWith(targetDuration: const Duration(minutes: 5)),
        pieces,
      );
      items.addAll(cooldownItems.map((item) => PracticeItem(
        id: item.id,
        spot: item.spot,
        pieceTitle: item.pieceTitle,
        recommendedTime: item.recommendedTime,
        instructions: 'Cooldown: ${item.instructions}',
        repetitions: 1,
        urgencyScore: item.urgencyScore,
        isCooldown: true,
      )));
    }
    
    return items;
  }
  
  /// Generate smart practice items using SRS algorithm
  Future<List<PracticeItem>> _generateSmartPracticeItems(
    PracticeSessionConfig config,
    List<Piece> pieces,
  ) async {
    final allSpots = pieces.expand((p) => p.spots.map((s) => (piece: p, spot: s))).toList();
    
    // Use SRS service to select optimal spots
    final selectedSpots = _srsService.selectSpotsForSmartPractice(
      allSpots.map((item) => item.spot).toList(),
      targetDuration: config.targetDuration,
      maxSpots: config.maxSpots,
      concertDate: config.concertDate,
    );
    
    final items = <PracticeItem>[];
    Duration totalTime = Duration.zero;
    
    for (final spot in selectedSpots) {
      if (totalTime >= config.targetDuration) break;
      
      final piece = allSpots.firstWhere((item) => item.spot.id == spot.id).piece;
      final urgencyScore = _srsService.calculateUrgencyScore(
        spot,
        concertDate: config.concertDate,
      );
      
      final item = PracticeItem(
        id: '${piece.id}_${spot.id}',
        spot: spot,
        pieceTitle: piece.title,
        recommendedTime: spot.recommendedPracticeTime,
        instructions: _generateInstructions(spot, urgencyScore),
        repetitions: _calculateRepetitions(spot, urgencyScore),
        urgencyScore: urgencyScore,
      );
      
      items.add(item);
      totalTime += item.recommendedTime;
    }
    
    return items;
  }
  
  /// Generate critical spot items (red spots only)
  Future<List<PracticeItem>> _generateCriticalSpotItems(
    PracticeSessionConfig config,
    List<Piece> pieces,
  ) async {
    final criticalSpots = pieces
        .expand((p) => p.spots
            .where((s) => s.color == SpotColor.red)
            .map((s) => (piece: p, spot: s)))
        .toList();
    
    // Sort by urgency
    criticalSpots.sort((a, b) {
      final urgencyA = _srsService.calculateUrgencyScore(a.spot, concertDate: config.concertDate);
      final urgencyB = _srsService.calculateUrgencyScore(b.spot, concertDate: config.concertDate);
      return urgencyB.compareTo(urgencyA);
    });
    
    final items = <PracticeItem>[];
    Duration totalTime = Duration.zero;
    
    for (final item in criticalSpots) {
      if (totalTime >= config.targetDuration) break;
      
      final urgencyScore = _srsService.calculateUrgencyScore(
        item.spot,
        concertDate: config.concertDate,
      );
      
      final practiceItem = PracticeItem(
        id: '${item.piece.id}_${item.spot.id}',
        spot: item.spot,
        pieceTitle: item.piece.title,
        recommendedTime: Duration(milliseconds: 
            (item.spot.recommendedPracticeTime.inMilliseconds * 1.5).round()),
        instructions: 'CRITICAL: ${_generateInstructions(item.spot, urgencyScore)}',
        repetitions: _calculateRepetitions(item.spot, urgencyScore) + 2,
        urgencyScore: urgencyScore,
      );
      
      items.add(practiceItem);
      totalTime += practiceItem.recommendedTime;
    }
    
    return items;
  }
  
  /// Generate new piece introduction items
  Future<List<PracticeItem>> _generateNewPieceItems(
    PracticeSessionConfig config,
    List<Piece> pieces,
  ) async {
    // Focus on pieces with minimal practice time
    final newPieces = pieces
        .where((p) => p.totalTimeSpent.inMinutes < 60)
        .toList();
    
    final items = <PracticeItem>[];
    
    for (final piece in newPieces) {
      // Create introduction spots if none exist
      if (piece.spots.isEmpty) {
        // TODO: Generate initial learning spots for new pieces
        continue;
      }
      
      // Select easiest spots first for new pieces
      final easySpots = piece.spots
          .where((s) => s.difficulty <= 3)
          .take(5)
          .toList();
      
      for (final spot in easySpots) {
        items.add(PracticeItem(
          id: '${piece.id}_${spot.id}',
          spot: spot,
          pieceTitle: piece.title,
          recommendedTime: Duration(minutes: 2), // Short sessions for new material
          instructions: 'New piece: Start slowly, focus on accuracy',
          repetitions: 2,
          urgencyScore: 0.3,
        ));
      }
    }
    
    return items;
  }
  
  /// Generate warmup items (easy, well-learned spots)
  Future<List<PracticeItem>> _generateWarmupItems(
    PracticeSessionConfig config,
    List<Piece> pieces,
  ) async {
    final warmupSpots = pieces
        .expand((p) => p.spots
            .where((s) => s.successRate > 0.8 && s.difficulty <= 3)
            .map((s) => (piece: p, spot: s)))
        .take(5)
        .toList();
    
    final items = <PracticeItem>[];
    
    for (final item in warmupSpots) {
      items.add(PracticeItem(
        id: '${item.piece.id}_${item.spot.id}',
        spot: item.spot,
        pieceTitle: item.piece.title,
        recommendedTime: const Duration(minutes: 1),
        instructions: 'Warmup: Play confidently at comfortable tempo',
        repetitions: 1,
        urgencyScore: 0.2,
        isWarmup: true,
      ));
    }
    
    return items;
  }
  
  /// Generate quick review items
  Future<List<PracticeItem>> _generateQuickReviewItems(
    PracticeSessionConfig config,
    List<Piece> pieces,
  ) async {
    final reviewSpots = pieces
        .expand((p) => p.spots
            .where((s) => s.successRate > 0.6)
            .map((s) => (piece: p, spot: s)))
        .take(10)
        .toList();
    
    final items = <PracticeItem>[];
    
    for (final item in reviewSpots) {
      items.add(PracticeItem(
        id: '${item.piece.id}_${item.spot.id}',
        spot: item.spot,
        pieceTitle: item.piece.title,
        recommendedTime: const Duration(seconds: 45),
        instructions: 'Quick review: Play once at performance tempo',
        repetitions: 1,
        urgencyScore: 0.4,
      ));
    }
    
    return items;
  }
  
  /// Generate performance run items (full pieces)
  Future<List<PracticeItem>> _generatePerformanceItems(
    PracticeSessionConfig config,
    List<Piece> pieces,
  ) async {
    // TODO: Implement full piece performance items
    // This would involve creating virtual "full piece" spots
    return [];
  }
  
  /// Generate interleaved practice items
  Future<List<PracticeItem>> _generateInterleavedItems(
    PracticeSessionConfig config,
    List<Piece> pieces,
  ) async {
    // Generate regular smart practice items
    final items = await _generateSmartPracticeItems(config, pieces);
    
    // Interleaving is handled in the ordering phase
    return items;
  }
  
  /// Generate custom session items
  Future<List<PracticeItem>> _generateCustomItems(
    PracticeSessionConfig config,
    List<Piece> pieces,
  ) async {
    // Filter by spot colors if specified
    var allSpots = pieces.expand((p) => p.spots.map((s) => (piece: p, spot: s))).toList();
    
    if (config.spotColors.isNotEmpty) {
      allSpots = allSpots.where((item) => 
          config.spotColors.contains(item.spot.color)).toList();
    }
    
    // Filter by success rate range
    allSpots = allSpots.where((item) =>
        item.spot.successRate >= config.minSuccessRate &&
        item.spot.successRate <= config.maxSuccessRate).toList();
    
    final items = <PracticeItem>[];
    Duration totalTime = Duration.zero;
    
    for (final item in allSpots) {
      if (totalTime >= config.targetDuration) break;
      if (config.maxSpots != null && items.length >= config.maxSpots!) break;
      
      final urgencyScore = _srsService.calculateUrgencyScore(
        item.spot,
        concertDate: config.concertDate,
      );
      
      final practiceItem = PracticeItem(
        id: '${item.piece.id}_${item.spot.id}',
        spot: item.spot,
        pieceTitle: item.piece.title,
        recommendedTime: item.spot.recommendedPracticeTime,
        instructions: _generateInstructions(item.spot, urgencyScore),
        repetitions: _calculateRepetitions(item.spot, urgencyScore),
        urgencyScore: urgencyScore,
      );
      
      items.add(practiceItem);
      totalTime += practiceItem.recommendedTime;
    }
    
    return items;
  }
  
  /// Optimize item order for learning effectiveness
  List<PracticeItem> _optimizeItemOrder(
    List<PracticeItem> items,
    PracticeSessionType type,
  ) {
    final optimized = List<PracticeItem>.from(items);
    
    switch (type) {
      case PracticeSessionType.interleavedMixed:
        // Random interleaving for optimal retention
        optimized.shuffle();
        break;
        
      case PracticeSessionType.interleavedBlocked:
        // Group by piece for blocked practice
        optimized.sort((a, b) => a.pieceTitle.compareTo(b.pieceTitle));
        break;
        
      case PracticeSessionType.criticalSpots:
        // Hardest spots first when energy is highest
        optimized.sort((a, b) => b.urgencyScore.compareTo(a.urgencyScore));
        break;
        
      case PracticeSessionType.warmup:
        // Easiest to hardest progression
        optimized.sort((a, b) => a.urgencyScore.compareTo(b.urgencyScore));
        break;
        
      default:
        // Default: moderate interleaving with urgency weighting
        optimized.sort((a, b) {
          // Primary sort by urgency, secondary by piece variety
          final urgencyDiff = b.urgencyScore.compareTo(a.urgencyScore);
          if (urgencyDiff != 0) return urgencyDiff;
          return a.pieceTitle.compareTo(b.pieceTitle);
        });
    }
    
    return optimized;
  }
  
  /// Generate practice instructions based on spot characteristics
  String _generateInstructions(Spot spot, double urgencyScore) {
    final instructions = <String>[];
    
    // Base instruction by color
    switch (spot.color) {
      case SpotColor.red:
        instructions.add('Critical spot: Focus on accuracy');
        break;
      case SpotColor.yellow:
        instructions.add('Practice spot: Work on consistency');
        break;
      case SpotColor.green:
        instructions.add('Maintenance: Keep it polished');
        break;
      case SpotColor.blue:
        instructions.add('New material: Build familiarity');
        break;
    }
    
    // Add tempo guidance
    if (spot.successRate < 0.5) {
      instructions.add('Start slowly, build tempo gradually');
    } else if (spot.successRate > 0.8) {
      instructions.add('Practice at performance tempo');
    }
    
    // Add difficulty-specific advice
    if (spot.difficulty >= 4) {
      instructions.add('Complex passage: Break into smaller sections');
    }
    
    // Add urgency note
    if (urgencyScore > 0.8) {
      instructions.add('HIGH PRIORITY');
    }
    
    return instructions.join('. ');
  }
  
  /// Calculate optimal repetitions based on spot characteristics
  int _calculateRepetitions(Spot spot, double urgencyScore) {
    int reps = 3; // Base repetitions
    
    // Adjust for success rate
    if (spot.successRate < 0.3) {
      reps = 5; // More reps for struggling spots
    } else if (spot.successRate > 0.8) {
      reps = 2; // Fewer reps for mastered spots
    }
    
    // Adjust for difficulty
    if (spot.difficulty >= 4) {
      reps += 1; // Extra rep for hard spots
    }
    
    // Adjust for urgency
    if (urgencyScore > 0.8) {
      reps += 1; // Extra rep for urgent spots
    }
    
    return math.max(1, math.min(8, reps)); // Clamp between 1-8 reps
  }
}
