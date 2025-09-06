import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/micro_breaks_service.dart';
import '../services/learning_system_service.dart';
import '../services/database_service.dart';
import '../providers/app_settings_provider.dart';
import '../providers/practice_session_provider.dart';
import '../theme/app_theme.dart';

// Provider for today's break statistics
final todayBreakStatsProvider = FutureProvider<int>((ref) async {
  final database = ref.read(databaseServiceProvider);
  final sessions = await database.getTodayPracticeSessions();
  
  // Sum up breaks taken from all today's sessions
  int totalBreaks = 0;
  for (final session in sessions) {
    totalBreaks += 0; // breaks_taken field removed
  }
  
  // Add current session breaks if active
  final activeSession = ref.read(activePracticeSessionProvider);
  if (activeSession.hasActiveSession && activeSession.session != null) {
    totalBreaks += 0; // breaks_taken field removed
  }
  
  return totalBreaks;
});

class PracticeSessionWidget extends ConsumerWidget {
  const PracticeSessionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(practiceTimerProvider);
    final settings = ref.watch(appSettingsProvider);
    final todayBreaksAsync = ref.watch(todayBreakStatsProvider);
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timer,
                  color: AppColors.primaryPurple,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Practice Session',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (timerState.isRunning && settings.microBreaksEnabled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: timerState.isOnBreak 
                          ? Colors.orange.withOpacity(0.2)
                          : AppColors.primaryPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      timerState.isOnBreak ? 'ON BREAK' : 'PRACTICING',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: timerState.isOnBreak ? Colors.orange : AppColors.primaryPurple,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Timer Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryPurple.withOpacity(0.1),
                    AppColors.accentPurple.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryPurple.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Session Time',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    MicroBreaksService.formatDuration(timerState.sessionDuration),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                  if (settings.microBreaksEnabled) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTimerStat(
                          'Next Break',
                          timerState.isOnBreak 
                              ? 'Break ends in ${MicroBreaksService.formatDuration(timerState.timeUntilBreak)}'
                              : MicroBreaksService.formatDuration(timerState.timeUntilBreak),
                          timerState.isOnBreak ? Colors.orange : AppColors.primaryPurple,
                        ),
                        _buildTimerStat(
                          'Breaks Taken',
                          todayBreaksAsync.when(
                            data: (breakCount) => '$breakCount',
                            loading: () => '${timerState.breakCount}',
                            error: (_, __) => '${timerState.breakCount}',
                          ),
                          AppColors.accentPurple,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Control Buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: timerState.isRunning 
                        ? () => ref.read(practiceTimerProvider.notifier).pausePracticeSession()
                        : () => ref.read(practiceTimerProvider.notifier).startPracticeSession(),
                    icon: Icon(timerState.isRunning ? Icons.pause : Icons.play_arrow),
                    label: Text(timerState.isRunning ? 'Pause' : 'Start Practice'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: timerState.sessionDuration > Duration.zero
                      ? () => ref.read(practiceTimerProvider.notifier).stopPracticeSession()
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                  child: const Icon(Icons.stop),
                ),
              ],
            ),
            
            // Break Controls (only show during break)
            if (timerState.isOnBreak) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => ref.read(practiceTimerProvider.notifier).skipBreak(),
                      icon: const Icon(Icons.skip_next),
                      label: const Text('Skip Break'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => ref.read(practiceTimerProvider.notifier)
                          .extendBreak(const Duration(minutes: 2)),
                      icon: const Icon(Icons.add),
                      label: const Text('+2 min'),
                    ),
                  ),
                ],
              ),
            ],
            
            // Settings Summary
            if (settings.microBreaksEnabled) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Break Settings',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Every ${settings.microBreakInterval.round()} min → ${settings.microBreakDuration.round()} min break',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
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

  Widget _buildTimerStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// Widget to show break notification dialog
class BreakNotificationDialog extends ConsumerWidget {
  final Duration breakDuration;
  final int breakNumber;

  const BreakNotificationDialog({
    super.key,
    required this.breakDuration,
    required this.breakNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.pause_circle, color: Colors.orange),
          const SizedBox(width: 8),
          Text('Break Time #$breakNumber'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Time for a ${breakDuration.inMinutes}-minute break!',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Text(
            'Take this time to:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text('• Stretch your hands and fingers'),
          const Text('• Rest your eyes'),
          const Text('• Take a few deep breaths'),
          const Text('• Stay hydrated'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            ref.read(practiceTimerProvider.notifier).skipBreak();
          },
          child: const Text('Skip Break'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Take Break'),
        ),
      ],
    );
  }
}
