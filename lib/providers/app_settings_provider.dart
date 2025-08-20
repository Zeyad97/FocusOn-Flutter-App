import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Global App Settings Provider
final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier();
});

class AppSettings {
  final double textScaleFactor;
  final double interfacePadding;
  final String interfaceDensity;
  final String learningProfile;
  final bool microBreaksEnabled;
  final double microBreakInterval;
  final double microBreakDuration;
  final double criticalSpotsFrequency;
  final double reviewSpotsFrequency;
  final double maintenanceSpotsFrequency;

  const AppSettings({
    this.textScaleFactor = 1.0,
    this.interfacePadding = 16.0,
    this.interfaceDensity = 'Default',
    this.learningProfile = 'Standard',
    this.microBreaksEnabled = true,
    this.microBreakInterval = 15.0,
    this.microBreakDuration = 2.0,
    this.criticalSpotsFrequency = 15.0,
    this.reviewSpotsFrequency = 20.0,
    this.maintenanceSpotsFrequency = 25.0,
  });

  // Convenience getter for learning system profile
  String get learningSystemProfile => learningProfile;

  AppSettings copyWith({
    double? textScaleFactor,
    double? interfacePadding,
    String? interfaceDensity,
    String? learningProfile,
    bool? microBreaksEnabled,
    double? microBreakInterval,
    double? microBreakDuration,
    double? criticalSpotsFrequency,
    double? reviewSpotsFrequency,
    double? maintenanceSpotsFrequency,
  }) {
    return AppSettings(
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      interfacePadding: interfacePadding ?? this.interfacePadding,
      interfaceDensity: interfaceDensity ?? this.interfaceDensity,
      learningProfile: learningProfile ?? this.learningProfile,
      microBreaksEnabled: microBreaksEnabled ?? this.microBreaksEnabled,
      microBreakInterval: microBreakInterval ?? this.microBreakInterval,
      microBreakDuration: microBreakDuration ?? this.microBreakDuration,
      criticalSpotsFrequency: criticalSpotsFrequency ?? this.criticalSpotsFrequency,
      reviewSpotsFrequency: reviewSpotsFrequency ?? this.reviewSpotsFrequency,
      maintenanceSpotsFrequency: maintenanceSpotsFrequency ?? this.maintenanceSpotsFrequency,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    state = AppSettings(
      textScaleFactor: _calculateTextScaleFactor(prefs.getDouble('font_size') ?? 16.0),
      interfacePadding: _calculateInterfacePadding(prefs.getString('interface_density') ?? 'Default'),
      interfaceDensity: prefs.getString('interface_density') ?? 'Default',
      learningProfile: prefs.getString('learning_profile') ?? 'Standard',
      microBreaksEnabled: prefs.getBool('micro_breaks_enabled') ?? true,
      microBreakInterval: prefs.getDouble('micro_break_interval') ?? 15.0,
      microBreakDuration: prefs.getDouble('micro_break_duration') ?? 2.0,
      criticalSpotsFrequency: prefs.getDouble('critical_spots_frequency') ?? 15.0,
      reviewSpotsFrequency: prefs.getDouble('review_spots_frequency') ?? 20.0,
      maintenanceSpotsFrequency: prefs.getDouble('maintenance_spots_frequency') ?? 25.0,
    );
  }

  double _calculateTextScaleFactor(double fontSize) {
    // Convert font size (12-24px) to text scale factor (0.75-1.5)
    return (fontSize - 12) / 8 * 0.75 + 0.75;
  }

  double _calculateInterfacePadding(String density) {
    switch (density) {
      case 'Compact':
        return 12.0;
      case 'Spacious':
        return 24.0;
      default: // Default
        return 16.0;
    }
  }

  Future<void> updateFontSize(double fontSize) async {
    final textScaleFactor = _calculateTextScaleFactor(fontSize);
    state = state.copyWith(textScaleFactor: textScaleFactor);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_size', fontSize);
  }

  Future<void> updateInterfaceDensity(String density) async {
    final padding = _calculateInterfacePadding(density);
    state = state.copyWith(
      interfaceDensity: density,
      interfacePadding: padding,
    );
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('interface_density', density);
  }

  Future<void> updateLearningProfile(String profile) async {
    state = state.copyWith(learningProfile: profile);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('learning_profile', profile);
  }

  Future<void> updateMicroBreaksEnabled(bool enabled) async {
    state = state.copyWith(microBreaksEnabled: enabled);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('micro_breaks_enabled', enabled);
  }

  Future<void> updateMicroBreakInterval(double interval) async {
    state = state.copyWith(microBreakInterval: interval);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('micro_break_interval', interval);
  }

  Future<void> updateMicroBreakDuration(double duration) async {
    state = state.copyWith(microBreakDuration: duration);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('micro_break_duration', duration);
  }

  Future<void> updateCriticalSpotsFrequency(double frequency) async {
    state = state.copyWith(criticalSpotsFrequency: frequency);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('critical_spots_frequency', frequency);
  }

  Future<void> updateReviewSpotsFrequency(double frequency) async {
    state = state.copyWith(reviewSpotsFrequency: frequency);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('review_spots_frequency', frequency);
  }

  Future<void> updateMaintenanceSpotsFrequency(double frequency) async {
    state = state.copyWith(maintenanceSpotsFrequency: frequency);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('maintenance_spots_frequency', frequency);
  }

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Clear all stored preferences
    await prefs.remove('font_size');
    await prefs.remove('interface_density');
    await prefs.remove('learning_profile');
    await prefs.remove('micro_breaks_enabled');
    await prefs.remove('micro_break_interval');
    await prefs.remove('micro_break_duration');
    await prefs.remove('critical_spots_frequency');
    await prefs.remove('review_spots_frequency');
    await prefs.remove('maintenance_spots_frequency');
    
    // Reset to default values
    state = const AppSettings();
  }
}
