import 'package:flutter/material.dart';

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
