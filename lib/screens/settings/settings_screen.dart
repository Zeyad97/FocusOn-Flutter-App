import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_settings_provider.dart';
import '../../services/database_service.dart';
import '../../services/bluetooth_pedal_service.dart';
import 'onboarding_view_screen.dart';
// Removed test screen imports for production

// Providers for settings state management
final darkModeProvider = StateNotifierProvider<DarkModeNotifier, bool>((ref) {
  return DarkModeNotifier();
});

final userNameProvider = StateNotifierProvider<UserNameNotifier, String>((ref) {
  return UserNameNotifier();
});

final autoSyncProvider = StateNotifierProvider<BoolSettingNotifier, bool>((ref) {
  return BoolSettingNotifier('auto_sync', true);
});

final soundEffectsProvider = StateNotifierProvider<BoolSettingNotifier, bool>((ref) {
  return BoolSettingNotifier('sound_effects', true);
});

final defaultTempoProvider = StateNotifierProvider<DoubleSettingNotifier, double>((ref) {
  return DoubleSettingNotifier('default_tempo', 120.0);
});

final colorblindModeProvider = StateNotifierProvider<BoolSettingNotifier, bool>((ref) {
  return BoolSettingNotifier('colorblind_mode', false);
});

// New Settings Providers

// Micro-breaks Settings
final microBreaksEnabledProvider = StateNotifierProvider<BoolSettingNotifier, bool>((ref) {
  return BoolSettingNotifier('micro_breaks_enabled', true);
});

final microBreakIntervalProvider = StateNotifierProvider<DoubleSettingNotifier, double>((ref) {
  return DoubleSettingNotifier('micro_break_interval', 2.0);
});

final microBreakDurationProvider = StateNotifierProvider<DoubleSettingNotifier, double>((ref) {
  return DoubleSettingNotifier('micro_break_duration', 2.0);
});

// Layout & Typography Settings
final interfaceDensityProvider = StateNotifierProvider<StringSettingNotifier, String>((ref) {
  return StringSettingNotifier('interface_density', 'Default');
});

final fontSizeProvider = StateNotifierProvider<DoubleSettingNotifier, double>((ref) {
  return DoubleSettingNotifier('font_size', 16.0);
});

// Learning System Settings
final learningProfileProvider = StateNotifierProvider<StringSettingNotifier, String>((ref) {
  return StringSettingNotifier('learning_profile', 'Standard');
});

// Review Frequency Settings
final criticalSpotsFrequencyProvider = StateNotifierProvider<DoubleSettingNotifier, double>((ref) {
  return DoubleSettingNotifier('critical_spots_frequency', 15.0);
});

final reviewSpotsFrequencyProvider = StateNotifierProvider<DoubleSettingNotifier, double>((ref) {
  return DoubleSettingNotifier('review_spots_frequency', 20.0);
});

final maintenanceSpotsFrequencyProvider = StateNotifierProvider<DoubleSettingNotifier, double>((ref) {
  return DoubleSettingNotifier('maintenance_spots_frequency', 25.0);
});

// State notifiers for persistent settings
class DarkModeNotifier extends StateNotifier<bool> {
  DarkModeNotifier() : super(false) {
    _loadDarkMode();
  }

  Future<void> _loadDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('dark_mode') ?? false;
  }

  Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    state = !state;
    await prefs.setBool('dark_mode', state);
  }
}

class UserNameNotifier extends StateNotifier<String> {
  UserNameNotifier() : super('User') {
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('user_name') ?? 'User';
  }

  Future<void> updateUserName(String newName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', newName);
    state = newName;
  }
}

class BoolSettingNotifier extends StateNotifier<bool> {
  final String key;
  final bool defaultValue;

  BoolSettingNotifier(this.key, this.defaultValue) : super(defaultValue) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(key) ?? defaultValue;
  }

  Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    state = !state;
    await prefs.setBool(key, state);
  }
}

class DoubleSettingNotifier extends StateNotifier<double> {
  final String key;
  final double defaultValue;

  DoubleSettingNotifier(this.key, this.defaultValue) : super(defaultValue) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getDouble(key) ?? defaultValue;
  }

  Future<void> update(double value) async {
    final prefs = await SharedPreferences.getInstance();
    state = value;
    await prefs.setDouble(key, value);
  }
}

class StringSettingNotifier extends StateNotifier<String> {
  final String key;
  final String defaultValue;

  StringSettingNotifier(this.key, this.defaultValue) : super(defaultValue) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(key) ?? defaultValue;
  }

  Future<void> update(String value) async {
    final prefs = await SharedPreferences.getInstance();
    state = value;
    await prefs.setString(key, value);
  }
}

