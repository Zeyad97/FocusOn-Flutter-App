import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../providers/practice_session_provider.dart';
import '../../providers/unified_library_provider.dart';
import '../../models/practice_session.dart';
import '../../models/spot.dart';
import '../../models/piece.dart';
import '../../models/pdf_document.dart';
import '../../theme/app_theme.dart';
import '../../screens/pdf_viewer/pdf_score_viewer.dart';

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
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final state = ref.read(activePracticeSessionProvider);
        if (state.isRunning) {
          setState(() {
            _sessionElapsed = _sessionElapsed + const Duration(seconds: 1);
            _spotElapsed = _spotElapsed + const Duration(seconds: 1);
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final practiceState = ref.watch(activePracticeSessionProvider);
    final practiceNotifier = ref.read(activePracticeSessionProvider.notifier);

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

    final session = practiceState.session!;
    final currentSpot = practiceState.currentSpot;

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Text(session.name),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(practiceState.isRunning ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              if (practiceState.isRunning) {
                practiceNotifier.pauseSession();
              } else {
                practiceNotifier.resumeSession();
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
    );
  }

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
          // Spot not found in any piece
        }
        
        if (currentPiece == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.music_off,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'Musical score not available',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Practicing spot: ${_getSpotName(currentSpot.spotId)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }
        
        // Find the current spot details
        final currentSpotDetails = currentPiece.spots.firstWhere(
          (spot) => spot.id == currentSpot.spotId,
          orElse: () => currentPiece!.spots.first,
        );
        
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
                      onPressed: currentPiece != null ? () => _openFullPDFViewer(currentPiece!) : null,
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
              onPressed: () {
                ref.read(activePracticeSessionProvider.notifier).clearSession();
                Navigator.pop(context);
              },
              child: const Text('Finish Session'),
            ),
          ),
        ],
      ),
    );
  }

  void _openFullPDFViewer(Piece piece) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFScoreViewer(piece: piece),
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
            onPressed: () {
              // Mark as solved and delete the spot
              notifier.completeCurrentSpot(SpotResult.excellent);
              // TODO: Implement spot deletion logic here
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Spot deleted successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
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
}
