import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  // Primary colors - Modern Blue (#0079dc)
  static const Color primary = Color(0xFF0079DC);
  static const Color primaryLight = primary;
  static const Color primaryDark = primary;
  static const Color primaryUltraLight = Color(0xFFF2F2F2);

  // Secondary colors - Teal
  static const Color secondary = Color(0xFF555555);
  static const Color secondaryLight = Color(0xFF888888);
  static const Color secondaryDark = Color(0xFF333333);

  // Tertiary colors - Premium navy for supporting actions and emphasis
  static const Color tertiary = Color(0xFF122235);
  static const Color tertiaryLight = Color(0xFF243B53);
  static const Color tertiaryDark = Color(0xFF0B1623);
  static const Color tertiaryContainer = Color(0xFFE8EEF5);

  // Accent colors - Coral
  static const Color accent = Color(0xFFE76F51);
  static const Color accentLight = Color(0xFFF28B73);
  static const Color accentDark = Color(0xFFC9563C);

  // Success colors - Modern Green
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFF4ADE80);
  static const Color successDark = Color(0xFF15803D);
  static const Color successUltraLight = Color(0xFFDCFCE7);

  // Warning colors - Amber
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFB45309);
  static const Color warningUltraLight = Color(0xFFFEF3C7);

  // Error colors - Modern Red
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFEF4444);
  static const Color errorDark = Color(0xFFB91C1C);
  static const Color errorUltraLight = Color(0xFFFEE2E2);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF6F6F6);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightDivider = Color(0xFFE8E8E8);
  static const Color lightBorder = Colors.transparent;
  static const Color lightTextPrimary = Color(0xFF111111);
  static const Color lightTextSecondary = Color(0xFF666666);
  static const Color lightTextTertiary = Color(0xFF999999);
  static const Color lightTextInverse = Color(0xFFFFFFFF);
  static const Color lightTextMuted = Color(0xFF999999);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0B1220);
  static const Color darkSurface = Color(0xFF101A2A);
  static const Color darkCard = Color(0xFF162235);
  static const Color darkDivider = Color(0xFF26384D);
  static const Color darkBorder = Color(0xFF30455D);
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
  static const Color darkTextTertiary = Color(0xFF808080);
  static const Color darkTextInverse = Color(0xFFFFFFFF);
  static const Color darkTextMuted = Color(0xFF808080);
  // Navy-toned elevated surface used by muted cards and dark containers.
  static const Color darkElevatedSurface = Color(0xFF182A40);
  // Floating navigation surface. Keep it aligned with the redesigned navy
  // card palette instead of the legacy near-black navigation bar.
  static const Color darkNavSurface = darkCard;

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
  static const Color info = primary;
  static const Color infoLight = primary;
  static const Color infoDark = primary;

  // Budget status colors
  static const Color budgetOnTrack = success;
  static const Color budgetWarning = warning;
  static const Color budgetOver = error;

  // Brand colors (third-party)
  static const Color googleRed = Color(0xFFDB4437);

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
  static const String fontFamily = 'Geist';

  // Shared form-control geometry
  static const double formFieldRadius = 16;

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

  // Semantic layout tokens. Prefer these names in shared components so
  // screens do not slowly drift into different visual systems.
  static const double pagePadding = spacing16;
  static const double sectionGap = spacing24;
  static const double cardRadius = radius24;
  static const double controlRadius = radius12;
  static const double smallIconSize = 18.0;
  static const double mediumIconSize = 20.0;

  // Border radius
  static const double radius4 = 4.0;
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius20 = 20.0;
  static const double radius24 = 24.0;
  static const double radius32 = 32.0;

  static Color pageBackground(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
  }

  /// The primary page surface used by the redesigned feature screens.
  /// Light mode stays white; dark mode uses the deep navy app background.
  static Color pageSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkBackground
        : Colors.white;
  }

  static Color cardSurface(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? AppColors.darkCard
        : Colors.white;
  }

  static Color mutedSurface(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? AppColors.darkElevatedSurface
        : const Color(0xFFFAFAFA);
  }

  static Color navigationBarSurface(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? AppColors.darkNavSurface
        : AppColors.lightBackground;
  }

  static Color navigationBarBorder(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? AppColors.darkBorder.withValues(alpha: 0.65)
        : AppColors.lightDivider;
  }

  static Color navigationBarShadow(BuildContext context) {
    final theme = Theme.of(context);
    return Colors.black.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.26 : 0.10,
    );
  }

  static BoxDecoration surfaceDecoration(
    BuildContext context, {
    double radius = cardRadius,
    bool subtle = false,
  }) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: subtle ? mutedSurface(context) : cardSurface(context),
      borderRadius: BorderRadius.circular(radius),
      border: theme.brightness == Brightness.dark
          ? Border.all(color: AppColors.darkBorder.withValues(alpha: 0.55))
          : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.24 : 0.035),
          blurRadius: subtle ? 10 : 14,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration tintedSurfaceDecoration(
    BuildContext context, {
    required Color tint,
    double radius = cardRadius,
  }) {
    final theme = Theme.of(context);
    return BoxDecoration(
      // Cards stay monochrome by default. Accent colors belong to icons,
      // progress, and the deliberately emphasized dashboard hero card.
      color: cardSurface(context),
      borderRadius: BorderRadius.circular(radius),
      border: theme.brightness == Brightness.dark
          ? Border.all(color: AppColors.darkBorder.withValues(alpha: 0.55))
          : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.20 : 0.025),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static TextStyle sectionTitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.headlineSmall!.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        );
  }

  static TextStyle sectionSubtitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62),
          fontWeight: FontWeight.w500,
        );
  }

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

  /// One switch style for the whole app: white thumb, brand-blue track when
  /// on, a visible neutral track when off (M3's default off track is the
  /// surface colour, which vanishes on white cards).
  static SwitchThemeData _switchTheme(Brightness b) {
    final dark = b == Brightness.dark;
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled)) {
          return dark ? AppColors.darkBorder : AppColors.lightDivider;
        }
        return Colors.white;
      }),
      trackColor: WidgetStateProperty.resolveWith((s) {
        final on = s.contains(WidgetState.selected);
        if (s.contains(WidgetState.disabled)) {
          return (on ? AppColors.primary : (dark ? AppColors.darkDivider : AppColors.lightDivider))
              .withValues(alpha: 0.5);
        }
        if (on) return AppColors.primary;
        return dark ? AppColors.darkBorder : const Color(0xFFD5D9E0);
      }),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      thumbIcon: const WidgetStatePropertyAll(null),
    );
  }

  // Light theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: Brightness.light,
      switchTheme: _switchTheme(Brightness.light),
      scaffoldBackgroundColor: AppColors.lightBackground,
      canvasColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryUltraLight,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryLight,
        tertiary: AppColors.tertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
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
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppColors.lightTextPrimary,
          fontFamily: fontFamily,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.lightTextPrimary,
          size: 24,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: AppColors.lightBackground,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.lightBackground,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarDividerColor: AppColors.lightBackground,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius16),
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
            borderRadius: BorderRadius.circular(controlRadius),
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
            borderRadius: BorderRadius.circular(controlRadius),
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
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
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
        backgroundColor: AppColors.lightBackground,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
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
      switchTheme: _switchTheme(Brightness.dark),
      scaffoldBackgroundColor: AppColors.darkBackground,
      canvasColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        primaryContainer: AppColors.darkElevatedSurface,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryDark,
        tertiary: AppColors.tertiaryLight,
        tertiaryContainer: AppColors.tertiaryDark,
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
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppColors.darkTextPrimary,
          fontFamily: fontFamily,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.darkTextPrimary,
          size: 24,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: AppColors.darkBackground,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.darkBackground,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarDividerColor: AppColors.darkBackground,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius16),
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
            borderRadius: BorderRadius.circular(controlRadius),
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
            borderRadius: BorderRadius.circular(controlRadius),
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
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
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
        backgroundColor: AppColors.darkNavSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
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

