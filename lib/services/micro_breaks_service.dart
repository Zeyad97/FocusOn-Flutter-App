import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_settings_provider.dart';

// Provider for the micro-breaks service
final microBreaksServiceProvider = Provider<MicroBreaksService>((ref) {
  return MicroBreaksService(ref);
});

// Provider for the current practice timer state
final practiceTimerProvider = StateNotifierProvider<PracticeTimerNotifier, PracticeTimerState>((ref) {
  return PracticeTimerNotifier(ref);
});

class PracticeTimerState {
  final Duration sessionDuration;
  final Duration timeUntilBreak;
  final bool isOnBreak;
  final bool isRunning;
  final int breakCount;

  const PracticeTimerState({
    this.sessionDuration = Duration.zero,
    this.timeUntilBreak = Duration.zero,
    this.isOnBreak = false,
    this.isRunning = false,
    this.breakCount = 0,
  });

  PracticeTimerState copyWith({
    Duration? sessionDuration,
    Duration? timeUntilBreak,
    bool? isOnBreak,
    bool? isRunning,
    int? breakCount,
  }) {
    return PracticeTimerState(
      sessionDuration: sessionDuration ?? this.sessionDuration,
      timeUntilBreak: timeUntilBreak ?? this.timeUntilBreak,
      isOnBreak: isOnBreak ?? this.isOnBreak,
      isRunning: isRunning ?? this.isRunning,
      breakCount: breakCount ?? this.breakCount,
    );
  }
}

class PracticeTimerNotifier extends StateNotifier<PracticeTimerState> {
  final Ref ref;
  Timer? _timer;
  late Duration _breakInterval;
  late Duration _breakDuration;

  PracticeTimerNotifier(this.ref) : super(const PracticeTimerState()) {
    _updateSettings();
  }

  void _updateSettings() {
    final settings = ref.read(appSettingsProvider);
    _breakInterval = Duration(minutes: settings.microBreakInterval.round());
    _breakDuration = Duration(minutes: settings.microBreakDuration.round());
  }

  void startPracticeSession() {
    if (!ref.read(appSettingsProvider).microBreaksEnabled) {
      // Just track time without breaks
      _startSimpleTimer();
      return;
    }

    _updateSettings();
    state = state.copyWith(
      isRunning: true,
      timeUntilBreak: _breakInterval,
      isOnBreak: false,
    );

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), _onTimerTick);
  }

  void _startSimpleTimer() {
    state = state.copyWith(isRunning: true);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(
        sessionDuration: Duration(seconds: state.sessionDuration.inSeconds + 1),
      );
    });
  }

  void _onTimerTick(Timer timer) {
    if (state.isOnBreak) {
      // During break, countdown break duration
      final remainingBreak = Duration(
        seconds: state.timeUntilBreak.inSeconds - 1,
      );
      
      if (remainingBreak <= Duration.zero) {
        // Break is over, resume practice
        _resumeFromBreak();
      } else {
        state = state.copyWith(timeUntilBreak: remainingBreak);
      }
    } else {
      // During practice, countdown to next break and track total time
      final newSessionDuration = Duration(
        seconds: state.sessionDuration.inSeconds + 1,
      );
      final newTimeUntilBreak = Duration(
        seconds: state.timeUntilBreak.inSeconds - 1,
      );

      if (newTimeUntilBreak <= Duration.zero) {
        // Time for a break!
        _startBreak();
      } else {
        state = state.copyWith(
          sessionDuration: newSessionDuration,
          timeUntilBreak: newTimeUntilBreak,
        );
      }
    }
  }

  void _startBreak() {
    state = state.copyWith(
      isOnBreak: true,
      timeUntilBreak: _breakDuration,
      breakCount: state.breakCount + 1,
    );
    
    // Show break notification
    ref.read(microBreaksServiceProvider).showBreakNotification(
      _breakDuration,
      state.breakCount,
    );
  }

  void _resumeFromBreak() {
    state = state.copyWith(
      isOnBreak: false,
      timeUntilBreak: _breakInterval,
    );
    
    ref.read(microBreaksServiceProvider).showResumeNotification();
  }

  void pausePracticeSession() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void stopPracticeSession() {
    _timer?.cancel();
    state = const PracticeTimerState();
  }

  void skipBreak() {
    if (state.isOnBreak) {
      _resumeFromBreak();
    }
  }

  void extendBreak(Duration extension) {
    if (state.isOnBreak) {
      state = state.copyWith(
        timeUntilBreak: Duration(
          seconds: state.timeUntilBreak.inSeconds + extension.inSeconds,
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class MicroBreaksService {
  final Ref ref;

  MicroBreaksService(this.ref);

  void showBreakNotification(Duration breakDuration, int breakNumber) {
    // This would show a dialog or notification
    // For now, we'll just print (in a real app, use a notification system)
    print('🛑 Time for break #$breakNumber! Duration: ${breakDuration.inMinutes} minutes');
  }

  void showResumeNotification() {
    print('✅ Break over! Ready to resume practice?');
  }

  // Helper to format duration for display
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Get break recommendations based on practice intensity
  String getBreakRecommendation(Duration sessionLength, int breaksTaken) {
    if (sessionLength.inMinutes < 30) {
      return 'Light stretching and eye rest';
    } else if (sessionLength.inMinutes < 60) {
      return 'Walk around, hydrate, and stretch';
    } else {
      return 'Take a proper break: walk, snack, and rest your hands';
    }
  }

  // Calculate optimal break frequency based on user profile
  Duration getOptimalBreakInterval(String learningProfile) {
    switch (learningProfile) {
      case 'Conservatory':
        return const Duration(minutes: 20); // Intensive practice
      case 'Advanced':
        return const Duration(minutes: 25); // Focused sessions
      case 'Standard':
      default:
        return const Duration(minutes: 30); // Balanced approach
    }
  }
}
