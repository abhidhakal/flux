import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  // Typography
  static const String fontFamily = 'Poppins';
  
  // Light Text Theme
  static const TextTheme lightTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
      color: AppColors.lightTextPrimary,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.25,
      color: AppColors.lightTextPrimary,
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: AppColors.lightTextPrimary,
    ),
    headlineLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: AppColors.lightTextPrimary,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.lightTextPrimary,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.lightTextPrimary,
    ),
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.lightTextPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.lightTextPrimary,
    ),
    titleSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.lightTextSecondary,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: AppColors.lightTextPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: AppColors.lightTextPrimary,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: AppColors.lightTextSecondary,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.lightTextPrimary,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.lightTextSecondary,
    ),
    labelSmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: AppColors.lightTextTertiary,
    ),
  );

  // Dark Text Theme
  static const TextTheme darkTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
      color: AppColors.darkTextPrimary,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.25,
      color: AppColors.darkTextPrimary,
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: AppColors.darkTextPrimary,
    ),
    headlineLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: AppColors.darkTextPrimary,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.darkTextPrimary,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.darkTextPrimary,
    ),
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.darkTextPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.darkTextPrimary,
    ),
    titleSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.darkTextSecondary,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: AppColors.darkTextPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: AppColors.darkTextPrimary,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: AppColors.darkTextSecondary,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.darkTextPrimary,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.darkTextSecondary,
    ),
    labelSmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: AppColors.darkTextTertiary,
    ),
  );

  // Legacy text theme (for backward compatibility)
  static const TextTheme textTheme = lightTextTheme;

  // Spacing
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;

  // Border radius
  static const double radius4 = 4.0;
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius20 = 20.0;
  static const double radius24 = 24.0;
  static const double radius32 = 32.0;

  // Shadows
  static const List<BoxShadow> shadowLight = [
    BoxShadow(
      color: AppColors.shadowLight,
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
  ];

  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: AppColors.shadowMedium,
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
  ];

  static const List<BoxShadow> shadowDark = [
    BoxShadow(
      color: AppColors.shadowDark,
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];

  // Light theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryUltraLight,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryLight,
        surface: AppColors.lightSurface,
        error: AppColors.error,
        errorContainer: AppColors.errorUltraLight,
        onPrimary: AppColors.lightTextInverse,
        onSecondary: AppColors.lightTextInverse,
        onSurface: AppColors.lightTextPrimary,
        onBackground: AppColors.lightTextPrimary,
        onError: AppColors.lightTextInverse,
        outline: AppColors.lightBorder,
        outlineVariant: AppColors.lightDivider,
      ),
      textTheme: lightTextTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.lightTextInverse,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.lightTextInverse,
          fontFamily: fontFamily,
        ),
        iconTheme: IconThemeData(
          color: AppColors.lightTextInverse,
          size: 24,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColors.primary,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.lightBackground,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarDividerColor: AppColors.lightBackground,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius16),
          side: const BorderSide(
            color: AppColors.lightBorder,
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: spacing8,
          vertical: spacing8,
        ),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.lightTextInverse,
          elevation: 0,
          shadowColor: AppColors.shadowMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: fontFamily,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: fontFamily,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacing16,
            vertical: spacing12,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: fontFamily,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(
            color: AppColors.lightBorder,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(
            color: AppColors.lightBorder,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing16,
        ),
        labelStyle: const TextStyle(
          color: AppColors.lightTextSecondary,
          fontSize: 14,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        hintStyle: const TextStyle(
          color: AppColors.lightTextTertiary,
          fontSize: 14,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightDivider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.lightTextSecondary,
        size: 24,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primaryUltraLight,
        selectedColor: AppColors.primary,
        disabledColor: AppColors.lightTextTertiary,
        labelStyle: const TextStyle(
          color: AppColors.primary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius20),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: spacing12,
          vertical: spacing8,
        ),
      ),
    );
  }

  // Dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryDark,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryDark,
        surface: AppColors.darkSurface,
        error: AppColors.error,
        errorContainer: AppColors.errorDark,
        onPrimary: AppColors.darkTextInverse,
        onSecondary: AppColors.darkTextInverse,
        onSurface: AppColors.darkTextPrimary,
        onBackground: AppColors.darkTextPrimary,
        onError: AppColors.darkTextInverse,
        outline: AppColors.darkBorder,
        outlineVariant: AppColors.darkDivider,
      ),
      textTheme: darkTextTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
          fontFamily: fontFamily,
        ),
        iconTheme: IconThemeData(
          color: AppColors.darkTextPrimary,
          size: 24,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius16),
          side: const BorderSide(
            color: AppColors.darkBorder,
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: spacing8,
          vertical: spacing8,
        ),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.darkTextInverse,
          elevation: 0,
          shadowColor: AppColors.shadowMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: fontFamily,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: fontFamily,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacing16,
            vertical: spacing12,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: fontFamily,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(
            color: AppColors.darkBorder,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(
            color: AppColors.darkBorder,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing16,
        ),
        labelStyle: const TextStyle(
          color: AppColors.darkTextSecondary,
          fontSize: 14,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        hintStyle: const TextStyle(
          color: AppColors.darkTextTertiary,
          fontSize: 14,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.darkTextSecondary,
        size: 24,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primaryDark,
        selectedColor: AppColors.primary,
        disabledColor: AppColors.darkTextTertiary,
        labelStyle: const TextStyle(
          color: AppColors.primary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius20),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: spacing12,
          vertical: spacing8,
        ),
      ),
    );
  }
}