/// Settings screen with comprehensive app configuration
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(darkModeProvider);
    final autoSync = ref.watch(autoSyncProvider);
    final soundEffects = ref.watch(soundEffectsProvider);
    final defaultTempo = ref.watch(defaultTempoProvider);
    final colorblindMode = ref.watch(colorblindModeProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primaryPurple,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryPurple,
                        AppColors.accentPurple,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Settings content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile Settings
                    _buildSettingsSection(
                      'Profile',
                      Icons.person,
                      [
                        _buildUsernameTile(),
                        _buildActionTile(
                          'Show Onboarding',
                          'View the app introduction again',
                          Icons.school,
                          () => _showOnboarding(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Appearance Settings
                    _buildSettingsSection(
                      'Appearance',
                      Icons.palette,
                      [
                        _buildSwitchTile(
                          'Dark Mode',
                          'Switch between light and dark themes',
                          Icons.dark_mode,
                          isDarkMode,
                          (value) {
                            ref.read(darkModeProvider.notifier).toggle();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isDarkMode ? 'Light mode enabled' : 'Dark mode enabled',
                                ),
                                backgroundColor: AppColors.primaryPurple,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        _buildSwitchTile(
                          'Colorblind Accessibility',
                          'Use high contrast colors and patterns for better visibility',
                          Icons.accessibility,
                          colorblindMode,
                          (value) {
                            ref.read(colorblindModeProvider.notifier).toggle();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  colorblindMode 
                                    ? 'Colorblind mode disabled' 
                                    : 'Colorblind mode enabled',
                                ),
                                backgroundColor: AppColors.primaryPurple,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        
                        // Color preview when colorblind mode is enabled
                        if (colorblindMode) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primaryPurple.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Colorblind-Friendly Colors Active',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryPurple,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Practice spot colors now use:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildColorPreview('Critical', AppColors.colorblindRed),
                                    const SizedBox(width: 8),
                                    _buildColorPreview('Review', AppColors.colorblindOrange),
                                    const SizedBox(width: 8),
                                    _buildColorPreview('Maintenance', AppColors.colorblindBlue),
                                    const SizedBox(width: 8),
                                    _buildColorPreview('Mastered', AppColors.colorblindPattern1),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Data Management
                    _buildSettingsSection(
                      'Data Management',
                      Icons.storage,
                      [
                        _buildActionTile(
                          'Export Data',
                          'Export all your practice data and annotations',
                          Icons.download,
                          () => _exportData(),
                        ),
                        _buildActionTile(
                          'Clear Cache',
                          'Free up storage space by clearing temporary files',
                          Icons.cleaning_services,
                          () => _clearCache(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Micro-breaks Settings
                    _buildSettingsSection(
                      'Micro-breaks',
                      Icons.timer,
                      [
                        _buildSwitchTile(
                          'Enable Micro-breaks',
                          'Take short breaks during practice sessions',
                          Icons.pause_circle,
                          ref.watch(appSettingsProvider).microBreaksEnabled,
                          (value) => ref.read(appSettingsProvider.notifier).updateMicroBreaksEnabled(value),
                        ),
                        _buildSliderTile(
                          'Break Interval',
                          'How often to take breaks (in minutes)',
                          Icons.schedule,
                          ref.watch(appSettingsProvider).microBreakInterval,
                          1.0,
                          60.0,
                          (value) => ref.read(appSettingsProvider.notifier).updateMicroBreakInterval(value),
                          unit: ' min',
                        ),
                        _buildSliderTile(
                          'Break Duration',
                          'Length of each break (in minutes)',
                          Icons.timer_outlined,
                          ref.watch(appSettingsProvider).microBreakDuration,
                          1.0,
                          15.0,
                          (value) => ref.read(appSettingsProvider.notifier).updateMicroBreakDuration(value),
                          unit: ' min',
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Layout & Typography Settings
                    _buildSettingsSection(
                      'Layout & Typography',
                      Icons.text_fields,
                      [
                        _buildDropdownTile(
                          'Interface Density',
                          'Adjust spacing and element sizes',
                          Icons.density_medium,
                          ref.watch(appSettingsProvider).interfaceDensity,
                          ['Compact', 'Default', 'Spacious'],
                          (value) => ref.read(appSettingsProvider.notifier).updateInterfaceDensity(value!),
                        ),
                        _buildSliderTile(
                          'Font Size',
                          'Adjust text size throughout the app',
                          Icons.format_size,
                          (ref.watch(appSettingsProvider).textScaleFactor - 0.75) / 0.75 * 8 + 12,
                          12.0,
                          24.0,
                          (value) => ref.read(appSettingsProvider.notifier).updateFontSize(value),
                          unit: 'px',
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Learning System Settings
                    // Review Frequency Settings
                    _buildSettingsSection(
                      'Review Frequency Difficulty',
                      Icons.repeat,
                      [
                        _buildFrequencySliderTile(
                          'Critical Spots (Red)',
                          'High priority spots that need frequent practice',
                          Icons.priority_high,
                          ref.watch(appSettingsProvider).criticalSpotsFrequency,
                          8.0,
                          25.0,
                          (value) => ref.read(appSettingsProvider.notifier).updateCriticalSpotsFrequency(value),
                          AppColors.errorRed,
                        ),
                        _buildFrequencySliderTile(
                          'Review Spots (Yellow)',
                          'Medium priority spots for regular review',
                          Icons.warning,
                          ref.watch(appSettingsProvider).reviewSpotsFrequency,
                          12.0,
                          30.0,
                          (value) => ref.read(appSettingsProvider.notifier).updateReviewSpotsFrequency(value),
                          AppColors.warningOrange,
                        ),
                        _buildFrequencySliderTile(
                          'Maintenance Spots (Green)',
                          'Low priority spots for occasional review',
                          Icons.check_circle,
                          ref.watch(appSettingsProvider).maintenanceSpotsFrequency,
                          15.0,
                          35.0,
                          (value) => ref.read(appSettingsProvider.notifier).updateMaintenanceSpotsFrequency(value),
                          AppColors.successGreen,
                        ),
                      ],
                      infoButton: _buildInfoButton(
                        'How Review Frequency Works',
                        'The app uses Spaced Repetition System (SRS) to optimize your practice. Each spot color has a different review schedule:\n\n'
                        '• Red spots: Need urgent attention, reviewed every few days\n'
                        '• Yellow spots: Active practice, reviewed weekly\n'
                        '• Green spots: Maintenance mode, reviewed every few weeks\n\n'
                        'Lower numbers = more frequent reviews. Adjust based on your learning pace.'
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Bluetooth Pedal Settings
                    _buildSettingsSection(
                      'Bluetooth Pedal Support',
                      Icons.pedal_bike_outlined,
                      [
                        Consumer(
                          builder: (context, ref, child) {
                            final pedalSettings = ref.watch(bluetoothPedalSettingsProvider);
                            return _buildSwitchTile(
                              'Enable Bluetooth Pedal',
                              'Turn on Bluetooth pedal support for page navigation',
                              Icons.bluetooth,
                              pedalSettings.isEnabled,
                              (value) {
                                ref.read(bluetoothPedalSettingsProvider.notifier).toggleEnabled();
                              },
                            );
                          },
                        ),
                        Consumer(
                          builder: (context, ref, child) {
                            final pedalSettings = ref.watch(bluetoothPedalSettingsProvider);
                            return _buildSwitchTile(
                              'Haptic Feedback',
                              'Vibrate when pedal commands are received',
                              Icons.vibration,
                              pedalSettings.hapticFeedback,
                              (value) {
                                ref.read(bluetoothPedalSettingsProvider.notifier).toggleHapticFeedback();
                              },
                            );
                          },
                        ),
                      ],
                      infoButton: _buildInfoButton(
                        'Bluetooth Pedal Setup',
                        'Connect a Bluetooth pedal for hands-free page turning during performance. Most Bluetooth pedals work by sending keyboard commands.\n\n'
                        'Supported keys:\n'
                        '• Page Up/Down\n'
                        '• Arrow Keys\n'
                        '• Space\n'
                        '• F1-F5\n'
                        '• Enter, Escape\n\n'
                        'Enable haptic feedback to get vibration confirmation when pedal commands are received.'
                      ),
                    ),

                    const SizedBox(height: 24),

                    // About Section
                    _buildSettingsSection(
                      'About',
                      Icons.info,
                      [
                        _buildInfoTile(
                          'Version',
                          '1.0.0 (Build 1)',
                          Icons.info_outline,
                        ),
                        _buildDeveloperTile(),
                        _buildActionTile(
                          'Privacy Policy',
                          'Read our privacy policy and data handling practices',
                          Icons.privacy_tip,
                          () => _openPrivacyPolicy(),
                        ),
                        _buildActionTile(
                          'Terms of Service',
                          'View the terms and conditions of use',
                          Icons.gavel,
                          () => _openTerms(),
                        ),
                        _buildActionTile(
                          'Contact Support',
                          'Get help or report issues',
                          Icons.support_agent,
                          () => _contactSupport(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Reset button
                    OutlinedButton(
                      onPressed: _resetSettings,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.errorRed,
                        side: const BorderSide(color: AppColors.errorRed),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text('Reset All Settings'),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, IconData icon, List<Widget> children, {Widget? infoButton}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryPurple.withOpacity(0.1),
                  AppColors.accentPurple.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primaryPurple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryPurple,
                  ),
                ),
                if (infoButton != null) ...[
                  const Spacer(),
                  infoButton,
                ],
              ],
            ),
          ),
          // Section content
          ...children,
        ],
      ),
    );
  }

  Widget _buildUsernameTile() {
    final userName = ref.watch(userNameProvider);
    
    return ListTile(
      leading: const Icon(Icons.person, color: AppColors.textSecondary),
      title: const Text('Username', style: TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(userName, style: const TextStyle(color: AppColors.textSecondary)),
      trailing: const Icon(Icons.edit, color: AppColors.textSecondary),
      onTap: () => _showUsernameDialog(),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
      trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 16),
      onTap: onTap,
    );
  }

  Future<void> _showUsernameDialog() async {
    final currentName = ref.read(userNameProvider);
    final controller = TextEditingController(text: currentName);
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Username'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Username',
              hintText: 'Enter your name',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  ref.read(userNameProvider.notifier).updateUserName(newName);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Username updated successfully!'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showOnboarding() async {
    // Import the onboarding screen
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const OnboardingViewScreen(),
      ),
    );
  }

  // Test functions removed for production

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: AppColors.textSecondary)),
      trailing: Switch(
        value: value,
        onChanged: (newValue) {
          HapticFeedback.lightImpact();
          onChanged(newValue);
        },
        activeColor: AppColors.primaryPurple,
      ),
    );
  }

  Widget _buildSliderTile(
    String title,
    String subtitle,
    IconData icon,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    String unit = ' BPM',
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Text(
                '${value.round()}$unit',
                style: TextStyle(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).round(),
            onChanged: (newValue) {
              HapticFeedback.lightImpact();
              onChanged(newValue);
            },
            activeColor: AppColors.primaryPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencySliderTile(
    String title,
    String subtitle,
    IconData icon,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    Color color,
  ) {
    // Calculate approximate review interval
    int intervalDays = (100 / value).round();
    String intervalText = intervalDays == 1 ? 'daily' : 'every $intervalDays days';
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${value.round()}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    intervalText,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).round(),
            onChanged: (newValue) {
              HapticFeedback.lightImpact();
              onChanged(newValue);
            },
            activeColor: color,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    IconData icon,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: AppColors.textSecondary)),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        items: options.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Text(option),
          );
        }).toList(),
        underline: const SizedBox(),
      ),
    );
  }

  Widget _buildDeveloperTile() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryPurple.withOpacity(0.1),
            AppColors.accentPurple.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryPurple.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.code,
            color: AppColors.primaryPurple,
            size: 20,
          ),
        ),
        title: const Text(
          'Developer',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Built with ❤️ by a passionate developer',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryPurple,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'ZYAD',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Text(
        value,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryPurple,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Exporting Data...'),
            ],
          ),
          content: const Text('Please wait while we prepare your data for export.'),
        ),
      );

      // Get database service
      final databaseService = ref.read(databaseServiceProvider);
      
      // Export all data
      final practiceSessionsData = await databaseService.getAllPracticeSessions();
      final spotsData = await databaseService.getAllSpots();
      final preferencesData = await _getAllPreferences();
      
      // Create export data map
      final exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'practice_sessions': practiceSessionsData.map((session) => session.toJson()).toList(),
        'spots': spotsData.map((spot) => spot.toJson()).toList(),
        'preferences': preferencesData,
      };

      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'music_app_backup_$timestamp.json';
      final file = File(path.join(directory.path, fileName));
      
      // Write data to file
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(exportData),
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.successGreen),
                const SizedBox(width: 8),
                const Text('Export Successful'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your data has been exported successfully!'),
                const SizedBox(height: 12),
                Text(
                  'File saved to:\n${file.path}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Exported data includes:\n• ${practiceSessionsData.length} practice sessions\n• ${spotsData.length} practice spots\n• App preferences and settings',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) Navigator.pop(context);
      
      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error, color: AppColors.errorRed),
                const SizedBox(width: 8),
                const Text('Export Failed'),
              ],
            ),
            content: Text('Failed to export data: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _getAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final preferencesData = <String, dynamic>{};
    
    for (final key in keys) {
      final value = prefs.get(key);
      preferencesData[key] = value;
    }
    
    return preferencesData;
  }

  Future<void> _clearCache() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cleaning_services, color: AppColors.warningOrange),
            const SizedBox(width: 8),
            const Text('Clear Cache'),
          ],
        ),
        content: const Text(
          'This will delete all temporary files, cached PDFs, and app cache. '
          'Your practice data and settings will not be affected. Continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  title: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('Clearing Cache...'),
                    ],
                  ),
                  content: const Text('Please wait while we clear temporary files.'),
                ),
              );
              
              try {
                int totalFilesDeleted = 0;
                int totalSizeFreed = 0;
                
                // Clear app cache directory
                final cacheDir = await getTemporaryDirectory();
                if (await cacheDir.exists()) {
                  final files = cacheDir.listSync(recursive: true);
                  for (final file in files) {
                    if (file is File) {
                      final size = await file.length();
                      totalSizeFreed += size;
                      await file.delete();
                      totalFilesDeleted++;
                    }
                  }
                }
                
                // Clear file picker cache
                final appDir = await getApplicationSupportDirectory();
                final filePickerCache = Directory(path.join(appDir.path, 'file_picker'));
                if (await filePickerCache.exists()) {
                  final files = filePickerCache.listSync(recursive: true);
                  for (final file in files) {
                    if (file is File) {
                      final size = await file.length();
                      totalSizeFreed += size;
                      await file.delete();
                      totalFilesDeleted++;
                    }
                  }
                }
                
                // Close loading dialog
                if (mounted) Navigator.pop(context);
                
                // Show success message
                if (mounted) {
                  final sizeMB = (totalSizeFreed / (1024 * 1024)).toStringAsFixed(1);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Row(
                        children: [
                          Icon(Icons.check_circle, color: AppColors.successGreen),
                          const SizedBox(width: 8),
                          const Text('Cache Cleared'),
                        ],
                      ),
                      content: Text(
                        'Successfully cleared cache!\n\n'
                        '• $totalFilesDeleted files deleted\n'
                        '• ${sizeMB}MB of storage freed',
                      ),
                      actions: [
                        FilledButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  );
                }
              } catch (e) {
                // Close loading dialog if open
                if (mounted) Navigator.pop(context);
                
                // Show error
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Row(
                        children: [
                          Icon(Icons.error, color: AppColors.errorRed),
                          const SizedBox(width: 8),
                          const Text('Clear Cache Failed'),
                        ],
                      ),
                      content: Text('Failed to clear cache: $e'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.warningOrange),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }

  void _openPrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening privacy policy...'),
        backgroundColor: AppColors.primaryPurple,
      ),
    );
  }

  void _openTerms() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening terms of service...'),
        backgroundColor: AppColors.primaryPurple,
      ),
    );
  }

  void _contactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.support_agent, color: AppColors.primaryPurple),
            const SizedBox(width: 8),
            const Text('Contact Support'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Need help? Choose how you\'d like to get support:'),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.email, color: AppColors.primaryPurple),
              title: const Text('Email Support'),
              subtitle: const Text('support@scorereadpro.com'),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening email client...'),
                    backgroundColor: AppColors.primaryPurple,
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.bug_report, color: AppColors.warningOrange),
              title: const Text('Report Bug'),
              subtitle: const Text('Help us improve the app'),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening bug report form...'),
                    backgroundColor: AppColors.warningOrange,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _resetSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('This will restore all settings to their default values. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              // Reset all settings using the providers
              await ref.read(darkModeProvider.notifier).toggle();
              if (ref.read(darkModeProvider)) {
                await ref.read(darkModeProvider.notifier).toggle();
              }
              
              await ref.read(autoSyncProvider.notifier).toggle();
              if (!ref.read(autoSyncProvider)) {
                await ref.read(autoSyncProvider.notifier).toggle();
              }
              
              await ref.read(soundEffectsProvider.notifier).toggle();
              if (!ref.read(soundEffectsProvider)) {
                await ref.read(soundEffectsProvider.notifier).toggle();
              }
              
              // Reset other settings to defaults
              await ref.read(defaultTempoProvider.notifier).update(120.0);
              
              // Reset new app settings
              await ref.read(appSettingsProvider.notifier).resetToDefaults();
              
              Navigator.pop(context);
              
              // Show success message with haptic feedback
              HapticFeedback.heavyImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text('All settings reset to defaults'),
                    ],
                  ),
                  backgroundColor: AppColors.successGreen,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.errorRed),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPreview(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoButton(String title, String content) {
    return GestureDetector(
      onTap: () => _showInfoDialog(title, content),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.primaryPurple.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primaryPurple.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.info_outline,
          size: 16,
          color: AppColors.primaryPurple,
        ),
      ),
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }
}
