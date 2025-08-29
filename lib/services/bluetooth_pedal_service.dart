import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service for handling Bluetooth pedal input for page turning
class BluetoothPedalService {
  static final BluetoothPedalService _instance = BluetoothPedalService._internal();
  factory BluetoothPedalService() => _instance;
  BluetoothPedalService._internal();

  // Callback functions for page navigation
  VoidCallback? _onNextPage;
  VoidCallback? _onPreviousPage;
  VoidCallback? _onToggleFullscreen;

  bool _isListening = false;

  /// Start listening for Bluetooth pedal input
  void startListening({
    VoidCallback? onNextPage,
    VoidCallback? onPreviousPage,
    VoidCallback? onToggleFullscreen,
  }) {
    if (_isListening) return;

    _onNextPage = onNextPage;
    _onPreviousPage = onPreviousPage;
    _onToggleFullscreen = onToggleFullscreen;

    // Listen for raw keyboard events (many Bluetooth pedals send keyboard events)
    RawKeyboard.instance.addListener(_handleKeyEvent);
    _isListening = true;
    
    print('BluetoothPedalService: Started listening for pedal input');
  }

  /// Stop listening for Bluetooth pedal input
  void stopListening() {
    if (!_isListening) return;

    RawKeyboard.instance.removeListener(_handleKeyEvent);
    _isListening = false;
    
    _onNextPage = null;
    _onPreviousPage = null;
    _onToggleFullscreen = null;
    
    print('BluetoothPedalService: Stopped listening for pedal input');
  }

  /// Handle raw keyboard events from Bluetooth pedals
  void _handleKeyEvent(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return; // Only respond to key down events

    // Common Bluetooth pedal key mappings
    switch (event.logicalKey) {
      // Page Down / Right Arrow / Space = Next Page
      case LogicalKeyboardKey.pageDown:
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.space:
        print('BluetoothPedalService: Next page triggered');
        _onNextPage?.call();
        break;

      // Page Up / Left Arrow / Backspace = Previous Page  
      case LogicalKeyboardKey.pageUp:
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.backspace:
        print('BluetoothPedalService: Previous page triggered');
        _onPreviousPage?.call();
        break;

      // Enter / Escape = Toggle fullscreen
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.escape:
        print('BluetoothPedalService: Toggle fullscreen triggered');
        _onToggleFullscreen?.call();
        break;

      // F1-F12 keys (common on programmable pedals)
      case LogicalKeyboardKey.f1:
      case LogicalKeyboardKey.f2:
        _onNextPage?.call();
        break;

      case LogicalKeyboardKey.f3:
      case LogicalKeyboardKey.f4:
        _onPreviousPage?.call();
        break;

      case LogicalKeyboardKey.f5:
        _onToggleFullscreen?.call();
        break;

      default:
        // Log unhandled keys for debugging
        print('BluetoothPedalService: Unhandled key: ${event.logicalKey}');
        break;
    }
  }

  /// Check if service is currently listening
  bool get isListening => _isListening;

  /// Get supported key mappings for user reference
  static Map<String, List<String>> get supportedKeyMappings => {
    'Next Page': [
      'Page Down',
      'Right Arrow', 
      'Space Bar',
      'F1',
      'F2'
    ],
    'Previous Page': [
      'Page Up',
      'Left Arrow',
      'Backspace', 
      'F3',
      'F4'
    ],
    'Toggle Fullscreen': [
      'Enter',
      'Escape',
      'F5'
    ],
  };
}

/// Provider for Bluetooth pedal service
final bluetoothPedalServiceProvider = Provider<BluetoothPedalService>((ref) {
  return BluetoothPedalService();
});

/// Settings provider for Bluetooth pedal configuration
class BluetoothPedalSettings {
  final bool isEnabled;
  final Map<String, String> keyMappings;
  final bool hapticFeedback;
  final bool audioFeedback;

  const BluetoothPedalSettings({
    this.isEnabled = false,
    this.keyMappings = const {
      'nextPage': 'pageDown',
      'previousPage': 'pageUp', 
      'toggleFullscreen': 'escape',
    },
    this.hapticFeedback = true,
    this.audioFeedback = false,
  });

  BluetoothPedalSettings copyWith({
    bool? isEnabled,
    Map<String, String>? keyMappings,
    bool? hapticFeedback,
    bool? audioFeedback,
  }) {
    return BluetoothPedalSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      keyMappings: keyMappings ?? this.keyMappings,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      audioFeedback: audioFeedback ?? this.audioFeedback,
    );
  }
}

/// State notifier for Bluetooth pedal settings
class BluetoothPedalSettingsNotifier extends StateNotifier<BluetoothPedalSettings> {
  BluetoothPedalSettingsNotifier() : super(const BluetoothPedalSettings());

  void toggleEnabled() {
    state = state.copyWith(isEnabled: !state.isEnabled);
  }

  void updateKeyMapping(String action, String key) {
    final newMappings = Map<String, String>.from(state.keyMappings);
    newMappings[action] = key;
    state = state.copyWith(keyMappings: newMappings);
  }

  void toggleHapticFeedback() {
    state = state.copyWith(hapticFeedback: !state.hapticFeedback);
  }

  void toggleAudioFeedback() {
    state = state.copyWith(audioFeedback: !state.audioFeedback);
  }
}

/// Provider for Bluetooth pedal settings
final bluetoothPedalSettingsProvider = StateNotifierProvider<BluetoothPedalSettingsNotifier, BluetoothPedalSettings>((ref) {
  return BluetoothPedalSettingsNotifier();
});
