import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storage_service.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../screens/onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();
  bool _keepScreenOn = true;
  bool _darkMode = false;
  double _defaultZoom = 1.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _keepScreenOn = prefs.getBool('keep_screen_on') ?? true;
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _defaultZoom = prefs.getDouble('default_zoom') ?? 1.0;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('keep_screen_on', _keepScreenOn);
    await prefs.setBool('dark_mode', _darkMode);
    await prefs.setDouble('default_zoom', _defaultZoom);
  }

  Future<void> _showAddCategoryDialog() async {
    final TextEditingController controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _storageService.addCategory(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category "$result" added')),
        );
      }
    }
  }

  Future<void> _showManageCategoriesDialog() async {
    final categories = await _storageService.getCategories();
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Manage Categories'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isDefault = ['Classical', 'Jazz', 'Pop', 'Folk', 'Other'].contains(category);
                
                return ListTile(
                  title: Text(category),
                  trailing: isDefault 
                    ? null 
                    : IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await _storageService.deleteCategory(category);
                          Navigator.pop(context);
                          _showManageCategoriesDialog();
                        },
                      ),
                );
              },
            ),
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
  }

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will delete all PDFs, bookmarks, and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text(
              'Settings',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            floating: true,
            pinned: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // User Section
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    return _buildSection(
                      context,
                      'Profile',
                      Icons.person_outline,
                      [
                        _buildUserTile(context, userProvider),
                        _buildActionTile(
                          context,
                          'Change Name',
                          'Update your display name',
                          Icons.edit_outlined,
                          () => _showChangeNameDialog(userProvider),
                        ),
                        _buildActionTile(
                          context,
                          'Show Onboarding',
                          'View the welcome tutorial again',
                          Icons.help_outline,
                          () => _showOnboarding(userProvider),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                
                // Appearance Section
                _buildSection(
                  context,
                  'Appearance',
                  Icons.palette_outlined,
                  [
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return _buildThemeTile(context, themeProvider);
                      },
                    ),
                    _buildSwitchTile(
                      context,
                      'Keep Screen On',
                      'Prevent screen timeout while reading',
                      Icons.screen_lock_portrait_outlined,
                      _keepScreenOn,
                      (value) {
                        setState(() {
                          _keepScreenOn = value;
                        });
                        _saveSettings();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Reading Section
                _buildSection(
                  context,
                  'Reading',
                  Icons.chrome_reader_mode_outlined,
                  [
                    _buildSliderTile(
                      context,
                      'Default Zoom',
                      'Set initial zoom level for PDFs',
                      Icons.zoom_in_outlined,
                      _defaultZoom,
                      0.5,
                      2.0,
                      '${(_defaultZoom * 100).toInt()}%',
                      (value) {
                        setState(() {
                          _defaultZoom = value;
                        });
                      },
                      () => _saveSettings(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Library Section
                _buildSection(
                  context,
                  'Library Management',
                  Icons.library_music_outlined,
                  [
                    _buildActionTile(
                      context,
                      'Add Category',
                      'Create new music categories',
                      Icons.add_circle_outline,
                      _showAddCategoryDialog,
                    ),
                    _buildActionTile(
                      context,
                      'Manage Categories',
                      'Edit or delete categories',
                      Icons.category_outlined,
                      _showManageCategoriesDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Data Section
                _buildSection(
                  context,
                  'Data Management',
                  Icons.storage_outlined,
                  [
                    _buildActionTile(
                      context,
                      'Clear All Data',
                      'Delete all PDFs and settings',
                      Icons.delete_forever_outlined,
                      _clearAllData,
                      isDestructive: true,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // About Section
                _buildSection(
                  context,
                  'About',
                  Icons.info_outline,
                  [
                    _buildInfoTile(
                      context,
                      'Music Sheet Reader',
                      'Version 1.0.0 • Built for musicians',
                      Icons.music_note_outlined,
                    ),
                    _buildInfoTile(
                      context,
                      'Developed by Zyad',
                      'Crafted with ❤️ for music lovers',
                      Icons.code_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon, List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Icon(icon, size: 24, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildThemeTile(BuildContext context, ThemeProvider themeProvider) {
    return ListTile(
      leading: Icon(themeProvider.themeModeIcon),
      title: const Text('Theme'),
      subtitle: Text('Current: ${themeProvider.themeModeString}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose Theme',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ...ThemeMode.values.map((mode) => ListTile(
                  leading: Icon(_getThemeIcon(mode)),
                  title: Text(_getThemeName(mode)),
                  trailing: themeProvider.themeMode == mode 
                      ? const Icon(Icons.check) 
                      : null,
                  onTap: () {
                    themeProvider.setThemeMode(mode);
                    Navigator.pop(context);
                  },
                )),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildSliderTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    double value,
    double min,
    double max,
    String valueLabel,
    ValueChanged<double> onChanged,
    VoidCallback onChangeEnd,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: 15,
                  onChanged: onChanged,
                  onChangeEnd: (_) => onChangeEnd(),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 50,
                child: Text(
                  valueLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isDestructive ? colorScheme.error : null;
    
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.auto_mode;
    }
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _showChangeNameDialog(UserProvider userProvider) {
    final controller = TextEditingController(text: userProvider.userName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Your Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await userProvider.setUserName(controller.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name updated successfully')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showOnboarding(UserProvider userProvider) async {
    await userProvider.resetOnboarding();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  Widget _buildUserTile(BuildContext context, UserProvider userProvider) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Text(
          userProvider.userName.isNotEmpty 
            ? userProvider.userName[0].toUpperCase()
            : 'U',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(userProvider.userName),
      subtitle: const Text('Tap to change your name'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showChangeNameDialog(userProvider),
    );
  }
}