/// Motion + haptics rules for the app. Any transient UI animation (button
/// press states, entrance transitions, toggles) should use these tokens
/// instead of ad-hoc `Duration`/`Curve` literals, so motion feels consistent
/// screen to screen. Haptics follow the same idea: use [AppHaptics] at the
/// moments listed below rather than calling `HapticFeedback` directly, so the
/// vocabulary (what a "selection" vs a "success" feels like) stays uniform.
class AppMotion {
  const AppMotion._();

  // Durations
  static const Duration fast = Duration(
      milliseconds: 150); // micro-interactions: toggles, button presses
  static const Duration medium =
      Duration(milliseconds: 250); // card/section transitions
  static const Duration slow =
      Duration(milliseconds: 400); // screen-level entrances

  // Curves
  static const Curve standard =
      Curves.easeOutCubic; // default for most transitions
  static const Curve emphasized =
      Curves.easeOutBack; // draws attention (success states, confirmations)
}

/// Haptic feedback vocabulary. Call at the point of user action, not on
/// result arrival (e.g. on button tap, not after the async call resolves).
class AppHaptics {
  const AppHaptics._();

  /// Selecting/toggling something (type pickers, switches, chips).
  static void selection() => HapticFeedback.selectionClick();

  /// A lightweight, frequent tap (icon buttons, list taps).
  static void tap() => HapticFeedback.lightImpact();

  /// A primary action succeeded (save, submit, confirm).
  static void success() => HapticFeedback.mediumImpact();

  /// A primary action failed or was blocked (validation error, request failure).
  static void error() => HapticFeedback.heavyImpact();
}
