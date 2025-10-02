// ==========================================
// MAIN.DART - APPLICATION ENTRY POINT
// ==========================================
// This file serves as the main entry point for the FocusON Music App.
// It sets up the app's core architecture, theme management, and navigation.
// The app uses Riverpod for state management and Material Design for UI.

// Core Flutter framework - provides widgets, material design, and app structure
import 'package:flutter/material.dart';

// Riverpod state management - provides reactive state management across the app
// ProviderScope wraps the entire app to enable Riverpod functionality
// ConsumerWidget allows widgets to listen to and react to provider state changes
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Custom app theme definitions - contains light and dark theme configurations
// Includes color schemes, typography, and component styling
import 'theme/app_theme.dart';

// App settings provider - manages user preferences like theme, text scale, interface density
// Provides reactive state for settings that affect the entire app's appearance and behavior
import 'providers/app_settings_provider.dart';

// Screen imports - all major app screens that can be navigated to
import 'screens/splash_screen.dart';        // Initial loading screen with app branding
import 'screens/onboarding_screen.dart';    // First-time user tutorial and setup
import 'screens/main_navigation.dart';      // Main app navigation container with bottom tabs
import 'screens/settings/settings_screen.dart'; // User preferences and app configuration
import 'services/break_notification_service.dart'; // Practice break reminders and notifications

// ==========================================
// MAIN FUNCTION - APPLICATION BOOTSTRAP
// ==========================================
// The main() function is the entry point for all Dart applications.
// It sets up the app's root widget wrapped in ProviderScope for state management.
void main() {
  // runApp() takes the given widget and makes it the root of the widget tree
  // ProviderScope enables Riverpod state management throughout the entire app
  // All descendant widgets can now access providers for reactive state management
  runApp(const ProviderScope(child: FocusONScoresApp()));
}

// ==========================================
// FOCUSON SCORES APP - ROOT APPLICATION WIDGET
// ==========================================
// This is the root widget of the entire application. It extends ConsumerWidget
// to access Riverpod providers and manage the app's global configuration.
// Handles theme switching, navigation setup, and global UI settings.
class FocusONScoresApp extends ConsumerWidget {
  // Constructor with optional key parameter for widget identification
  // The key helps Flutter identify this widget in the widget tree for optimization
  const FocusONScoresApp({super.key});

  // Build method that constructs the widget tree for the entire application
  // @param context: BuildContext provides location in widget tree and theme data
  // @param ref: WidgetRef allows reading from and listening to Riverpod providers
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch app settings provider to get current user preferences
    // This creates a reactive subscription - widget rebuilds when settings change
    final appSettings = ref.watch(appSettingsProvider);
    
    // Watch dark mode provider to determine current theme preference
    // Returns boolean indicating whether dark theme should be used
    final isDarkMode = ref.watch(darkModeProvider);
    
    // Watch navigator key provider for global navigation control
    // This key allows navigation from anywhere in the app, including services
    final navigatorKey = ref.watch(navigatorKeyProvider);
    
