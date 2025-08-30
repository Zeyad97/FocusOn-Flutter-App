import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/practice_session_provider.dart';
import '../../theme/app_theme.dart';

class PracticeSessionScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String projectName;
  final String practiceType;

  const PracticeSessionScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.practiceType,
  });

  @override
  ConsumerState<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends ConsumerState<PracticeSessionScreen> {
  bool _isSessionActive = false;
  Duration _sessionDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startPracticeSession();
  }

  void _startPracticeSession() async {
    await ref.read(practiceSessionProvider.notifier).startSession(
      widget.projectId,
      widget.projectName,
      widget.practiceType,
    );
    setState(() {
      _isSessionActive = true;
    });
  }

  void _endPracticeSession() async {
    await ref.read(practiceSessionProvider.notifier).endSession();
    setState(() {
      _isSessionActive = false;
    });
    if (mounted) {
      _showPracticeResultDialog();
    }
  }

  void _showPracticeResultDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How Did Practice Go?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildResultButton(
              'Failed', 
              Icons.sentiment_very_dissatisfied, 
              Colors.red,
              () => _handlePracticeResult('failed'),
            ),
            const SizedBox(height: 8),
            _buildResultButton(
              'Struggled', 
              Icons.sentiment_dissatisfied, 
              AppColors.warningYellow,
              () => _handlePracticeResult('struggled'),
            ),
            const SizedBox(height: 8),
            _buildResultButton(
              'Good', 
              Icons.sentiment_satisfied, 
              Colors.green,
              () => _handlePracticeResult('good'),
            ),
            const SizedBox(height: 8),
            _buildResultButton(
              'Solved', 
              Icons.check_circle, 
              Colors.green.shade700,
              () => _handlePracticeResult('solved'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  void _handlePracticeResult(String result) {
    Navigator.pop(context);
    Navigator.pop(context);

    if (result == 'solved') {
      _showSpotDeletionDialog();
    } else {
      Color bgColor = AppColors.successGreen;
      if (result == 'failed') bgColor = AppColors.errorRed;
      else if (result == 'struggled') bgColor = AppColors.warningYellow;
      else if (result == 'good') bgColor = AppColors.successGreen;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Practice marked as $result'),
          backgroundColor: bgColor,
        ),
      );
    }
  }

  void _showSpotDeletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Spot Solved'),
        content: const Text('Do you want to delete this spot from future practice sessions?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement actual spot deletion logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Spot deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Spot'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(practiceSessionProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Practice Session'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        actions: [
          if (_isSessionActive)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _endPracticeSession,
              tooltip: 'End Session',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.primaryContainer.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.music_note,
                        color: colorScheme.onPrimaryContainer,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.projectName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.practiceType,
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Session Status
            if (session != null) ...[
              Text(
                'Session Active',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Session Timer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.timer,
                      size: 48,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<Duration>(
                      stream: Stream.periodic(const Duration(seconds: 1), (count) {
                        final startTime = session.startTime;
                        return DateTime.now().difference(startTime);
                      }),
                      builder: (context, snapshot) {
                        final duration = snapshot.data ?? Duration.zero;
                        final minutes = duration.inMinutes;
                        final seconds = duration.inSeconds % 60;
                        
                        return Text(
                          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 48,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Practice Time',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Practice Tools
              Text(
                'Practice Tools',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildToolCard(
                      context,
                      icon: Icons.bookmark_add,
                      title: 'Add Bookmark',
                      subtitle: 'Mark important sections',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Bookmark added!')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildToolCard(
                      context,
                      icon: Icons.note_add,
                      title: 'Add Note',
                      subtitle: 'Record practice notes',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Note added!')),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // End Session Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _endPracticeSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.stop),
                      const SizedBox(width: 8),
                      const Text(
                        'End Practice Session',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.music_off,
                      size: 64,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No active practice session',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: colorScheme.primary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
