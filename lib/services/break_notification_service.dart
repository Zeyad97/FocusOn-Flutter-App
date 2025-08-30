import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'micro_breaks_service.dart';
import 'audio_service.dart';
import '../screens/settings/settings_screen.dart';

// Global navigator key for showing dialogs from anywhere
final navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>((ref) {
  return GlobalKey<NavigatorState>();
});

// Provider for the break notification service
final breakNotificationServiceProvider = Provider<BreakNotificationService>((ref) {
  return BreakNotificationService(ref);
});

class BreakNotificationService {
  final Ref ref;
  final AudioService _audioService = AudioService();

  BreakNotificationService(this.ref);

  void showBreakDialog(Duration breakDuration, int breakNumber) {
    final context = ref.read(navigatorKeyProvider).currentContext;
    if (context == null || !context.mounted) {
      print('🛑 BREAK TIME #$breakNumber! Duration: ${breakDuration.inMinutes} minutes');
      return;
    }

    // Play break notification sound if sound effects are enabled
    final soundEffectsEnabled = ref.read(soundEffectsProvider);
    if (soundEffectsEnabled) {
      _audioService.playBreakNotification();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => BreakNotificationDialog(
        breakDuration: breakDuration,
        breakNumber: breakNumber,
      ),
    );
  }

  void showResumeDialog() {
    final context = ref.read(navigatorKeyProvider).currentContext;
    if (context == null || !context.mounted) {
      print('✅ Break over! Ready to resume practice?');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => const ResumeNotificationDialog(),
    );
  }
}

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
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            Icons.pause_circle_filled,
            color: colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'Break Time #$breakNumber',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time for a ${breakDuration.inMinutes}-minute break!',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getBreakRecommendation(breakNumber),
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Taking regular breaks helps prevent fatigue and improves focus.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Skip break - resume immediately
            ref.read(practiceTimerProvider.notifier).skipBreak();
          },
          child: Text(
            'Skip Break',
            style: TextStyle(color: colorScheme.outline),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Start the break timer
            ref.read(practiceTimerProvider.notifier).startBreak();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          child: const Text('Start Break'),
        ),
      ],
    );
  }

  String _getBreakRecommendation(int breakNumber) {
    switch (breakNumber) {
      case 1:
        return 'Light stretching and eye rest';
      case 2:
        return 'Walk around and hydrate';
      case 3:
        return 'Hand and wrist exercises';
      case 4:
        return 'Step outside for fresh air';
      default:
        return 'Take a proper break: walk, snack, and rest your hands';
    }
  }
}

class ResumeNotificationDialog extends ConsumerWidget {
  const ResumeNotificationDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            Icons.play_circle_filled,
            color: colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'Break Complete',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Ready to continue practicing?',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.successContainer ?? colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.energy_savings_leaf,
                  color: colorScheme.onSuccessContainer ?? colorScheme.onPrimaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You\'re refreshed and ready to focus!',
                    style: TextStyle(
                      color: colorScheme.onSuccessContainer ?? colorScheme.onPrimaryContainer,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Extend break by 2 minutes
            ref.read(practiceTimerProvider.notifier).extendBreakFromResume(
              const Duration(minutes: 2),
            );
          },
          child: Text(
            'Extend Break',
            style: TextStyle(color: colorScheme.outline),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Resume practice session
            ref.read(practiceTimerProvider.notifier).resumePractice();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          child: const Text('Resume Practice'),
        ),
      ],
    );
  }
}

// Extension to add success colors to ColorScheme if not available
extension ColorSchemeExtension on ColorScheme {
  Color? get successContainer => brightness == Brightness.light 
      ? const Color(0xFFE8F5E8) 
      : const Color(0xFF2E4A2E);
  
  Color? get onSuccessContainer => brightness == Brightness.light 
      ? const Color(0xFF0D4A1F) 
      : const Color(0xFFB8E6C1);
}
