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
  Timer? _sessionTimer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _startTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final state = ref.read(activePracticeSessionProvider);
        if (state.hasActiveSession && state.isRunning) {
          setState(() {
            _elapsedSeconds++;
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
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  void _resetTimerState() {
    _stopTimer();
    setState(() {
      _elapsedSeconds = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final practiceState = ref.watch(activePracticeSessionProvider);
    final practiceNotifier = ref.read(activePracticeSessionProvider.notifier);

    if (!practiceState.hasActiveSession) {
      return PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;
          final shouldExit = await _showExitConfirmationDialog();
          if (shouldExit && context.mounted) {
            _resetTimerState();
            ref.read(activePracticeSessionProvider.notifier).clearSession();
            Navigator.of(context).pop();
          }
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Practice Session')),
          body: const Center(child: Text('No active practice session')),
        ),
      );
    }

    final session = practiceState.session!;
    final currentRealSpot = practiceState.currentRealSpot;
    
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldExit = await _showExitConfirmationDialog();
        if (shouldExit && context.mounted) {
          _resetTimerState();
          ref.read(activePracticeSessionProvider.notifier).clearSession();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(session.name),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldExit = await _showExitConfirmationDialog();
              if (shouldExit && context.mounted) {
                _resetTimerState();
                ref.read(activePracticeSessionProvider.notifier).clearSession();
                Navigator.of(context).pop();
              }
            },
          ),
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
              onPressed: () => _showCancelDialog(practiceNotifier),
            ),
          ],
        ),
        body: currentRealSpot != null 
            ? _buildPracticeInterface(session, practiceState, practiceNotifier, currentRealSpot)
            : _buildSessionComplete(),
      ),
    );
  }

  Widget _buildPracticeInterface(
    PracticeSession session,
    ActivePracticeSessionState state,
    ActivePracticeSessionNotifier notifier,
    Spot currentSpot,
  ) {
    return Column(
      children: [
        // Session Progress
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress: ${state.completedSpots}/${state.totalSpots}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    _formatTime(_elapsedSeconds),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: state.progress,
                backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Spot Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getSpotColor(currentSpot.color),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                currentSpot.title,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                          ],
                        ),
                        if (currentSpot.description != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            currentSpot.description!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildInfoChip('Page ${currentSpot.pageNumber}', Icons.book),
                            const SizedBox(width: 8),
                            _buildInfoChip('${currentSpot.recommendedPracticeTime} min', Icons.timer),
                            const SizedBox(width: 8),
                            _buildInfoChip(currentSpot.priority.displayName, Icons.priority_high),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Practice Stats
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Practice Statistics',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn(
                              'Total Sessions', 
                              '${currentSpot.practiceCount}',
                              Icons.history,
                            ),
                            _buildStatColumn(
                              'Success Rate', 
                              currentSpot.practiceCount > 0 
                                ? '${((currentSpot.successCount / currentSpot.practiceCount) * 100).round()}%'
                                : '0%',
                              Icons.trending_up,
                            ),
                            _buildStatColumn(
                              'Readiness', 
                              currentSpot.readinessLevel.displayName,
                              Icons.psychology,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildResultButton(
                      'Struggled',
                      SpotResult.struggled,
                      Colors.red,
                      Icons.thumb_down,
                      notifier,
                    ),
                    _buildResultButton(
                      'Good',
                      SpotResult.good,
                      Colors.orange,
                      Icons.thumb_up,
                      notifier,
                    ),
                    _buildResultButton(
                      'Excellent',
                      SpotResult.excellent,
                      Colors.green,
                      Icons.star,
                      notifier,
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Skip button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _completeSpot(notifier, SpotResult.failed),
                    child: const Text('Skip This Spot'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionComplete() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 64, color: Colors.green),
          SizedBox(height: 16),
          Text('Practice Session Complete!', style: TextStyle(fontSize: 24)),
          SizedBox(height: 8),
          Text('Great job on your practice session!'),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onPrimaryContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildResultButton(
    String label,
    SpotResult result,
    Color color,
    IconData icon,
    ActivePracticeSessionNotifier notifier,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () => _completeSpot(notifier, result),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSpotColor(SpotColor spotColor) {
    switch (spotColor) {
      case SpotColor.red:
        return Colors.red;
      case SpotColor.yellow:
        return Colors.orange;
      case SpotColor.green:
        return Colors.green;
      case SpotColor.blue:
        return Colors.blue;
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _completeSpot(ActivePracticeSessionNotifier notifier, SpotResult result) {
    notifier.completeCurrentSpot(result);
  }

  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Practice Session?'),
        content: const Text('Are you sure you want to exit this practice session? Your session timer will be stopped and reset.'),
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

  void _showCancelDialog(ActivePracticeSessionNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Practice Session'),
        content: const Text('Are you sure you want to end this practice session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              notifier.cancelSession();
              Navigator.of(context).pop();
            },
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }
}
