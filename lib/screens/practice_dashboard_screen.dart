import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../models/spot.dart';
import '../models/piece.dart';
import '../services/srs_ai_engine.dart';
import '../services/spot_service.dart';
import '../services/piece_service.dart';
import '../providers/unified_library_provider.dart';
import '../providers/practice_provider.dart';
import '../theme/app_theme.dart';
import 'pdf_viewer_screen.dart';
import '../models/pdf_document.dart';
import '../widgets/practice_session_widget.dart';
import '../widgets/learning_recommendations_widget.dart';
import '../widgets/layout_typography_demo_widget.dart';

class PracticeDashboardScreen extends ConsumerStatefulWidget {
  const PracticeDashboardScreen({super.key});

  @override
  ConsumerState<PracticeDashboardScreen> createState() => _PracticeDashboardScreenState();
}

class _PracticeDashboardScreenState extends ConsumerState<PracticeDashboardScreen> 
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load practice data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(practiceProvider.notifier).loadPracticeData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh when app resumes (user returns from PDF viewer)
    if (state == AppLifecycleState.resumed) {
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          ref.read(practiceProvider.notifier).refresh();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final practiceState = ref.watch(practiceProvider);
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: practiceState.isLoading 
          ? Center(child: CircularProgressIndicator())
          : practiceState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${practiceState.error}'),
                      ElevatedButton(
                        onPressed: () => ref.read(practiceProvider.notifier).refresh(),
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    // Modern App Bar
                    SliverAppBar(
                      expandedHeight: 120,
                      floating: false,
                      pinned: true,
                      backgroundColor: Colors.transparent,
                      flexibleSpace: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryPurple,
                              AppColors.accentPurple,
                            ],
                          ),
                        ),
                        child: FlexibleSpaceBar(
                          title: const Text(
                            'AI Practice Dashboard',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                          background: Stack(
                            children: [
                              Positioned(
                                right: -40,
                                top: -40,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 20,
                                top: 60,
                                child: Icon(
                                  Icons.track_changes_outlined,
                                  color: Colors.white.withOpacity(0.15),
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      actions: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                            tooltip: 'Import PDF',
                            onPressed: _importPdfForPractice,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(right: 16),
                          child: IconButton(
                            icon: const Icon(Icons.refresh_outlined, color: Colors.white),
                            tooltip: 'Refresh',
                            onPressed: () => ref.read(practiceProvider.notifier).refresh(),
                          ),
                        ),
                      ],
                    ),
                    
                    // Content
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Practice Session Timer with Micro-breaks
                            const PracticeSessionWidget(),
                            
                            const SizedBox(height: 20),
                            
                            // Learning Recommendations based on profile
                            const LearningRecommendationsWidget(),
                            
                            const SizedBox(height: 20),
                            
                            // Layout & Typography Demo showing settings in action
                            const LayoutTypographyDemoWidget(),
                            
                            const SizedBox(height: 20),
                            
                            // Quick Stats Row
                            _buildQuickStatsRow(practiceState),
                            
                            const SizedBox(height: 20),
                            
                            if (practiceState.urgentSpots?.isNotEmpty == true)
                              _buildUrgentSpotsCard(practiceState.urgentSpots!),
                            if (practiceState.urgentSpots?.isNotEmpty == true)
                              const SizedBox(height: 20),
                            
                            _buildDailyPlanCard(practiceState.dailyPlan ?? []),
                            
                            const SizedBox(height: 100), // Bottom padding
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildQuickStatsRow(PracticeState practiceState) {
    final totalSpots = practiceState.stats?.totalSpots ?? 0;
    final dueSpots = practiceState.dailyPlan?.length ?? 0;
    final urgentSpots = practiceState.urgentSpots?.length ?? 0;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Spots',
            '$totalSpots',
            Icons.location_on_outlined,
            AppColors.primaryPurple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Due Today',
            '$dueSpots',
            Icons.today_outlined,
            AppColors.spotYellow,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Urgent',
            '$urgentSpots',
            Icons.priority_high_outlined,
            AppColors.spotRed,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentSpotsCard(List<Spot> urgentSpots) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.spotRed.withOpacity(0.1),
            AppColors.spotRed.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.spotRed.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.spotRed.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.spotRed.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.priority_high_outlined,
                  color: AppColors.spotRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Urgent Practice Needed',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.spotRed,
                      ),
                    ),
                    Text(
                      'These spots need immediate attention',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.spotRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${urgentSpots.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: urgentSpots.take(3).map((spot) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildSpotTile(spot, isUrgent: true),
              ),
            ).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyPlanCard(List<Spot> dailyPlan) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryPurple.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.track_changes_outlined,
                  color: AppColors.primaryPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Practice Plan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'AI-optimized for your progress',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (dailyPlan.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${dailyPlan.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (dailyPlan.isEmpty)
            _buildEmptyPracticeState()
          else
            Column(
              children: dailyPlan.take(5).map((spot) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildSpotTile(spot),
                ),
              ).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyPracticeState() {
    return Column(
      children: [
        Icon(
          Icons.music_note_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        ),
        SizedBox(height: 16),
        Text(
          'Ready to start practicing?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Import a PDF to begin your AI-guided practice journey',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _importPdfForPractice,
          icon: Icon(Icons.add),
          label: Text('Import PDF'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSpotTile(Spot spot, {bool isUrgent = false}) {
    // Use correct priority colors - red for high priority, yellow for medium, green for low
    Color spotColor = AppColors.successGreen; // Default green for low priority
    if (spot.priority == SpotPriority.high) {
      spotColor = AppColors.errorRed;
    } else if (spot.priority == SpotPriority.medium) {
      spotColor = AppColors.warningOrange;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isUrgent 
            ? AppColors.errorRed.withOpacity(0.05)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        // Removed border rectangles as requested
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 6,
          height: 40,
          decoration: BoxDecoration(
            color: spotColor, // Use correct priority color
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        title: Text(
          spot.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getReadinessColor(spot.readinessLevel).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  spot.readinessLevel.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _getReadinessColor(spot.readinessLevel),
                  ),
                ),
              ),
              SizedBox(width: 8),
              if (spot.nextDue != null)
                Text(
                  _formatDueDate(spot.nextDue!),
                  style: TextStyle(
                    fontSize: 12,
                    color: isUrgent ? Colors.red.shade700 : null,
                    fontWeight: isUrgent ? FontWeight.w600 : null,
                  ),
                ),
            ],
          ),
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '${spot.recommendedPracticeTime}min',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 12,
            ),
          ),
        ),
        onTap: () => _openSpotInPdf(spot),
      ),
    );
  }

  Color _getReadinessColor(ReadinessLevel level) {
    switch (level) {
      case ReadinessLevel.newSpot:
        return AppColors.errorRed; // Red for new spots needing practice
      case ReadinessLevel.learning:
        return AppColors.warningOrange; // Orange for learning spots
      case ReadinessLevel.review:
        return AppColors.successGreen; // Green for review spots
      case ReadinessLevel.mastered:
        return AppColors.primaryPurple; // Purple for mastered spots
    }
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    
    if (difference < 0) {
      return 'Overdue by ${-difference} days';
    } else if (difference == 0) {
      return 'Due today';
    } else if (difference == 1) {
      return 'Due tomorrow';
    } else {
      return 'Due in $difference days';
    }
  }

  Future<void> _openSpotInPdf(Spot spot) async {
    try {
      // Get the actual piece from the unified library
      final asyncPieces = ref.read(unifiedLibraryProvider);
      
      // Handle AsyncValue states
      final pieces = asyncPieces.when(
        data: (data) => data,
        loading: () => <Piece>[],
        error: (error, stack) => <Piece>[],
      );
      
      final piece = pieces.where((p) => p.id == spot.pieceId).firstOrNull;
      
      if (piece == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not find piece for this spot')),
          );
        }
        return;
      }
      
      // Create PDF document from the piece
      final pdfDocument = PDFDocument(
        id: piece.id,
        title: piece.title,
        filePath: piece.pdfFilePath,
        category: 'Sheet Music',
        isFavorite: false,
        lastOpened: DateTime.now(),
      );

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewerScreen(document: pdfDocument),
        ),
      );
      
      // Refresh dashboard when returning - this will show newly created spots
      ref.read(practiceProvider.notifier).refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening PDF: $e')),
        );
      }
    }
  }

  /// Import PDF directly from AI Practice Dashboard for immediate practice connection
  Future<void> _importPdfForPractice() async {
    try {
      print('PracticeDashboard: Starting PDF import for immediate practice');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening file picker to import PDF for practice...'),
          backgroundColor: Colors.blue,
        ),
      );

      // Import PDF file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        print('PracticeDashboard: PDF selected: ${file.name}');
        
        if (file.path != null) {
          // Show dialog to get piece details
          final pieceDetails = await _showPieceDetailsDialog();
          
          if (pieceDetails != null) {
            final now = DateTime.now();
            final pieceId = 'practice_${now.millisecondsSinceEpoch}';
            
            // Create piece object
            final piece = Piece(
              id: pieceId,
              title: pieceDetails['title'] ?? file.name.replaceAll('.pdf', ''),
              composer: pieceDetails['composer'] ?? 'Unknown Composer',
              keySignature: pieceDetails['keySignature'],
              difficulty: pieceDetails['difficulty'] ?? 3,
              pdfFilePath: file.path!,
              spots: [],
              createdAt: now,
              updatedAt: now,
              totalPages: 1,
            );
            
            print('PracticeDashboard: Saving piece ${piece.id}');
            
            // Save piece to library via unified provider
            await ref.read(unifiedLibraryProvider.notifier).addPiece(piece);
            
            // Create initial practice spot (not urgent, just ready to practice)
            final spot = Spot(
              id: 'practice_spot_${now.millisecondsSinceEpoch}',
              pieceId: piece.id,
              title: 'New Import: ${piece.title}',
              description: 'Ready for practice! Open PDF to create specific practice spots.',
              pageNumber: 1,
              x: 0.2,  // More centered position
              y: 0.2,  // More centered position 
              width: 0.6,  // More reasonable width
              height: 0.2,  // More reasonable height for a practice spot
              priority: SpotPriority.medium, // Medium priority - not urgent
              readinessLevel: ReadinessLevel.newSpot,
              color: SpotColor.yellow, // Yellow for new imports (practice needed)
              createdAt: now,
              updatedAt: now,
              nextDue: now, // Available for practice immediately
              isActive: true,
            );
            
            print('PracticeDashboard: Creating practice spot ${spot.id}');
            
            // Save spot
            final spotService = ref.read(spotServiceProvider);
            await spotService.saveSpot(spot);
            
            // Refresh practice dashboard immediately
            ref.read(practiceProvider.notifier).refresh();
            
            print('PracticeDashboard: Import completed, practice dashboard refreshed');
            
            if (mounted) {
              // Show success message with prominent action button
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ ${piece.title} imported successfully! Tap "Open PDF" to start practicing.'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 10), // Longer duration
                  behavior: SnackBarBehavior.floating, // Make it more prominent
                  action: SnackBarAction(
                    label: 'Open PDF',
                    textColor: Colors.white,
                    backgroundColor: Colors.green.shade700,
                    onPressed: () => _openPdfViewer(piece),
                  ),
                ),
              );
              
              // Also show a dialog for immediate access
              Future.delayed(Duration(seconds: 1), () {
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('PDF Imported!'),
                        ],
                      ),
                      content: Text('${piece.title} is ready for practice. Would you like to open it now?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Later'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _openPdfViewer(piece);
                          },
                          child: Text('Open PDF'),
                        ),
                      ],
                    ),
                  );
                }
              });
            }
          }
        }
      }
    } catch (e) {
      print('PracticeDashboard: Error importing PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Open PDF viewer for a piece
  void _openPdfViewer(Piece piece) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerScreen(
          document: PDFDocument(
            id: piece.id,
            title: piece.title,
            filePath: piece.pdfFilePath,
            category: 'Music',
            isFavorite: false,
            lastOpened: DateTime.now(),
          ),
        ),
      ),
    );
  }

  /// Show dialog to get piece details
  Future<Map<String, dynamic>?> _showPieceDetailsDialog() async {
    final titleController = TextEditingController();
    final composerController = TextEditingController();
    String? selectedKeySignature;
    int selectedDifficulty = 3;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Piece Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter piece title',
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: composerController,
                  decoration: InputDecoration(
                    labelText: 'Composer',
                    hintText: 'Enter composer name',
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedKeySignature,
                  decoration: InputDecoration(labelText: 'Key Signature'),
                  items: ['C Major', 'G Major', 'D Major', 'A Major', 'E Major', 'B Major', 'F# Major',
                         'A minor', 'E minor', 'B minor', 'F# minor', 'C# minor', 'G# minor', 'D# minor']
                      .map((key) => DropdownMenuItem(value: key, child: Text(key)))
                      .toList(),
                  onChanged: (value) => selectedKeySignature = value,
                ),
                SizedBox(height: 16),
                Text('Difficulty: $selectedDifficulty'),
                Slider(
                  value: selectedDifficulty.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (value) {
                    setState(() {
                      selectedDifficulty = value.round();
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'title': titleController.text.trim().isEmpty ? null : titleController.text.trim(),
                  'composer': composerController.text.trim().isEmpty ? null : composerController.text.trim(),
                  'keySignature': selectedKeySignature,
                  'difficulty': selectedDifficulty,
                });
              },
              child: Text('Import'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.music_note_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          SizedBox(height: 24),
          Text(
            'Welcome to AI Practice!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            'Your personalized practice companion is ready.\nImport a PDF to get started with AI-guided practice.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _importPdfForPractice,
            icon: Icon(Icons.upload_file),
            label: Text('Import Your First PDF'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
