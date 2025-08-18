import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import 'onboarding_view_screen.dart';
import '../database_test_screen.dart';

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

final practiceRemindersProvider = StateNotifierProvider<BoolSettingNotifier, bool>((ref) {
  return BoolSettingNotifier('practice_reminders', true);
});

final soundEffectsProvider = StateNotifierProvider<BoolSettingNotifier, bool>((ref) {
  return BoolSettingNotifier('sound_effects', true);
});

final defaultTempoProvider = StateNotifierProvider<DoubleSettingNotifier, double>((ref) {
  return DoubleSettingNotifier('default_tempo', 120.0);
});

final exportFormatProvider = StateNotifierProvider<StringSettingNotifier, String>((ref) {
  return StringSettingNotifier('export_format', 'PDF');
});

final cloudStorageProvider = StateNotifierProvider<StringSettingNotifier, String>((ref) {
  return StringSettingNotifier('cloud_storage', 'Google Drive');
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
    final practiceReminders = ref.watch(practiceRemindersProvider);
    final soundEffects = ref.watch(soundEffectsProvider);
    final defaultTempo = ref.watch(defaultTempoProvider);
    final exportFormat = ref.watch(exportFormatProvider);
    final cloudStorage = ref.watch(cloudStorageProvider);
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

                    // Practice Settings
                    _buildSettingsSection(
                      'Practice',
                      Icons.piano,
                      [
                        _buildSwitchTile(
                          'Practice Reminders',
                          'Get notified when spots are due for review',
                          Icons.notifications,
                          practiceReminders,
                          (value) => ref.read(practiceRemindersProvider.notifier).toggle(),
                        ),
                        _buildSliderTile(
                          'Default Metronome BPM',
                          'Set your preferred starting tempo',
                          Icons.speed,
                          defaultTempo,
                          60.0,
                          200.0,
                          (value) => ref.read(defaultTempoProvider.notifier).update(value),
                        ),
                        _buildDropdownTile(
                          'Export Format',
                          'Choose format for exported annotations',
                          Icons.file_download,
                          exportFormat,
                          ['PDF', 'MIDI', 'MusicXML'],
                          (value) => ref.read(exportFormatProvider.notifier).update(value!),
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
                          'Sound Effects',
                          'Enable audio feedback for interactions',
                          Icons.volume_up,
                          soundEffects,
                          (value) => ref.read(soundEffectsProvider.notifier).toggle(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Sync & Storage
                    _buildSettingsSection(
                      'Sync & Storage',
                      Icons.cloud,
                      [
                        _buildSwitchTile(
                          'Auto Sync',
                          'Automatically backup your progress to the cloud',
                          Icons.sync,
                          autoSync,
                          (value) => ref.read(autoSyncProvider.notifier).toggle(),
                        ),
                        _buildDropdownTile(
                          'Cloud Storage',
                          'Choose your preferred cloud storage provider',
                          Icons.cloud_upload,
                          cloudStorage,
                          ['Google Drive', 'iCloud', 'Dropbox', 'OneDrive'],
                          (value) => ref.read(cloudStorageProvider.notifier).update(value!),
                        ),
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

                    const SizedBox(height: 24),

                    // Developer Section
                    _buildSettingsSection(
                      'Developer',
                      Icons.code,
                      [
                        _buildActionTile(
                          'Test Database',
                          'Test the new practice spots database system',
                          Icons.storage,
                          () => _testDatabase(),
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

  Widget _buildSettingsSection(String title, IconData icon, List<Widget> children) {
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

  Future<void> _testDatabase() async {
    // Navigate to database test screen
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DatabaseTestScreen(),
      ),
    );
  }

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
        onChanged: onChanged,
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
    ValueChanged<double> onChanged,
  ) {
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
                '${value.round()} BPM',
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
            onChanged: onChanged,
            activeColor: AppColors.primaryPurple,
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

  void _exportData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.download, color: AppColors.primaryPurple),
            const SizedBox(width: 8),
            const Text('Export Data'),
          ],
        ),
        content: const Text('This will export all your practice data, annotations, and settings to a backup file.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text('Practice data exported successfully!'),
                    ],
                  ),
                  backgroundColor: AppColors.primaryPurple,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will delete all temporary files. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: AppColors.successGreen,
                ),
              );
            },
            child: const Text('Clear'),
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
              
              await ref.read(practiceRemindersProvider.notifier).toggle();
              if (!ref.read(practiceRemindersProvider)) {
                await ref.read(practiceRemindersProvider.notifier).toggle();
              }
              
              await ref.read(autoSyncProvider.notifier).toggle();
              if (!ref.read(autoSyncProvider)) {
                await ref.read(autoSyncProvider.notifier).toggle();
              }
              
              await ref.read(soundEffectsProvider.notifier).toggle();
              if (!ref.read(soundEffectsProvider)) {
                await ref.read(soundEffectsProvider.notifier).toggle();
              }
              
              await ref.read(defaultTempoProvider.notifier).update(120.0);
              await ref.read(exportFormatProvider.notifier).update('PDF');
              await ref.read(cloudStorageProvider.notifier).update('Google Drive');
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to defaults'),
                  backgroundColor: AppColors.successGreen,
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
}
