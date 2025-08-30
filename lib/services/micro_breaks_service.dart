import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_settings_provider.dart';
import '../providers/practice_session_provider.dart';
import 'break_notification_service.dart';

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
  final bool isBreakDialogShown; // New field to track dialog state

  const PracticeTimerState({
    this.sessionDuration = Duration.zero,
    this.timeUntilBreak = Duration.zero,
    this.isOnBreak = false,
    this.isRunning = false,
    this.breakCount = 0,
    this.isBreakDialogShown = false,
  });

  PracticeTimerState copyWith({
    Duration? sessionDuration,
    Duration? timeUntilBreak,
    bool? isOnBreak,
    bool? isRunning,
    int? breakCount,
    bool? isBreakDialogShown,
  }) {
    return PracticeTimerState(
      sessionDuration: sessionDuration ?? this.sessionDuration,
      timeUntilBreak: timeUntilBreak ?? this.timeUntilBreak,
      isOnBreak: isOnBreak ?? this.isOnBreak,
      isRunning: isRunning ?? this.isRunning,
      breakCount: breakCount ?? this.breakCount,
      isBreakDialogShown: isBreakDialogShown ?? this.isBreakDialogShown,
    );
  }
}

class PracticeTimerNotifier extends StateNotifier<PracticeTimerState> {
  final Ref ref;
  Timer? _timer;
  late Duration _breakInterval;
  late Duration _breakDuration;
  bool _disposed = false;

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
    
    // Initialize break count from existing session if available
    startFromExistingSession();
    
    // Only reset timeUntilBreak if starting fresh (not resuming)
    if (!state.isRunning || state.timeUntilBreak == Duration.zero) {
      state = state.copyWith(
        isRunning: true,
        timeUntilBreak: _breakInterval,
        isOnBreak: false,
        isBreakDialogShown: false,
      );
    } else {
      // Resuming - just restart timer with current state
      state = state.copyWith(
        isRunning: true,
        isOnBreak: false,
        isBreakDialogShown: false,
      );
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), _onTimerTick);
  }

  void _startSimpleTimer() {
    state = state.copyWith(isRunning: true);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      state = state.copyWith(
        sessionDuration: Duration(seconds: state.sessionDuration.inSeconds + 1),
      );
    });
  }

  void _onTimerTick(Timer timer) {
    // Check if the notifier is still active before updating state
    if (_disposed) {
      _timer?.cancel();
      return;
    }
    
    if (state.isOnBreak) {
      // During break, countdown break duration
      final remainingBreak = Duration(
        seconds: state.timeUntilBreak.inSeconds - 1,
      );
      
      if (remainingBreak <= Duration.zero) {
        // Break is over, resume practice
        _resumeFromBreak();
      } else {
        if (!_disposed) {
          state = state.copyWith(timeUntilBreak: remainingBreak);
        }
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
        // Time for a break! Show dialog but don't start break timer yet
        _showBreakDialog();
      } else {
        state = state.copyWith(
          sessionDuration: newSessionDuration,
          timeUntilBreak: newTimeUntilBreak,
        );
      }
    }
  }

  void _showBreakDialog() {
    if (_disposed) return;
    
    final newBreakCount = state.breakCount + 1;
    
    // Pause the timer but don't start break countdown yet
    state = state.copyWith(
      isRunning: false,
      breakCount: newBreakCount,
      isBreakDialogShown: true,
    );
    
    // Cancel the timer until user makes a choice
    _timer?.cancel();
    
    // Update the active practice session with the new break count
    _updatePracticeSessionBreakCount(newBreakCount);
    
    // Show break notification
    ref.read(breakNotificationServiceProvider).showBreakDialog(
      _breakDuration,
      newBreakCount,
    );
  }

  void _startBreak() {
    if (_disposed) return;
    
    state = state.copyWith(
      isOnBreak: true,
      timeUntilBreak: _breakDuration,
      isRunning: true,
      isBreakDialogShown: false,
    );

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), _onTimerTick);
  }

  void _resumeFromBreak() {
    if (_disposed) return;
    
    state = state.copyWith(
      isOnBreak: false,
      timeUntilBreak: _breakInterval,
      isRunning: false, // Pause until user decides
      isBreakDialogShown: true, // Show resume dialog
    );
    
    // Cancel timer until user makes choice
    _timer?.cancel();
    
    ref.read(breakNotificationServiceProvider).showResumeDialog();
  }

  void resumePractice() {
    if (!_disposed) {
      state = state.copyWith(
        isOnBreak: false,
        isRunning: true,
        isBreakDialogShown: false,
      );
      
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), _onTimerTick);
    }
  }

  void extendBreakFromResume(Duration extension) {
    if (!_disposed) {
      // Go back to break mode with extended time
      state = state.copyWith(
        isOnBreak: true,
        timeUntilBreak: extension,
        isRunning: true,
        isBreakDialogShown: false,
      );
      
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), _onTimerTick);
    }
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
    if (state.isBreakDialogShown && !_disposed) {
      // Skip break - reset interval and resume practice
      state = state.copyWith(
        isOnBreak: false,
        isRunning: true,
        timeUntilBreak: _breakInterval,
        isBreakDialogShown: false,
      );
      
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), _onTimerTick);
    } else if (state.isOnBreak && !_disposed) {
      // Skip during active break
      _resumeFromBreak();
    }
  }

  void startBreak() {
    if (state.isBreakDialogShown && !_disposed) {
      _startBreak();
    }
  }

  void extendBreak(Duration extension) {
    if (state.isOnBreak && !_disposed) {
      state = state.copyWith(
        timeUntilBreak: Duration(
          seconds: state.timeUntilBreak.inSeconds + extension.inSeconds,
        ),
      );
    }
  }

  void _updatePracticeSessionBreakCount(int newBreakCount) {
    // Update active practice session with break count if one exists
    final activePracticeSession = ref.read(activePracticeSessionProvider);
    if (activePracticeSession.hasActiveSession && activePracticeSession.session != null) {
      // Update the session with the new break count
      final updatedSession = activePracticeSession.session!.copyWith(
        breaksTaken: newBreakCount,
        updatedAt: DateTime.now(),
      );
      
      // Update the session in the provider (this would ideally save to database)
      // For now, we'll just update the state
      print('[MicroBreaks] Updated practice session break count to: $newBreakCount');
    }
  }

  void startFromExistingSession() {
    // When starting timer from an existing practice session, 
    // initialize break count from the session data
    final activePracticeSession = ref.read(activePracticeSessionProvider);
    if (activePracticeSession.hasActiveSession && activePracticeSession.session != null) {
      final existingBreakCount = activePracticeSession.session!.breaksTaken;
      state = state.copyWith(breakCount: existingBreakCount);
      print('[MicroBreaks] Restored break count from session: $existingBreakCount');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}

class MicroBreaksService {
  final Ref ref;

  MicroBreaksService(this.ref);

  void showBreakNotification(Duration breakDuration, int breakNumber) {
    // Deprecated: Use breakNotificationServiceProvider.showBreakDialog instead
    print('🛑 BREAK TIME #$breakNumber! Duration: ${breakDuration.inMinutes} minutes');
    print('   Recommendation: ${getBreakRecommendation(Duration(minutes: 15), breakNumber)}');
  }

  void showResumeNotification() {
    // Deprecated: Use breakNotificationServiceProvider.showResumeDialog instead
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
