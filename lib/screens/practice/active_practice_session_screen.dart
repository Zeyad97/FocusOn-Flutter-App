import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../providers/practice_session_provider.dart';
import '../../models/practice_session.dart';
import '../../models/spot.dart';

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
      appBar: AppBar(
        title: Text(session.name),
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
      body: currentSpot == null 
        ? _buildSessionComplete(session)
        : _buildPracticeInterface(session, currentSpot, practiceNotifier),
    );
  }

  Widget _buildPracticeInterface(PracticeSession session, SpotSession currentSpot, ActivePracticeSessionNotifier notifier) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = (session.spotSessions.indexOf(currentSpot) + 1) / session.spotSessions.length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress indicator
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${session.spotSessions.indexOf(currentSpot) + 1} / ${session.spotSessions.length}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Time display
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Session Time',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDuration(_sessionElapsed),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Current Spot',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDuration(_spotElapsed),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Current spot info
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Current Spot',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Spot details (we'll need to get these from the spot ID)
                    _buildSpotInfo(currentSpot),
                    
                    const Spacer(),
                    
                    // Practice instructions
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Practice Instructions:',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Focus on accuracy and clean technique. Practice slowly first, then gradually increase tempo.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Action buttons - How did this spot go?
                    Text(
                      'How did this practice spot go?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 2x2 Grid of result buttons
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildResultButton(
                                context,
                                SpotResult.failed,
                                Icons.close,
                                Colors.red,
                                'Need more work',
                                () => _completeSpot(notifier, SpotResult.failed),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildResultButton(
                                context,
                                SpotResult.struggled,
                                Icons.sentiment_dissatisfied,
                                Colors.orange,
                                'Some difficulties',
                                () => _completeSpot(notifier, SpotResult.struggled),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildResultButton(
                                context,
                                SpotResult.good,
                                Icons.sentiment_satisfied,
                                Colors.blue,
                                'Went well',
                                () => _completeSpot(notifier, SpotResult.good),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildResultButton(
                                context,
                                SpotResult.excellent,
                                Icons.star,
                                Colors.green,
                                'Nailed it!',
                                () => _completeSpot(notifier, SpotResult.excellent),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Session controls
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showCancelDialog(notifier),
                            icon: const Icon(Icons.close),
                            label: const Text('Cancel Session'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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

  void _completeSpot(ActivePracticeSessionNotifier notifier, SpotResult result) {
    notifier.completeCurrentSpot(result);
    setState(() {
      _spotElapsed = Duration.zero; // Reset spot timer
    });
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

  Widget _buildResultButton(
    BuildContext context,
    SpotResult result,
    IconData icon,
    Color color,
    String subtitle,
    VoidCallback onPressed,
  ) {
    return Container(
      height: 80,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withOpacity(0.3)),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(
              result.displayName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
