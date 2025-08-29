import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../models/spot.dart';
import '../models/piece.dart';
import '../models/project.dart';
import '../models/practice_session.dart';
import '../models/pdf_document.dart';
import '../services/srs_ai_engine.dart';
import '../services/spot_service.dart';
import '../services/piece_service.dart';
import '../services/database_service.dart';
import '../providers/unified_library_provider.dart';
import '../providers/practice_provider.dart';
import '../providers/practice_session_provider.dart';
import '../theme/app_theme.dart';
import 'pdf_viewer_screen.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import '../screens/pdf_viewer_screen.dart';
import '../screens/library_screen.dart';
import '../models/pdf_document.dart';
import '../widgets/practice_session_widget.dart';
import 'settings/settings_screen.dart';
import 'practice/active_practice_session_screen.dart';

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

  // Helper method to get theme-aware text colors
  Color _getSecondaryTextColor() {
    return Theme.of(context).brightness == Brightness.dark 
        ? Colors.grey[300]! 
        : AppColors.textSecondary;
  }

  Color _getPrimaryTextColor() {
    return Theme.of(context).brightness == Brightness.dark 
        ? Colors.white 
        : AppColors.textPrimary;
  }

  // DEBUG: Clear all app data
  Future<void> _clearAllData() async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Recreate Database'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to recreate the database?'),
            const SizedBox(height: 12),
            Text(
              '⚠️ This will permanently delete:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
              ),
            ),
            const SizedBox(height: 8),
            Text('• All practice spots and annotations'),
            Text('• Practice history and statistics'),
            Text('• All user preferences and settings'),
            Text('• Imported PDF files and projects'),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Yes, Recreate Database'),
          ),
        ],
      ),
    );

    // Only proceed if user confirmed
    if (confirmed != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      print('DEBUG: Clearing ${keys.length} keys from SharedPreferences');
      await prefs.clear();
      
      // Clear database by recreating it
      final databaseService = ref.read(databaseServiceProvider);
      print('DEBUG: Recreating database to clear all data');
      await databaseService.recreateDatabase();
      
      print('DEBUG: All data cleared successfully');
      
      // Refresh providers
      ref.read(practiceProvider.notifier).loadPracticeData();
      ref.invalidate(unifiedLibraryProvider);
      ref.invalidate(userProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All app data cleared - database recreated')),
        );
      }
    } catch (e) {
      print('DEBUG: Error clearing data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recreating database: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                          titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                          title: const Text(
                            'Practice Dashboard',
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
                          margin: const EdgeInsets.only(right: 16),
                          child: IconButton(
                            icon: const Icon(Icons.refresh_outlined, color: Colors.white),
                            tooltip: 'Refresh',
                            onPressed: () => ref.read(practiceProvider.notifier).refresh(),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(right: 16),
                          child: IconButton(
                            icon: const Icon(Icons.clear_all, color: Colors.white),
                            tooltip: 'Clear All Data (DEBUG)',
                            onPressed: _clearAllData,
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
                            // 1. Today's Progress Tracking
                            _buildTodaysProgressSection(practiceState),
                            
                            const SizedBox(height: 20),
                            
                            // Quick Stats Row (between progress and plan)
                            _buildQuickStatsRow(practiceState),
                            
                            const SizedBox(height: 20),
                            
                            // 3. Today's Practice Plan (Daily Plan)
                            _buildDailyPlanCard(practiceState.dailyPlan ?? []),
                            
                            const SizedBox(height: 20),
                            
                            // 4. Practice Session Timer - Shows active session if any
                            _buildPracticeSessionSection(),
                            
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
                        color: _getPrimaryTextColor(),
                      ),
                    ),
                    Text(
                      'AI-optimized for your progress',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey[300]
                            : AppColors.textSecondary,
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
          'Add pieces to your library to begin your AI-guided practice journey.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSpotTile(Spot spot, {bool isUrgent = false}) {
    return Consumer(
      builder: (context, ref, child) {
        final colorblindMode = false; // TODO: Add colorblind mode support
        
        // Use colorblind-aware spot colors based on SpotColor enum
        Color spotColor = AppColors.getSpotColorByEnum(spot.color, colorblindMode: colorblindMode);

        // Get piece name from unified library
        final asyncPieces = ref.watch(unifiedLibraryProvider);
        String displayTitle = spot.title;
        
        asyncPieces.whenData((pieces) {
          final piece = pieces.where((p) => p.id == spot.pieceId).firstOrNull;
          if (piece != null) {
            displayTitle = piece.title;
          }
        });

        return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isUrgent 
            ? spotColor.withOpacity(0.05)
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
            color: spotColor, // Use colorblind-aware spot color
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        title: Text(
          displayTitle,
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
        trailing: SizedBox.shrink(), // Remove the time display as requested
        onTap: () => _openSpotInPdf(spot),
      ),
    );
      },
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
            SnackBar(
              content: Text('Could not find piece for this spot'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      
      // Start a practice session for this piece instead of opening PDF directly
      try {
        await ref.read(activePracticeSessionProvider.notifier)
            .startPieceSession(piece, SessionType.smart);
        
        // Navigate to active practice session screen
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ActivePracticeSessionScreen(),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error starting practice session: $e'),
              backgroundColor: AppColors.errorRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening practice session: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Adjust practice time for a specific spot
  Future<void> _adjustPracticeTime(Spot spot) async {
    final currentTime = spot.recommendedPracticeTime;
    
    final newTime = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adjust Practice Time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current practice time: ${currentTime} minutes'),
            SizedBox(height: 16),
            Text('Select new practice time:'),
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [5, 10, 15, 20, 30, 45, 60].map((minutes) => 
                ChoiceChip(
                  label: Text('${minutes}min'),
                  selected: minutes == currentTime,
                  onSelected: (selected) {
                    if (selected) {
                      Navigator.of(context).pop(minutes);
                    }
                  },
                ),
              ).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
        ],
      ),
    );

    if (newTime != null && newTime != currentTime) {
      try {
        // Update the spot's recommended practice time
        final updatedSpot = spot.copyWith(
          recommendedPracticeTime: newTime,
          updatedAt: DateTime.now(),
        );
        
        // Save the updated spot
        final spotService = ref.read(spotServiceProvider);
        await spotService.saveSpot(updatedSpot);
        
        // Refresh the practice dashboard
        ref.read(practiceProvider.notifier).refresh();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Practice time updated to ${newTime} minutes'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating practice time: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // Removed PDF import functionality - use library screen to add pieces

  /// Open PDF viewer for a piece
  void _openPdfViewer(Piece piece) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerScreen(
          piece: piece,
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
            onPressed: () {
              // Navigate to Library screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LibraryScreen(),
                ),
              );
            },
            icon: Icon(Icons.library_music),
            label: Text('Go to Library'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStartSection(PracticeState practiceState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple.withOpacity(0.1),
            AppColors.primaryPurple.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryPurple.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.1),
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
                  color: AppColors.primaryPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.rocket_launch_outlined,
                  color: AppColors.primaryPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Start',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryPurple,
                ),
              ),
              Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Smart Sessions',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Choose your practice approach based on your goals and available time.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          // Project Selector for Quick Start
          _buildProjectSelector(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickStartOption(
                  'Critical Focus',
                  '15-20 min',
                  'Target urgent spots only',
                  Icons.warning_amber_outlined,
                  AppColors.spotRed,
                  () => _startQuickSession('critical', practiceState),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickStartOption(
                  'Balanced Practice',
                  '30-45 min',
                  'Mix of all difficulty levels',
                  Icons.balance_outlined,
                  AppColors.spotYellow,
                  () => _startQuickSession('balanced', practiceState),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickStartOption(
                  'Maintenance',
                  '10-15 min',
                  'Review mastered pieces',
                  Icons.tune_outlined,
                  AppColors.spotGreen,
                  () => _startQuickSession('maintenance', practiceState),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStartOption(
    String title,
    String duration,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final isColorblind = false; // TODO: Add colorblind mode support
    final effectiveColor = isColorblind 
        ? AppColors.getSpotColorByEnum(
            color == AppColors.spotRed ? SpotColor.red :
            color == AppColors.spotYellow ? SpotColor.yellow : SpotColor.green
          )
        : color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: effectiveColor.withOpacity(0.3),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: effectiveColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: effectiveColor, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: effectiveColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              duration,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 9,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectSelector() {
    return FutureBuilder<List<Project>>(
      future: ref.read(databaseServiceProvider).getAllProjects(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryPurple.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Loading projects...',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryPurple.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.folder_open_outlined,
                  color: AppColors.primaryPurple,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Using: My Practice (Default)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final projects = snapshot.data!;
        final currentProjectName = ref.watch(currentProjectNameProvider);
        final currentProject = projects.firstWhere(
          (p) => p.name == currentProjectName,
          orElse: () => projects.first,
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryPurple.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.folder_outlined,
                color: AppColors.primaryPurple,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Project:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    DropdownButton<Project>(
                      value: currentProject,
                      isExpanded: true,
                      underline: Container(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryPurple,
                      ),
                      items: projects.map((Project project) {
                        return DropdownMenuItem<Project>(
                          value: project,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  project.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (project.pieceIds.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryPurple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${project.pieceIds.length} pieces',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.primaryPurple,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (Project? newProject) {
                        if (newProject != null && newProject != currentProject) {
                          ref.read(userProvider.notifier).setCurrentProject(
                                newProject.id,
                                newProject.name,
                              );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodaysProgressSection(PracticeState practiceState) {
    // Watch active session for real-time updates
    final activeSession = ref.watch(activePracticeSessionProvider);
    
    // Calculate real-time stats including active session
    final baseSessionTime = practiceState.stats?.todayPracticeTime ?? 0;
    final baseSpotsPracticed = practiceState.stats?.todaySpotsPracticed ?? 0;
    
    // Add active session time if there's an active session
    int totalSessionTime = baseSessionTime;
    int totalSpotsPracticed = baseSpotsPracticed;
    
    if (activeSession.hasActiveSession && activeSession.sessionStartTime != null) {
      final sessionDuration = DateTime.now().difference(activeSession.sessionStartTime!);
      totalSessionTime += sessionDuration.inMinutes;
      totalSpotsPracticed += activeSession.completedSpots; // Add completed spots from current session
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.06),
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
                  color: AppColors.primaryPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.trending_up_outlined,
                  color: AppColors.primaryPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Today's Progress",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white
                      : AppColors.textPrimary,
                ),
              ),
              Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getCurrentDateString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Progress Metrics Row
          Row(
            children: [
              Expanded(
                child: _buildProgressMetric(
                  'Session Time',
                  '$totalSessionTime min',
                  Icons.timer_outlined,
                  AppColors.primaryPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProgressMetric(
                  'Spots Practiced',
                  '$totalSpotsPracticed',
                  Icons.location_on_outlined,
                  AppColors.primaryPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProgressMetric(
                  'Goal Progress',
                  '${_calculateGoalProgress(practiceState, totalSessionTime)}%',
                  Icons.flag_outlined,
                  AppColors.spotYellow,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Quick Session Management
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _startNewSession(practiceState),
                  icon: Icon(Icons.play_arrow_outlined, size: 18),
                  label: Text('Start Session'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewWeeklyStats(practiceState),
                  icon: Icon(Icons.analytics_outlined, size: 18),
                  label: Text('Weekly Stats'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryPurple,
                    side: BorderSide(color: AppColors.primaryPurple),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressMetric(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
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

  // Helper methods for the new features
  String _getCurrentDateString() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[now.month - 1]} ${now.day}';
  }

  int _calculateGoalProgress(PracticeState practiceState, [int? overrideTodayTime]) {
    final todayTime = overrideTodayTime ?? practiceState.stats?.todayPracticeTime ?? 0;
    final dailyGoal = 30; // Default 30 minutes goal, could be from user settings
    return ((todayTime / dailyGoal) * 100).clamp(0, 100).round();
  }

  void _startQuickSession(String sessionType, PracticeState practiceState) {
    // Get current project from user provider
    final currentProject = ref.read(currentProjectNameProvider);
    
    // Map session types to the enum
    SessionType type;
    switch (sessionType) {
      case 'critical':
        type = SessionType.critical;
        break;
      case 'balanced':
        type = SessionType.balanced;
        break;
      case 'maintenance':
        type = SessionType.maintenance;
        break;
      default:
        type = SessionType.smart;
    }
    
    // Start real practice session using the practice session provider
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quick Session: ${sessionType.toUpperCase()}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Starting a $sessionType practice session...'),
            const SizedBox(height: 12),
            if (sessionType == 'critical')
              Text('• Focus on urgent spots only\n• Based on your current ${practiceState.urgentSpots?.length ?? 0} urgent spots\n• High intensity practice'),
            if (sessionType == 'balanced')  
              Text('• Mix of all difficulty levels\n• Includes ${practiceState.dailyPlan?.length ?? 0} spots from your daily plan\n• Comprehensive practice'),
            if (sessionType == 'maintenance')
              Text('• Review mastered pieces\n• Light maintenance work\n• Keep skills sharp'),
            const SizedBox(height: 12),
            Text(
              'This will start a real practice session with AI-selected spots.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Start real practice session
              try {
                await ref.read(activePracticeSessionProvider.notifier)
                    .startProjectPracticeSession(currentProject, type);
                
                // Navigate to active practice session screen
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ActivePracticeSessionScreen(),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error starting session: $e'),
                      backgroundColor: AppColors.errorRed,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text('Start Session'),
          ),
        ],
      ),
    );
  }

  void _startNewSession(PracticeState practiceState) async {
    // Get pieces from unified library for selection
    final asyncPieces = ref.read(unifiedLibraryProvider);
    
    asyncPieces.when(
      data: (pieces) {
        if (pieces.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No pieces available. Add some pieces to your library first.'),
              backgroundColor: AppColors.errorRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        
        _showPieceSelectionDialog(pieces, practiceState);
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loading pieces...'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      error: (error, stack) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading pieces: $error'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  void _showPieceSelectionDialog(List<Piece> pieces, PracticeState practiceState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Piece to Practice'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: pieces.length,
            itemBuilder: (context, index) {
              final piece = pieces[index];
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.music_note,
                    color: AppColors.primaryPurple,
                    size: 20,
                  ),
                ),
                title: Text(
                  piece.title,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${piece.composer} • ${piece.spots.length} spots • ${piece.readinessPercentage.round()}% ready',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  Navigator.pop(context);
                  await _startPracticeSessionForPiece(piece);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _startPracticeSessionForPiece(Piece piece) async {
    try {
      // Start a practice session for the selected piece
      await ref.read(activePracticeSessionProvider.notifier)
          .startPieceSession(piece, SessionType.smart);
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ActivePracticeSessionScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting session: $e'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _viewWeeklyStats(PracticeState practiceState) {
    // Get real-time active session data
    final activeSession = ref.read(activePracticeSessionProvider);
    
    // Calculate real-time weekly stats including active session
    final baseWeeklyTime = practiceState.stats?.weeklyPracticeTime ?? 0;
    final baseWeeklySessions = practiceState.stats?.weeklySessions ?? 0;
    final baseTodayTime = practiceState.stats?.todayPracticeTime ?? 0;
    final baseTodaySpots = practiceState.stats?.todaySpotsPracticed ?? 0;
    
    // Add active session data if there's an active session
    int totalWeeklyTime = baseWeeklyTime;
    int totalWeeklySessions = baseWeeklySessions;
    int totalTodayTime = baseTodayTime;
    int totalTodaySpots = baseTodaySpots;
    
    if (activeSession.hasActiveSession && activeSession.sessionStartTime != null) {
      final sessionDuration = DateTime.now().difference(activeSession.sessionStartTime!);
      final sessionMinutes = sessionDuration.inMinutes;
      
      totalWeeklyTime += sessionMinutes;
      totalTodayTime += sessionMinutes;
      totalTodaySpots += activeSession.completedSpots;
      
      // If this is the first session today, count it towards weekly sessions
      if (baseTodayTime == 0) {
        totalWeeklySessions += 1;
      }
    }
    
    // Calculate average session time
    final averageSession = totalWeeklySessions > 0 ? 
        (totalWeeklyTime / totalWeeklySessions).round() : 0;
    // Show real weekly statistics from the database
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Weekly Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Practice Overview (Last 7 Days)', 
                 style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildStatRow('Total Practice Time', '$totalWeeklyTime minutes'),
            _buildStatRow('Sessions Completed', '$totalWeeklySessions'),
            _buildStatRow('Spots Improved', '${practiceState.stats?.weeklyImprovedSpots ?? 0}'),
            _buildStatRow('Average Session', '$averageSession min'),
            const SizedBox(height: 12),
            Text('Today\'s Progress', 
                 style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildStatRow('Practice Time Today', '$totalTodayTime minutes'),
            _buildStatRow('Spots Practiced Today', '$totalTodaySpots'),
            _buildStatRow('Goal Progress', '${_calculateGoalProgress(practiceState, totalTodayTime)}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeSessionSection() {
    return Consumer(
      builder: (context, ref, child) {
        final activePracticeSession = ref.watch(activePracticeSessionProvider);
        
        if (activePracticeSession.hasActiveSession) {
          // Show active session status
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryPurple.withOpacity(0.1),
                  AppColors.primaryPurple.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryPurple.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        activePracticeSession.isRunning ? Icons.play_arrow : Icons.pause,
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
                            'Active Practice Session',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.white
                                  : AppColors.primaryPurple,
                            ),
                          ),
                          Text(
                            activePracticeSession.session?.name ?? 'Practice Session',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.grey[300]
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${activePracticeSession.completedSpots}/${activePracticeSession.totalSpots}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Progress bar
                LinearProgressIndicator(
                  value: activePracticeSession.progress,
                  backgroundColor: AppColors.primaryPurple.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
                ),
                
                const SizedBox(height: 16),
                
                // Current spot info
                if (activePracticeSession.currentRealSpot != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Spot:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.grey[300]
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activePracticeSession.currentRealSpot!.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                
                // Session controls
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ActivePracticeSessionScreen(),
                            ),
                          );
                        },
                        child: Text('Continue Session'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () {
                        // Pause/Resume session
                        if (activePracticeSession.isRunning) {
                          ref.read(activePracticeSessionProvider.notifier).pauseSession();
                        } else {
                          ref.read(activePracticeSessionProvider.notifier).resumeSession();
                        }
                      },
                      child: Icon(
                        activePracticeSession.isRunning ? Icons.pause : Icons.play_arrow,
                        size: 18,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryPurple,
                        side: BorderSide(color: AppColors.primaryPurple),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        } else {
          // Show regular practice session widget when no active session
          return const PracticeSessionWidget();
        }
      },
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  /// Unified method to add new pieces - replaces duplicate import systems
  void _showAddPieceDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Add New Piece',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildAddOptionTile(
                    icon: Icons.file_upload,
                    title: 'Import PDF',
                    subtitle: 'Import from device storage',
                    onTap: () => _importPDFFromDevice(),
                  ),
                  const SizedBox(height: 12),
                  _buildAddOptionTile(
                    icon: Icons.cloud_upload,
                    title: 'Import from Cloud',
                    subtitle: 'Google Drive, Dropbox, etc.',
                    onTap: () => _importFromCloud(),
                  ),
                  const SizedBox(height: 12),
                  _buildAddOptionTile(
                    icon: Icons.camera_alt,
                    title: 'Scan Sheet Music',
                    subtitle: 'Take a photo of physical sheets',
                    onTap: () => _scanSheetMusic(),
                  ),
                  const SizedBox(height: 12),
                  _buildAddOptionTile(
                    icon: Icons.web,
                    title: 'IMSLP/Web Import',
                    subtitle: 'Import from music libraries',
                    onTap: () => _importFromWeb(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryPurple.withOpacity(0.1),
          child: Icon(icon, color: AppColors.primaryPurple),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  /// Import PDF from device storage - redirect to main library system
  Future<void> _importPDFFromDevice() async {
    Navigator.pop(context); // Close the dialog
    
    // Navigate to the main library screen where the full import system is available
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LibraryScreen(),
      ),
    );
    
    // Show guidance message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('📚 Use the Library tab to import PDFs with full spot and annotation support!'),
          backgroundColor: AppColors.primaryPurple,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Got it',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  /// Removed - PDF processing now handled by unified library system
  /// This eliminates duplication and ensures all pieces use the same spot system
  @Deprecated('Use LibraryScreen import functionality instead')
  Future<void> _processPDFFile(File file, String fileName) async {
    // Redirect to library system for consistent import experience
    throw UnsupportedError('PDF import moved to LibraryScreen for unified spot system');
  }

  /// Import from cloud services (placeholder for future implementation)
  Future<void> _importFromCloud() async {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cloud import coming soon!'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Scan sheet music (placeholder for future implementation)
  Future<void> _scanSheetMusic() async {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sheet music scanning coming soon!'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Import from web libraries (placeholder for future implementation)
  Future<void> _importFromWeb() async {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Web import coming soon!'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
