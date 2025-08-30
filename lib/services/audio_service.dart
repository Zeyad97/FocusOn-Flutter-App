import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Set up audio player for low latency playback
      await _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
      _isInitialized = true;
    } catch (e) {
      print('Error initializing audio service: $e');
    }
  }

  /// Play a metronome click sound
  Future<void> playMetronomeClick({bool isAccent = false}) async {
    try {
      // Create a new AudioPlayer instance for each click to avoid conflicts
      final clickPlayer = AudioPlayer();
      await clickPlayer.setPlayerMode(PlayerMode.lowLatency);
      
      // Play the actual metronome sound file
      await clickPlayer.play(AssetSource('sounds/metronome-85688.mp3'));
      
      // Clean up the player after playback
      clickPlayer.onPlayerComplete.listen((_) {
        clickPlayer.dispose();
      });
      
      // Add haptic feedback
      if (isAccent) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }
      
    } catch (e) {
      print('Error playing metronome click: $e');
      // Fallback to system sound and haptic feedback
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.lightImpact();
    }
  }

  /// Play break notification sound
  Future<void> playBreakNotification() async {
    try {
      // Create a new AudioPlayer instance for the notification
      final notificationPlayer = AudioPlayer();
      await notificationPlayer.setPlayerMode(PlayerMode.lowLatency);
      
      // Play the break notification sound
      await notificationPlayer.play(AssetSource('sounds/new-notification-07-210334.mp3'));
      
      // Clean up the player after playback
      notificationPlayer.onPlayerComplete.listen((_) {
        notificationPlayer.dispose();
      });
      
      // Add gentle haptic feedback for break notification
      HapticFeedback.mediumImpact();
      
    } catch (e) {
      print('Error playing break notification: $e');
      // Fallback to system sound and haptic feedback
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.mediumImpact();
    }
  }

  /// Generate a simple beep tone
  Future<void> _playBeep(int frequency, int duration) async {
    try {
      // Generate a simple sine wave beep
      // For now, use system click but with different haptic patterns
      // In a real implementation, you would generate audio data
      
      if (frequency > 600) {
        // High pitch - use system click + strong haptic
        SystemSound.play(SystemSoundType.click);
        await Future.delayed(Duration(milliseconds: 10));
        SystemSound.play(SystemSoundType.click);
      } else {
        // Low pitch - use single system click
        SystemSound.play(SystemSoundType.click);
      }
    } catch (e) {
      print('Error generating beep: $e');
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Play a specific audio file (for future use with custom sounds)
  Future<void> playAudioFile(String assetPath) async {
    try {
      if (!_isInitialized) await initialize();
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (e) {
      print('Error playing audio file: $e');
    }
  }

  /// Stop any currently playing audio
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  /// Dispose of resources
  void dispose() {
    _audioPlayer.dispose();
    _isInitialized = false;
  }
}
