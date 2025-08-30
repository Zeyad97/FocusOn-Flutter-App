import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'providers/app_settings_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/settings/settings_screen.dart';
import 'services/break_notification_service.dart';

void main() {
  runApp(const ProviderScope(child: FocusONScoresApp()));
}

class FocusONScoresApp extends ConsumerWidget {
  const FocusONScoresApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettings = ref.watch(appSettingsProvider);
    final isDarkMode = ref.watch(darkModeProvider);
    final navigatorKey = ref.watch(navigatorKeyProvider);
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'FocusON Music',
      theme: _buildLightTheme(appSettings),
      darkTheme: _buildDarkTheme(appSettings),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: appSettings.textScaleFactor,
          ),
          child: child!,
        );
      },
    );
  }

  ThemeData _buildLightTheme(AppSettings settings) {
    return AppTheme.lightTheme.copyWith(
      cardTheme: CardThemeData(
        margin: EdgeInsets.all(settings.interfacePadding / 2),
        elevation: settings.interfaceDensity == 'Compact' ? 2 : 
                   settings.interfaceDensity == 'Spacious' ? 8 : 4,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: settings.interfacePadding,
          vertical: settings.interfacePadding / 4,
        ),
        dense: settings.interfaceDensity == 'Compact',
      ),
    );
  }

  ThemeData _buildDarkTheme(AppSettings settings) {
    return AppTheme.darkTheme.copyWith(
      cardTheme: CardThemeData(
        margin: EdgeInsets.all(settings.interfacePadding / 2),
        elevation: settings.interfaceDensity == 'Compact' ? 2 : 
                   settings.interfaceDensity == 'Spacious' ? 8 : 4,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: settings.interfacePadding,
          vertical: settings.interfacePadding / 4,
        ),
        dense: settings.interfaceDensity == 'Compact',
      ),
    );
  }
}