    // ==========================================
    // MATERIAL APP CONFIGURATION
    // ==========================================
    // MaterialApp is the root widget that provides Material Design foundation
    // It handles navigation, theming, localization, and global app configuration
    return MaterialApp(
      // Set the global navigation key for programmatic navigation from anywhere
      // This enables navigation from services, providers, or background processes
      navigatorKey: navigatorKey,
      
      // App title displayed in system UI (task switcher, etc.)
      // Used by the OS for app identification and accessibility
      title: 'FocusON Music',
      
      // Light theme configuration built from user settings
      // Applied when system is in light mode or user selects light theme
      theme: _buildLightTheme(appSettings),
      
      // Dark theme configuration built from user settings
      // Applied when system is in dark mode or user selects dark theme
      darkTheme: _buildDarkTheme(appSettings),
      
      // Theme mode selection based on user preference
      // Determines whether to use light, dark, or system theme
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      // Initial screen to display when app launches
      // SplashScreen shows app logo and handles initialization
      home: const SplashScreen(),
      
      // Hide debug banner in top-right corner (for release builds)
      // Debug banner shows "DEBUG" text in development mode
      debugShowCheckedModeBanner: false,
      
      // Custom builder to apply global text scaling and other overrides
      // This wrapper applies user settings to the entire widget tree
      builder: (context, child) {
        // MediaQuery.copyWith creates a new MediaQuery with modified properties
        // textScaleFactor affects all text sizes throughout the app
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // Apply user's preferred text scaling factor for accessibility
            // Range typically 0.8x to 2.0x for better readability
            textScaleFactor: appSettings.textScaleFactor,
          ),
          // Pass the child widget (entire app) with modified MediaQuery
          child: child!,
        );
      },
    );
  }

  // ==========================================
  // LIGHT THEME BUILDER
  // ==========================================
  // Constructs a customized light theme based on user settings and app design
  // Takes base light theme and applies user preferences for spacing and density
  ThemeData _buildLightTheme(AppSettings settings) {
    // Start with the base light theme from AppTheme class
    // copyWith() creates a new theme with specific overrides
    return AppTheme.lightTheme.copyWith(
      // Customize card appearance based on user interface density preference
      cardTheme: CardThemeData(
        // Card margins adjust based on user's interface padding preference
        // Divided by 2 to create balanced spacing around cards
        margin: EdgeInsets.all(settings.interfacePadding / 2),
        
        // Card elevation (shadow depth) varies by interface density setting
        // Compact: minimal shadow, Standard: medium shadow, Spacious: prominent shadow
        elevation: settings.interfaceDensity == 'Compact' ? 2 : 
                   settings.interfaceDensity == 'Spacious' ? 8 : 4,
      ),
      
      // Customize list tile spacing and density
      listTileTheme: ListTileThemeData(
        // Horizontal and vertical padding based on user preference
        // Horizontal uses full padding, vertical uses quarter for balanced appearance
        contentPadding: EdgeInsets.symmetric(
          horizontal: settings.interfacePadding,
          vertical: settings.interfacePadding / 4,
        ),
        // Dense layout for compact interface preference
        // Reduces list item height for more content on screen
        dense: settings.interfaceDensity == 'Compact',
      ),
    );
  }

  // ==========================================
  // DARK THEME BUILDER
  // ==========================================
  // Constructs a customized dark theme based on user settings and app design
  // Identical structure to light theme but uses dark color scheme as base
  ThemeData _buildDarkTheme(AppSettings settings) {
    // Start with the base dark theme from AppTheme class
    // copyWith() creates a new theme with specific overrides
    return AppTheme.darkTheme.copyWith(
      // Customize card appearance based on user interface density preference
      cardTheme: CardThemeData(
        // Card margins adjust based on user's interface padding preference
        // Divided by 2 to create balanced spacing around cards
        margin: EdgeInsets.all(settings.interfacePadding / 2),
        
        // Card elevation (shadow depth) varies by interface density setting
        // Compact: minimal shadow, Standard: medium shadow, Spacious: prominent shadow
        elevation: settings.interfaceDensity == 'Compact' ? 2 : 
                   settings.interfaceDensity == 'Spacious' ? 8 : 4,
      ),
      
      // Customize list tile spacing and density
      listTileTheme: ListTileThemeData(
        // Horizontal and vertical padding based on user preference
        // Horizontal uses full padding, vertical uses quarter for balanced appearance
        contentPadding: EdgeInsets.symmetric(
          horizontal: settings.interfacePadding,
          vertical: settings.interfacePadding / 4,
        ),
        // Dense layout for compact interface preference
        // Reduces list item height for more content on screen
        dense: settings.interfaceDensity == 'Compact',
      ),
    );
  }
}

// ==========================================
// END OF MAIN.DART
// ==========================================
// This file establishes the foundation for the entire FocusON Music App:
// 1. Sets up Riverpod state management
// 2. Configures Material Design theming with user customization
// 3. Handles global navigation and text scaling
// 4. Provides the entry point for app initialization
// 
// Next files to explore:
// - theme/app_theme.dart (theme definitions)
// - providers/app_settings_provider.dart (user settings state)
// - screens/splash_screen.dart (app initialization screen)
