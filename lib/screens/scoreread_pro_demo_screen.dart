import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/piece.dart';
import '../models/spot.dart';
import '../models/annotation.dart';
import '../models/project.dart';
import '../services/srs_service.dart';
import '../services/readiness_service.dart' as readiness_service;
import '../services/practice_session_service.dart';
import '../services/time_tracking_service.dart';
import '../theme/app_theme.dart';

/// Comprehensive demo screen showcasing ScoreRead Pro features
class ScoreReadProDemoScreen extends ConsumerStatefulWidget {
  const ScoreReadProDemoScreen({super.key});

  @override
  ConsumerState<ScoreReadProDemoScreen> createState() => _ScoreReadProDemoScreenState();
}

class _ScoreReadProDemoScreenState extends ConsumerState<ScoreReadProDemoScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Demo data
  late List<Piece> _demoPieces;
  late List<Annotation> _demoAnnotations;
  late Project _demoProject;
  
  // Services
  final _srsService = const SRSService();
  final _readinessService = const readiness_service.ReadinessService();
  final _practiceService = const PracticeSessionService();
  final _timeService = TimeTrackingService();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _initializeDemoData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _initializeDemoData() {
    // Create demo pieces with ScoreRead Pro features
    _demoPieces = [
      Piece(
        id: 'demo_piece_1',
        title: 'Chopin Nocturne Op. 9 No. 2',
        composer: 'Frédéric Chopin',
        pdfFilePath: 'assets/demo_chopin.pdf',
        difficulty: 4,
        keySignature: 'E♭ major',
        genre: 'Romantic',
        duration: 5, // minutes
        totalTimeSpent: const Duration(hours: 8, minutes: 30),
        targetTempo: 120,
        currentTempo: 108,
        spots: _createDemoSpots('demo_piece_1'),
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        lastOpened: DateTime.now().subtract(const Duration(hours: 2)),
        lastViewedPage: 2,
      ),
      Piece(
        id: 'demo_piece_2',
        title: 'Bach Invention No. 1 in C major',
        composer: 'Johann Sebastian Bach',
        pdfFilePath: 'assets/demo_bach.pdf',
        difficulty: 3,
        keySignature: 'C major',
        genre: 'Baroque',
        duration: 2, // minutes
        totalTimeSpent: const Duration(hours: 12, minutes: 15),
        targetTempo: 120,
        currentTempo: 118,
        spots: _createDemoSpots('demo_piece_2'),
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        lastOpened: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Piece(
        id: 'demo_piece_3',
        title: 'Debussy Clair de Lune',
        composer: 'Claude Debussy',
        pdfFilePath: 'assets/demo_debussy.pdf',
        difficulty: 5,
        keySignature: 'D♭ major',
        genre: 'Impressionist',
        duration: 5, // minutes
        totalTimeSpent: const Duration(hours: 25, minutes: 45),
        targetTempo: 66,
        currentTempo: 62,
        spots: _createDemoSpots('demo_piece_3'),
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
        lastOpened: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];
    
    // Create demo project
    _demoProject = Project(
      id: 'demo_project',
      name: 'Spring Recital 2024',
      description: 'Annual spring recital featuring Romantic and Impressionist pieces',
      concertDate: DateTime.now().add(const Duration(days: 45)),
      dailyPracticeGoal: const Duration(minutes: 60),
      pieceIds: _demoPieces.map((p) => p.id).toList(),
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    );
    
    // Create demo annotations
    _demoAnnotations = _createDemoAnnotations();
  }
  
  List<Spot> _createDemoSpots(String pieceId) {
    final now = DateTime.now();
    return [
      Spot(
        id: '${pieceId}_spot_1',
        pieceId: pieceId,
        title: 'Opening melody',
        description: 'Focus on phrasing and dynamics',
        pageNumber: 1,
        x: 0.3,
        y: 0.2,
        width: 0.2,
        height: 0.1,
        priority: SpotPriority.medium,
        readinessLevel: ReadinessLevel.learning,
        color: SpotColor.yellow,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 6)),
        lastPracticed: now.subtract(const Duration(hours: 6)),
        nextDue: now.add(const Duration(hours: 18)),
        recommendedPracticeTime: 5, // minutes
        history: [
          SpotHistory(
            id: '1',
            spotId: '${pieceId}_spot_1',
            practiceTimeMinutes: 5,
            result: SpotResult.good,
            timestamp: now.subtract(const Duration(hours: 6)),
          ),
          SpotHistory(
            id: '2',
            spotId: '${pieceId}_spot_1',
            practiceTimeMinutes: 3,
            result: SpotResult.struggled,
            timestamp: now.subtract(const Duration(days: 1)),
          ),
        ],
      ),
      Spot(
        id: '${pieceId}_spot_2',
        pieceId: pieceId,
        title: 'Tricky passage',
        description: 'Slow practice needed - complex fingering',
        pageNumber: 2,
        x: 0.6,
        y: 0.4,
        width: 0.25,
        height: 0.15,
        priority: SpotPriority.high,
        readinessLevel: ReadinessLevel.learning,
        color: SpotColor.red,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(hours: 12)),
        lastPracticed: now.subtract(const Duration(hours: 12)),
        nextDue: now.subtract(const Duration(hours: 2)), // Overdue
        recommendedPracticeTime: 8, // minutes
        history: [
          SpotHistory(
            id: '3',
            spotId: '${pieceId}_spot_2',
            practiceTimeMinutes: 8,
            result: SpotResult.failed,
            timestamp: now.subtract(const Duration(hours: 12)),
          ),
          SpotHistory(
            id: '4',
            spotId: '${pieceId}_spot_2',
            practiceTimeMinutes: 5,
            result: SpotResult.struggled,
            timestamp: now.subtract(const Duration(days: 2)),
          ),
        ],
      ),
      Spot(
        id: '${pieceId}_spot_3',
        pieceId: pieceId,
        title: 'Ending cadenza',
        description: 'Well learned - maintenance only',
        pageNumber: 3,
        x: 0.4,
        y: 0.7,
        width: 0.2,
        height: 0.1,
        priority: SpotPriority.low,
        readinessLevel: ReadinessLevel.review,
        color: SpotColor.green,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(hours: 24)),
        lastPracticed: now.subtract(const Duration(hours: 24)),
        nextDue: now.add(const Duration(days: 3)),
        recommendedPracticeTime: 2, // minutes
        history: [
          SpotHistory(
            id: '5',
            spotId: '${pieceId}_spot_3',
            practiceTimeMinutes: 2,
            result: SpotResult.excellent,
            timestamp: now.subtract(const Duration(hours: 24)),
          ),
          SpotHistory(
            id: '6',
            spotId: '${pieceId}_spot_3',
            practiceTimeMinutes: 3,
            result: SpotResult.good,
            timestamp: now.subtract(const Duration(days: 3)),
          ),
        ],
      ),
    ];
  }
  
  List<Annotation> _createDemoAnnotations() {
    return [
      Annotation(
        id: 'anno_1',
        pieceId: 'demo_piece_1',
        page: 1,
        layerId: 'fingering',
        colorTag: ColorTag.yellow,
        tool: AnnotationTool.highlighter,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        path: [
          const Offset(0.2, 0.3),
          const Offset(0.7, 0.3),
          const Offset(0.7, 0.35),
          const Offset(0.2, 0.35),
        ],
        bounds: const Rect.fromLTWH(0.2, 0.3, 0.5, 0.05),
      ),
      Annotation(
        id: 'anno_2',
        pieceId: 'demo_piece_1',
        page: 2,
        layerId: 'performance',
        colorTag: ColorTag.red,
        tool: AnnotationTool.pen,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        path: [
          const Offset(0.5, 0.4),
          const Offset(0.6, 0.5),
        ],
        text: 'Watch tempo here!',
        bounds: const Rect.fromLTWH(0.5, 0.4, 0.1, 0.1),
      ),
    ];
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ScoreRead Pro Features Demo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'SRS Algorithm'),
            Tab(text: 'Readiness Score'),
            Tab(text: 'Smart Practice'),
            Tab(text: 'Time Tracking'),
            Tab(text: 'Annotations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildSRSTab(),
          _buildReadinessTab(),
          _buildPracticeTab(),
          _buildTimeTrackingTab(),
          _buildAnnotationsTab(),
        ],
      ),
    );
  }
  
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ScoreRead Pro Features',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'A comprehensive PDF reader for musicians with advanced practice management, '
            'spaced repetition learning, and intelligent annotation system.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          _buildFeatureCard(
            'Spaced Repetition System (SRS)',
            'Research-based algorithm that schedules practice spots for optimal retention',
            Icons.psychology,
            AppColors.primary,
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            'Readiness Scoring',
            'AI-powered performance readiness assessment with concert deadline awareness',
            Icons.analytics,
            AppColors.successGreen,
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            'Smart Practice Sessions',
            'Intelligent practice planning with interleaved and blocked practice modes',
            Icons.auto_awesome,
            AppColors.warningOrange,
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            'Time Tracking & Analytics',
            'Comprehensive practice time tracking with weekly insights and achievements',
            Icons.schedule,
            AppColors.accentPurple,
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            'Vector Annotations',
            'Professional annotation system with color tagging and layer organization',
            Icons.edit,
            AppColors.errorRed,
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            'Multi-View PDF Reader',
            'Zero-lag PDF viewing with multiple view modes and performance optimization',
            Icons.picture_as_pdf,
            AppColors.warningYellow,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSRSTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spaced Repetition System',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'The SRS algorithm intelligently schedules practice spots based on '
            'performance history, difficulty, and concert deadlines.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          
          // SRS Settings Demo
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SRS Configuration',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildSRSProfileCard(SRSProfile.aggressive),
                  const SizedBox(height: 8),
                  _buildSRSProfileCard(SRSProfile.standard),
                  const SizedBox(height: 8),
                  _buildSRSProfileCard(SRSProfile.gentle),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Spot scheduling demo
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Smart Scheduling Demo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...(_demoPieces.first.spots.map((spot) => _buildSpotScheduleCard(spot))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReadinessTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Readiness',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'AI-powered readiness scoring considers practice time, success rates, '
            'tempo achievement, and concert proximity.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          
          // Piece readiness scores
          ..._demoPieces.map((piece) => _buildPieceReadinessCard(piece)),
          
          const SizedBox(height: 16),
          
          // Project readiness
          _buildProjectReadinessCard(),
        ],
      ),
    );
  }
  
  Widget _buildPracticeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Smart Practice Sessions',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Generate optimized practice sessions using research-based learning principles.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          
          // Practice session types
          ...PracticeSessionType.values.map((type) => _buildSessionTypeCard(type)),
        ],
      ),
    );
  }
  
  Widget _buildTimeTrackingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Time Tracking & Analytics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Comprehensive practice time tracking with insights and achievements.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          
          // Current session status
          _buildCurrentSessionCard(),
          
          const SizedBox(height: 16),
          
          // Weekly analytics demo
          _buildWeeklyAnalyticsCard(),
          
          const SizedBox(height: 16),
          
          // Practice insights
          _buildPracticeInsightsCard(),
        ],
      ),
    );
  }
  
  Widget _buildAnnotationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vector Annotation System',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Professional-grade annotation tools with vector graphics and color organization.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          
          // Annotation tools
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Annotation Tools',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AnnotationTool.values.map((tool) => Chip(
                      avatar: Icon(_getAnnotationToolIcon(tool), size: 16),
                      label: Text(_getAnnotationToolDisplayName(tool)),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Color tags
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Color Tags',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ColorTag.values.map((tag) => Chip(
                      backgroundColor: _getColorTagColor(tag).withValues(alpha: 0.2),
                      label: Text(_getColorTagDisplayName(tag)),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Demo annotations
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Demo Annotations',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._demoAnnotations.map((annotation) => _buildAnnotationCard(annotation)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureCard(String title, String description, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSRSProfileCard(SRSProfile profile) {
    return Card(
      color: profile == SRSProfile.standard ? AppColors.primary.withValues(alpha: 0.1) : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              profile == SRSProfile.aggressive ? Icons.flash_on :
              profile == SRSProfile.standard ? Icons.balance :
              Icons.spa,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    profile.description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '${profile.baseMultiplier}x',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSpotScheduleCard(Spot spot) {
    final urgency = _srsService.calculateUrgencyScore(spot, concertDate: _demoProject.concertDate);
    final nextDue = _srsService.calculateNextDue(spot, SpotResult.excellent, concertDate: _demoProject.concertDate);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 8,
                  backgroundColor: spot.color.visualColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    spot.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  'Urgency: ${(urgency * 100).toInt()}%',
                  style: TextStyle(
                    color: urgency > 0.7 ? AppColors.errorRed : AppColors.successGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Next due: ${_formatDuration(nextDue.difference(DateTime.now()))}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPieceReadinessCard(Piece piece) {
    final readinessScore = _readinessService.calculatePieceReadiness(
      piece,
      concertDate: _demoProject.concertDate,
    );
    final readinessLevel = _readinessService.getReadinessLevel(readinessScore);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        piece.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        piece.composer,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                CircularProgressIndicator(
                  value: readinessScore / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation(readinessScore.readinessColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: readinessLevel.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    readinessLevel.label,
                    style: TextStyle(
                      color: readinessLevel.color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${readinessScore.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: readinessScore.readinessColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProjectReadinessCard() {
    final projectReadiness = _readinessService.calculateProjectReadiness(_demoProject, _demoPieces);
    final overallScore = projectReadiness['overallScore'] as double;
    final level = projectReadiness['level'] as readiness_service.ReadinessLevel;
    final recommendations = projectReadiness['recommendations'] as List<String>;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _demoProject.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Concert: ${_formatDate(_demoProject.concertDate!)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${overallScore.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: overallScore.readinessColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: level.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                level.label,
                style: TextStyle(
                  color: level.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Recommendations:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            ...recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(rec)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSessionTypeCard(PracticeSessionType type) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Icon(type.icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.displayName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type.description,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCurrentSessionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timer, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Current Session',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  _timeService.isSessionActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: _timeService.isSessionActive ? AppColors.successGreen : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_timeService.isSessionActive) ...[
              Text('Duration: ${_formatDuration(_timeService.getCurrentSessionDuration())}'),
              const SizedBox(height: 4),
              const Text('Piece: Chopin Nocturne Op. 9 No. 2'),
              const SizedBox(height: 4),
              const Text('Spot: Opening melody'),
            ] else ...[
              const Text('No active session'),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  _timeService.startSession(pieceId: _demoPieces.first.id);
                  setState(() {});
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Practice'),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildWeeklyAnalyticsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'This Week',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Total Time', '4h 25m', Icons.schedule),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard('Sessions', '8', Icons.event),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Consistency', '85%', Icons.trending_up),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard('Avg/Day', '38min', Icons.today),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPracticeInsightsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, color: AppColors.warningOrange),
                SizedBox(width: 8),
                Text(
                  'Practice Insights',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInsightItem('Your most productive day was Monday (1h 15m)'),
            _buildInsightItem('Focus on critical spots - you have 3 overdue'),
            _buildInsightItem('Great consistency! You practiced 5/7 days this week'),
            _buildInsightItem('Consider increasing daily practice time for concert readiness'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInsightItem(String insight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right, size: 16, color: AppColors.primary),
          const SizedBox(width: 4),
          Expanded(child: Text(insight)),
        ],
      ),
    );
  }
  
  Widget _buildAnnotationCard(Annotation annotation) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getAnnotationToolIcon(annotation.tool),
                  color: annotation.color,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _getAnnotationToolDisplayName(annotation.tool),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (annotation.colorTag != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getColorTagColor(annotation.colorTag).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getColorTagDisplayName(annotation.colorTag),
                      style: TextStyle(
                        fontSize: 10,
                        color: _getColorTagColor(annotation.colorTag),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (annotation.text != null) ...[
              const SizedBox(height: 4),
              Text(
                annotation.text!,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Page ${annotation.page} • ${annotation.layerId} layer',
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    if (duration.isNegative) {
      return 'Overdue by ${_formatDuration(-duration)}';
    }
    
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference > 0) {
      return 'In $difference days';
    } else {
      return '${-difference} days ago';
    }
  }

  // Helper functions for missing enum getters
  IconData _getAnnotationToolIcon(AnnotationTool tool) {
    switch (tool) {
      case AnnotationTool.pen:
        return Icons.edit;
      case AnnotationTool.highlighter:
        return Icons.highlight;
      case AnnotationTool.eraser:
        return Icons.auto_fix_normal;
      case AnnotationTool.text:
        return Icons.text_fields;
      case AnnotationTool.stamp:
        return Icons.label;
    }
  }

  String _getAnnotationToolDisplayName(AnnotationTool tool) {
    switch (tool) {
      case AnnotationTool.pen:
        return 'Pen';
      case AnnotationTool.highlighter:
        return 'Highlighter';
      case AnnotationTool.eraser:
        return 'Eraser';
      case AnnotationTool.text:
        return 'Text';
      case AnnotationTool.stamp:
        return 'Stamp';
    }
  }

  String _getColorTagDisplayName(ColorTag tag) {
    switch (tag) {
      case ColorTag.yellow:
        return 'Dynamics';
      case ColorTag.blue:
        return 'Fingering';
      case ColorTag.purple:
        return 'Phrasing';
      case ColorTag.red:
        return 'Critical';
      case ColorTag.green:
        return 'Corrections';
    }
  }

  Color _getColorTagColor(ColorTag tag) {
    switch (tag) {
      case ColorTag.yellow:
        return Colors.yellow;
      case ColorTag.blue:
        return Colors.blue;
      case ColorTag.purple:
        return Colors.purple;
      case ColorTag.red:
        return Colors.red;
      case ColorTag.green:
        return Colors.green;
    }
  }
}
