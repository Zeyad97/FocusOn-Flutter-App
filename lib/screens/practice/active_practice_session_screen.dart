import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../providers/practice_session_provider.dart';
import '../../providers/unified_library_provider.dart';
import '../../providers/practice_provider.dart';
import '../../services/spot_service.dart';
import '../../models/practice_session.dart';
import '../../models/spot.dart';
import '../../models/piece.dart';
import '../../models/pdf_document.dart';
import '../../theme/app_theme.dart';
import '../../screens/pdf_viewer/pdf_score_viewer.dart';
import '../../services/micro_breaks_service.dart';

class ActivePracticeSessionScreen extends ConsumerStatefulWidget {
  const ActivePracticeSessionScreen({super.key});

  @override
  ConsumerState<ActivePracticeSessionScreen> createState() => _ActivePracticeSessionScreenState();
}

class _ActivePracticeSessionScreenState extends ConsumerState<ActivePracticeSessionScreen> {
  Timer? _timer;
  Duration _sessionElapsed = Duration.zero;
  Duration _spotElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
    
    // Start micro-breaks timer if enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(practiceTimerProvider.notifier).startPracticeSession();
      
      // Auto-open score when practice session starts
      _autoOpenScore();
    });
  }

  /// Automatically open the score when practice session starts (Client Issue #6)
  void _autoOpenScore() {
    final practiceState = ref.read(activePracticeSessionProvider);
    
    if (practiceState.hasActiveSession && practiceState.session != null) {
      final session = practiceState.session!;
      final currentSpot = practiceState.currentSpot;
      
      // Get the piece for the current spot
      final unifiedLibraryState = ref.read(unifiedLibraryProvider);
      unifiedLibraryState.whenData((pieces) {
        if (currentSpot != null) {
          // Find the piece that contains this spot
          final currentPiece = pieces.firstWhere(
            (piece) => piece.spots.any((spot) => spot.id == currentSpot.spotId),
            orElse: () => pieces.firstWhere(
              (piece) => piece.id == session.projectId, // Fallback to project piece
              orElse: () => pieces.isNotEmpty ? pieces.first : throw Exception('No pieces available'),
            ),
          );
          
          // Find the actual spot details
          final currentSpotDetails = currentPiece.spots.firstWhere(
            (spot) => spot.id == currentSpot.spotId,
            orElse: () => currentPiece.spots.isNotEmpty ? currentPiece.spots.first : throw Exception('No spots available'),
          );
          
          // Auto-open the PDF viewer with the current spot
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _openFullPDFViewer(currentPiece, currentSpotDetails);
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _stopTimer();
    // Stop micro-breaks timer when leaving the screen
    // Note: Don't use ref after dispose() is called
    try {
      ref.read(practiceTimerProvider.notifier).stopPracticeSession();
    } catch (e) {
      // Widget already disposed, timer will be cleaned up automatically
      print('Practice session screen disposed, timer cleanup handled automatically');
    }
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final state = ref.read(activePracticeSessionProvider);
        if (state.isRunning && state.hasActiveSession) {
          setState(() {
            _sessionElapsed = _sessionElapsed + const Duration(seconds: 1);
            _spotElapsed = _spotElapsed + const Duration(seconds: 1);
          });
        } else if (!state.hasActiveSession) {
          // Stop timer if session is no longer active
          _stopTimer();
        }
      } else {
        // Stop timer if widget is not mounted
        _stopTimer();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _resetTimerState() {
    _stopTimer();
    setState(() {
      _sessionElapsed = Duration.zero;
      _spotElapsed = Duration.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    final practiceState = ref.watch(activePracticeSessionProvider);
    final practiceNotifier = ref.read(activePracticeSessionProvider.notifier);
    final microBreaksState = ref.watch(practiceTimerProvider);

    if (!practiceState.hasActiveSession) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Practice Session'),
        ),
        body: const Center(
          child: Text('No active practice session'),
        ),
      );
    }

    // Check if session is completed
    if (practiceState.isCompleted) {
      return _buildCompletionScreen(practiceState, practiceNotifier);
    }

    final session = practiceState.session!;
    final currentSpot = practiceState.currentSpot;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        // Show confirmation dialog before exiting
        final shouldExit = await _showExitConfirmationDialog();
        if (shouldExit && context.mounted) {
          _resetTimerState();
          ref.read(practiceTimerProvider.notifier).stopPracticeSession();
          // Cancel session (which saves it) before clearing
          await ref.read(activePracticeSessionProvider.notifier).cancelSession();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          title: Text(session.name),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldExit = await _showExitConfirmationDialog();
              if (shouldExit && context.mounted) {
                _resetTimerState();
                ref.read(practiceTimerProvider.notifier).stopPracticeSession();
                // Cancel session (which saves it) before clearing
                await ref.read(activePracticeSessionProvider.notifier).cancelSession();
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
          // Micro-breaks indicator
          if (microBreaksState.isRunning)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: microBreaksState.isOnBreak 
                    ? Colors.orange.withOpacity(0.2)
                    : Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: microBreaksState.isOnBreak ? Colors.orange : Colors.green,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    microBreaksState.isOnBreak ? Icons.pause_circle_filled : Icons.timer,
                    size: 16,
                    color: microBreaksState.isOnBreak ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    microBreaksState.isOnBreak 
                        ? 'Break: ${_formatDuration(microBreaksState.timeUntilBreak)}'
                        : 'Next break: ${_formatDuration(microBreaksState.timeUntilBreak)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: microBreaksState.isOnBreak ? Colors.orange : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: Icon(practiceState.isRunning ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              if (practiceState.isRunning) {
                practiceNotifier.pauseSession();
                ref.read(practiceTimerProvider.notifier).pausePracticeSession();
              } else {
                practiceNotifier.resumeSession();
                ref.read(practiceTimerProvider.notifier).startPracticeSession();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: () {
              _showCancelDialog(practiceNotifier);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: currentSpot == null 
          ? _buildSessionComplete(session)
          : _buildPracticeInterface(session, currentSpot, practiceNotifier),
      ),
    ), // End Scaffold
  ); // End PopScope
  } // End build method

  Widget _buildPracticeInterface(PracticeSession session, SpotSession currentSpot, ActivePracticeSessionNotifier notifier) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = (session.spotSessions.indexOf(currentSpot) + 1) / session.spotSessions.length;

    return Column(
      children: [
        // Compact top bar with progress and controls
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
          ),
          child: Column(
            children: [
              // Progress indicator
              Row(
                children: [
                  Text(
                    'Progress: ${session.spotSessions.indexOf(currentSpot) + 1} / ${session.spotSessions.length}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatDuration(_sessionElapsed),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Practice action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _completeSpot(notifier, SpotResult.failed),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Failed'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _completeSpot(notifier, SpotResult.struggled),
                      icon: const Icon(Icons.warning, size: 16),
                      label: const Text('Struggled'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _completeSpot(notifier, SpotResult.good),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Good'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showSolvedSpotDialog(notifier),
                      icon: const Icon(Icons.star, size: 16),
                      label: const Text('Solved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // PDF viewer with spot highlighting
        Expanded(
          child: _buildPDFViewer(currentSpot),
        ),
      ],
    );
  }

  Widget _buildPDFViewer(SpotSession currentSpot) {
    final piecesAsync = ref.watch(unifiedLibraryProvider);
    
    return piecesAsync.when(
      data: (pieces) {
        // Find the piece for the current spot
        Piece? currentPiece;
        try {
          currentPiece = pieces.firstWhere((piece) => 
            piece.spots.any((spot) => spot.id == currentSpot.spotId));
        } catch (e) {
          // Also try searching by piece ID if the spot has one
          try {
            // Look for the piece by matching IDs
            for (final piece in pieces) {
              // Check if any spot in this piece matches our current spot
              for (final spot in piece.spots) {
                if (spot.id == currentSpot.spotId) {
                  currentPiece = piece;
                  break;
                }
              }
              if (currentPiece != null) break;
            }
          } catch (e2) {
            print('Active Practice Session: Could not find piece for spot ${currentSpot.spotId}');
          }
        }
        
        if (currentPiece == null) {
          // If we can't find the specific piece, use the first available piece
          // This ensures practice sessions work even if spot IDs don't match perfectly
          if (pieces.isNotEmpty) {
            currentPiece = pieces.first;
            print('Active Practice Session: Using first available piece "${currentPiece.title}" as fallback');
          } else {
            // No pieces available at all
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_music,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Musical Pieces Available',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Import some musical pieces to start practicing',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
        }
        
        // Find the current spot details - use exact match first, then fallback to first spot
        Spot? currentSpotDetails;
        try {
          currentSpotDetails = currentPiece.spots.firstWhere(
            (spot) => spot.id == currentSpot.spotId,
          );
        } catch (e) {
          // If exact spot not found, use the first available spot as fallback
          if (currentPiece.spots.isNotEmpty) {
            currentSpotDetails = currentPiece.spots.first;
            print('Active Practice Session: Using first available spot "${currentSpotDetails.title}" as fallback');
          } else {
            // Create a default spot if piece has no spots
            currentSpotDetails = Spot(
              id: 'default_spot',
              pieceId: currentPiece.id,
              title: 'Practice Spot',
              description: 'General practice for this piece',
              pageNumber: 1,
              x: 0.5,
              y: 0.5,
              width: 0.2,
              height: 0.15,
              priority: SpotPriority.medium,
              readinessLevel: ReadinessLevel.newSpot,
              color: SpotColor.yellow,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          }
        }
        
        // Display PDF viewer or open full PDF viewer
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(8),
          child: Column(
            children: [
              // PDF header with piece info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.music_note,
                      color: AppColors.getSpotColorByEnum(currentSpotDetails.color),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentPiece.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Spot: ${(currentSpotDetails.description?.isNotEmpty == true) ? currentSpotDetails.description : "Page ${currentSpotDetails.pageNumber}"}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: currentPiece != null ? () => _openFullPDFViewer(currentPiece!, currentSpotDetails) : null,
                      icon: const Icon(Icons.open_in_full, size: 16),
                      label: const Text('Open Score'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                  ],
                ),
              ),
              
              // PDF preview or placeholder
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.picture_as_pdf,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Musical Score Available',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap "Open Score" to view the full sheet music\nwith highlighted practice spots',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading musical score',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Practice Session?'),
        content: const Text('Are you sure you want to exit this practice session? Your session will be saved and the timer will be stopped.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Exit Session'),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _buildSpotInfo(SpotSession spotSession) {
    // For now, create placeholder info based on spot ID
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getSpotColor(spotSession.spotId),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _getSpotName(spotSession.spotId),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Measures: ${_getSpotMeasures(spotSession.spotId)}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Allocated Time: ${_formatDuration(spotSession.allocatedTime)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionComplete(PracticeSession session) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 64,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Session Complete!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Great work! You completed ${session.spotSessions.length} spots in ${_formatDuration(_sessionElapsed)}.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                // Ensure session is completed and saved before clearing
                final notifier = ref.read(activePracticeSessionProvider.notifier);
                await notifier.finishSession();
                Navigator.pop(context);
              },
              child: const Text('Finish Session'),
            ),
          ),
        ],
      ),
    );
  }

  void _openFullPDFViewer(Piece piece, [Spot? currentSpot]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFScoreViewer(
          piece: piece,
          initialPage: currentSpot?.pageNumber,
        ),
      ),
    );
  }

  void _completeSpot(ActivePracticeSessionNotifier notifier, SpotResult result) {
    notifier.completeCurrentSpot(result);
    setState(() {
      _spotElapsed = Duration.zero; // Reset spot timer
    });
  }

  void _showSolvedSpotDialog(ActivePracticeSessionNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Spot Solved'),
        content: const Text('Congratulations! You solved this spot. Do you want to delete it from future practice sessions?'),
        actions: [
          TextButton(
            onPressed: () {
              // Mark as solved but keep the spot
              notifier.completeCurrentSpot(SpotResult.excellent);
              Navigator.pop(context);
            },
            child: const Text('Keep Spot'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Mark as solved and delete the spot
              final currentSpot = ref.read(activePracticeSessionProvider).currentRealSpot;
              
              if (currentSpot != null) {
                try {
                  // Complete the spot first
                  notifier.completeCurrentSpot(SpotResult.excellent);
                  
                  // Delete the spot from the database
                  await ref.read(spotServiceProvider).deleteSpot(currentSpot.id);
                  
                  // Refresh both providers to update the UI
                  ref.read(practiceProvider.notifier).loadPracticeData();
                  ref.read(unifiedLibraryProvider.notifier).refresh();
                  
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Spot deleted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting spot: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No current spot to delete'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Spot', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(ActivePracticeSessionNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Session?'),
        content: const Text('Are you sure you want to cancel this practice session? Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              notifier.cancelSession();
              ref.read(practiceTimerProvider.notifier).stopPracticeSession();
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close practice screen
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Session'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Helper methods to extract info from spot ID (placeholder implementation)
  Color _getSpotColor(String spotId) {
    if (spotId.contains('spot_1') || spotId.contains('spot_2')) return Colors.red;
    if (spotId.contains('spot_0') || spotId.contains('spot_3')) return Colors.orange;
    return Colors.green;
  }

  String _getSpotName(String spotId) {
    if (spotId.contains('spot_0')) return 'Opening';
    if (spotId.contains('spot_1')) return 'Main Theme';
    if (spotId.contains('spot_2')) return 'Development';
    if (spotId.contains('spot_3')) return 'Transition';
    if (spotId.contains('spot_4')) return 'Closing';
    return 'Practice Spot';
  }

  String _getSpotMeasures(String spotId) {
    if (spotId.contains('spot_0')) return '1-8';
    if (spotId.contains('spot_1')) return '9-16';
    if (spotId.contains('spot_2')) return '17-24';
    if (spotId.contains('spot_3')) return '25-32';
    if (spotId.contains('spot_4')) return '33-40';
    return '1-8';
  }

  Widget _buildCompletionScreen(ActivePracticeSessionState practiceState, ActivePracticeSessionNotifier practiceNotifier) {
    final session = practiceState.session!;
    final totalTime = _sessionElapsed;
    final spotsCompleted = practiceState.completedSpots;
    final totalSpots = practiceState.totalSpots;
    
    // Stop the local timer when showing completion screen
    _stopTimer();
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF8B5CF6), // Purple
              Color(0xFF3B82F6), // Blue
              Color(0xFFFFFFFF), // White
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Back Arrow
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        practiceNotifier.finishCompletedSession();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              
              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      
                      // Success Icon with Animation
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.celebration,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Congratulations Text
                      const Text(
                        '🎉 Excellent Work!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Text(
                        'You\'ve completed your practice session!',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Stats Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Session Summary',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatItem(
                                  Icons.timer,
                                  'Time',
                                  '${totalTime.inMinutes}m ${totalTime.inSeconds % 60}s',
                                ),
                                _buildStatItem(
                                  Icons.location_on,
                                  'Spots',
                                  '$spotsCompleted/$totalSpots',
                                ),
                                _buildStatItem(
                                  Icons.trending_up,
                                  'Progress',
                                  '${(practiceState.progress * 100).round()}%',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Motivational Message
                      Container(
                        padding: const EdgeInsets.all(20),
                        constraints: const BoxConstraints(
                          maxHeight: 100, // Reduced height to prevent overflow
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            _getMotivationalMessage(spotsCompleted, totalSpots),
                            style: const TextStyle(
                              fontSize: 14, // Slightly smaller font
                              fontStyle: FontStyle.italic,
                              color: Colors.white,
                              height: 1.3, // Tighter line spacing
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Action Buttons
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                practiceNotifier.finishCompletedSession();
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(Icons.home),
                              label: const Text('Back to Dashboard'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF6C5CE7),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                practiceNotifier.finishCompletedSession();
                                // Start another session - you can implement this
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Practice More'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white, width: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 40), // Bottom padding
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  String _getMotivationalMessage(int completed, int total) {
    if (completed == total) {
      return "Perfect! You've mastered every spot in this session. Your dedication is paying off! 🌟";
    } else if (completed >= total * 0.8) {
      return "Outstanding work! You're building strong muscle memory. Keep up this momentum! 💪";
    } else if (completed >= total * 0.6) {
      return "Great progress! Every practice session brings you closer to mastery. Well done! 🎵";
    } else {
      return "Good start! Remember, consistency is key in music. Every practice counts! 🎹";
    }
  }
}
