import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  // Primary colors - Modern Blue (#0079dc)
  static const Color primary = Color(0xFF0079DC);
  static const Color primaryLight = Color(0xFF3399FF);
  static const Color primaryDark = Color(0xFF0056B3);
  static const Color primaryUltraLight = Color(0xFFE6F3FF);
  
  // Secondary colors - Teal
  static const Color secondary = Color(0xFF00B4D8);
  static const Color secondaryLight = Color(0xFF4DC9E6);
  static const Color secondaryDark = Color(0xFF0099CC);
  
  // Accent colors - Coral
  static const Color accent = Color(0xFFFF6B6B);
  static const Color accentLight = Color(0xFFFF8A8A);
  static const Color accentDark = Color(0xFFE55A5A);
  
  // Success colors - Modern Green
  static const Color success = Color(0xFF00C851);
  static const Color successLight = Color(0xFF4CD964);
  static const Color successDark = Color(0xFF00A843);
  static const Color successUltraLight = Color(0xFFE8F5E8);
  
  // Warning colors - Amber
  static const Color warning = Color(0xFFFFB300);
  static const Color warningLight = Color(0xFFFFC107);
  static const Color warningDark = Color(0xFFE6A200);
  static const Color warningUltraLight = Color(0xFFFFF8E1);
  
  // Error colors - Modern Red
  static const Color error = Color(0xFFDC3545);
  static const Color errorLight = Color(0xFFE74C3C);
  static const Color errorDark = Color(0xFFC82333);
  static const Color errorUltraLight = Color(0xFFFFEBEE);
  
  // Light Theme Colors
  static const Color lightBackground = Color(0xFFFAFBFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightDivider = Color(0xFFE9ECEF);
  static const Color lightBorder = Color(0xFFE1E5E9);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightTextTertiary = Color(0xFF9CA3AF);
  static const Color lightTextInverse = Color(0xFFFFFFFF);
  static const Color lightTextMuted = Color(0xFF9CA3AF);
  
  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0F0F0F);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkDivider = Color(0xFF2A2A2A);
  static const Color darkBorder = Color(0xFF333333);
  static const Color darkTextPrimary = Color(0xFFE5E5E5);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkTextTertiary = Color(0xFF808080);
  static const Color darkTextInverse = Color(0xFF000000);
  static const Color darkTextMuted = Color(0xFF808080);
  
  // Legacy colors (for backward compatibility)
  static const Color background = lightBackground;
  static const Color surface = lightSurface;
  static const Color card = lightCard;
  static const Color divider = lightDivider;
  static const Color border = lightBorder;
  static const Color textPrimary = lightTextPrimary;
  static const Color textSecondary = lightTextSecondary;
  static const Color textTertiary = lightTextTertiary;
  static const Color textInverse = lightTextInverse;
  static const Color textMuted = lightTextMuted;
  
  // Status colors
  static const Color info = Color(0xFF0079DC);
  static const Color infoLight = Color(0xFF4DA3FF);
  static const Color infoDark = Color(0xFF0056CC);
  
  // Budget status colors
  static const Color budgetOnTrack = Color(0xFF00C851);
  static const Color budgetWarning = Color(0xFFFFB300);
  static const Color budgetOver = Color(0xFFDC3545);
  
  // Gradient colors - Modern Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [success, successLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient errorGradient = LinearGradient(
    colors: [error, errorLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Shadow colors
  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowMedium = Color(0x1A000000);
  static const Color shadowDark = Color(0x33000000);
  
  // Overlay colors
  static const Color overlayLight = Color(0x80000000);
  static const Color overlayMedium = Color(0xB3000000);
  static const Color overlayDark = Color(0xE6000000);
}


class AppTheme {
  // Typography
  static const String fontFamily = 'Satoshi';
  
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
        onError: AppColors.lightTextInverse,
        outline: AppColors.lightBorder,
        outlineVariant: AppColors.lightDivider,
      ),
      textTheme: lightTextTheme,
      appBarTheme: AppBarTheme(
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
        iconTheme: const IconThemeData(
          color: AppColors.lightTextInverse,
          size: 24,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
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
          textStyle: TextStyle(
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
          textStyle: TextStyle(
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
          textStyle: TextStyle(
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
        labelStyle: TextStyle(
          color: AppColors.lightTextSecondary,
          fontSize: 14,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        hintStyle: TextStyle(
          color: AppColors.lightTextTertiary,
          fontSize: 14,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
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
        labelStyle: TextStyle(
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
        onError: AppColors.darkTextInverse,
        outline: AppColors.darkBorder,
        outlineVariant: AppColors.darkDivider,
      ),
      textTheme: darkTextTheme,
      appBarTheme: AppBarTheme(
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
        iconTheme: const IconThemeData(
          color: AppColors.darkTextPrimary,
          size: 24,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
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
          textStyle: TextStyle(
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
          textStyle: TextStyle(
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
          textStyle: TextStyle(
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
        labelStyle: TextStyle(
          color: AppColors.darkTextSecondary,
          fontSize: 14,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        hintStyle: TextStyle(
          color: AppColors.darkTextTertiary,
          fontSize: 14,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
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
        labelStyle: TextStyle(
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
