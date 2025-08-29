import 'package:flutter/material.dart';
import '../models/spot.dart';

/// App color constants based on the specification
class AppColors {
  // Spot Colors (Core Feature)
  static const spotRed = Color(0xFFEF4444);      // Critical spots
  static const spotYellow = Color(0xFFF59E0B);   // Review spots
  static const spotGreen = Color(0xFF10B981);    // Maintenance spots

  // Purple Theme Colors
  static const primary = Color(0xFF8B5CF6);       // Main purple
  static const primaryBlue = Color(0xFF8B5CF6);   // Purple instead of blue
  static const primaryPurple = Color(0xFF8B5CF6); // Main purple
  static const accentPurple = Color(0xFFA855F7);  // Lighter purple accent
  static const deepPurple = Color(0xFF7C3AED);    // Deeper purple
  static const lightPurple = Color(0xFFC084FC);   // Light purple
  static const accentWarm = Color(0xFFF59E0B);
  static const backgroundDark = Color(0xFF0F0B1F);
  static const backgroundSecondary = Color(0xFFF8F9FA);
  static const surfaceDark = Color(0xFF1E1B31);
  static const surface = Color(0xFFFAF9FC);
  static const surfaceColor = Color(0xFFFAF9FC);
  static const text = Color(0xFF1F2937);
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const borderLight = Color(0xFFE5E7EB);
  static const successGreen = Color(0xFF059669);
  static const warningOrange = Color(0xFFF97316);
  static const warningYellow = Color(0xFFF59E0B);
  static const errorRed = Color(0xFFDC2626);

  // Gradient colors
  static const gradientStart = Color(0xFF8B5CF6);
  static const gradientEnd = Color(0xFFA855F7);

  // Colorblind-friendly colors
  static const colorblindRed = Color(0xFF9D0208);      // Dark red for critical spots
  static const colorblindOrange = Color(0xFFFF6D00);   // Orange for review spots  
  static const colorblindBlue = Color(0xFF0077BE);     // Blue for maintenance spots
  static const colorblindPattern1 = Color(0xFF2E8B57); // Sea green alternative
  static const colorblindPattern2 = Color(0xFF8B008B); // Dark magenta alternative
  static const colorblindPattern3 = Color(0xFF4B0082); // Indigo alternative

  /// Get spot color based on difficulty and colorblind mode
  static Color getSpotColor(String difficulty, {bool colorblindMode = false}) {
    if (colorblindMode) {
      switch (difficulty.toLowerCase()) {
        case 'hard':
        case 'critical':
          return colorblindRed;
        case 'medium':
        case 'review':
          return colorblindOrange;
        case 'easy':
        case 'maintenance':
          return colorblindBlue;
        default:
          return colorblindPattern1;
      }
    } else {
      switch (difficulty.toLowerCase()) {
        case 'hard':
        case 'critical':
          return spotRed;
        case 'medium':
        case 'review':
          return spotYellow;
        case 'easy':
        case 'maintenance':
          return spotGreen;
        default:
          return spotGreen;
      }
    }
  }

  /// Get spot color by SpotColor enum with colorblind mode support
  static Color getSpotColorByEnum(SpotColor spotColor, {bool colorblindMode = false}) {
    if (colorblindMode) {
      switch (spotColor) {
        case SpotColor.red:
          return colorblindRed;      // Critical spots - Dark red
        case SpotColor.yellow:
          return colorblindOrange;   // Review spots - Orange  
        case SpotColor.green:
          return colorblindBlue;     // Maintenance spots - Blue
        case SpotColor.blue:
          return colorblindPattern1; // Mastered spots - Sea green
      }
    } else {
      switch (spotColor) {
        case SpotColor.red:
          return spotRed;
        case SpotColor.yellow:
          return spotYellow;
        case SpotColor.green:
          return spotGreen;
        case SpotColor.blue:
          return Colors.blue;
      }
    }
  }
}

/// Comprehensive theme system for FocusON Scores
class AppTheme {
  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryPurple,
        brightness: Brightness.light,
        primary: AppColors.primaryPurple,
        secondary: AppColors.accentPurple,
        error: AppColors.errorRed,
        surface: Colors.white,
        background: const Color(0xFFFBFAFF),
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Button Themes
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 2,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryPurple,
          side: BorderSide(color: AppColors.primaryPurple, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Navigation themes
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textSecondary,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // List tile theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minVerticalPadding: 8,
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        selectedColor: AppColors.primaryBlue.withOpacity(0.1),
        labelStyle: const TextStyle(fontSize: 14),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryBlue,
        linearTrackColor: AppColors.borderLight,
        circularTrackColor: AppColors.borderLight,
      ),

      // Typography
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        brightness: Brightness.dark,
        primary: AppColors.primaryBlue,
        secondary: AppColors.accentWarm,
        error: AppColors.errorRed,
        surface: AppColors.surfaceDark,
        background: AppColors.backgroundDark,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        elevation: 4,
        shadowColor: Colors.black26,
        color: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Button themes (same as light, colors handled by ColorScheme)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Navigation themes
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: Colors.grey.shade400,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
      ),

      // Typography for dark mode
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Colors.white,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: Colors.grey,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Gradient decorations for hero sections
  static BoxDecoration get primaryGradient {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.gradientStart, AppColors.gradientEnd],
      ),
    );
  }

  /// Card shadows
  static List<BoxShadow> get cardShadow {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }

  /// Elevated card shadows
  static List<BoxShadow> get elevatedCardShadow {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.15),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];
  }
}
