import 'package:flutter/material.dart';
import 'dart:async';
import '../../../models/piece.dart';
import '../../../models/spot.dart';
import '../../../theme/app_theme.dart';

/// Practice session dialog for tracking focused practice time
class PracticeSessionDialog extends StatefulWidget {
  final Piece piece;
  final List<Spot> selectedSpots;
  final Function(Duration, List<Spot>) onSessionComplete;

  const PracticeSessionDialog({
    super.key,
    required this.piece,
    required this.selectedSpots,
    required this.onSessionComplete,
  });

  @override
  State<PracticeSessionDialog> createState() => _PracticeSessionDialogState();
}

class _PracticeSessionDialogState extends State<PracticeSessionDialog> {
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;
  bool _isRunning = false;
  final _notesController = TextEditingController();
  List<Spot> _practiceSpots = [];

  @override
  void initState() {
    super.initState();
    _practiceSpots = List.from(widget.selectedSpots);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime = Duration(seconds: _elapsedTime.inSeconds + 1);
      });
    });
  }

  void _pauseTimer() {
    setState(() => _isRunning = false);
    _timer?.cancel();
  }

  void _resetTimer() {
    setState(() {
      _isRunning = false;
      _elapsedTime = Duration.zero;
    });
    _timer?.cancel();
  }

  void _completeSession() {
    _timer?.cancel();
    widget.onSessionComplete(_elapsedTime, _practiceSpots);
    Navigator.of(context).pop();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.timer,
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Practice Session',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.piece.title,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Timer display
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatDuration(_elapsedTime),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Timer controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                  icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(_isRunning ? 'Pause' : 'Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRunning ? AppColors.warningOrange : AppColors.successGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _resetTimer,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Practice spots
            if (_practiceSpots.isNotEmpty) ...[
              const Text(
                'Practice Spots',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _practiceSpots.length,
                  itemBuilder: (context, index) {
                    final spot = _practiceSpots[index];
                    return ListTile(
                      dense: true,
                      leading: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getSpotColor(spot.readinessLevel),
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(spot.title),
                      subtitle: Text('Page ${spot.page}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          setState(() {
                            _practiceSpots.removeAt(index);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Session notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Session Notes',
                hintText: 'What did you work on? Any insights?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _elapsedTime.inSeconds > 0 ? _completeSession : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Complete Session'),
                  ),
                ),
              ],
            ),
            
            // Quick stats
            if (_elapsedTime.inSeconds > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: 'Spots',
                      value: '${_practiceSpots.length}',
                    ),
                    _StatItem(
                      label: 'Avg/Spot',
                      value: _practiceSpots.isNotEmpty
                          ? _formatDuration(Duration(
                              seconds: _elapsedTime.inSeconds ~/ _practiceSpots.length))
                          : '0:00',
                    ),
                    _StatItem(
                      label: 'Efficiency',
                      value: _calculateEfficiency(),
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

  Color _getSpotColor(ReadinessLevel level) {
    switch (level) {
      case ReadinessLevel.needsWork:
        return AppColors.errorRed;
      case ReadinessLevel.improving:
        return AppColors.warningOrange;
      case ReadinessLevel.almostReady:
        return AppColors.warningYellow;
      case ReadinessLevel.performance:
        return AppColors.successGreen;
    }
  }

  String _calculateEfficiency() {
    if (_elapsedTime.inMinutes < 5) return 'Good';
    if (_elapsedTime.inMinutes < 15) return 'Great';
    return 'Excellent';
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
