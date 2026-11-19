import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// Nunito headings + Inter body (brief). google_fonts TextTheme helpers still
/// target flutter/material types, so we apply fonts via TextStyle APIs.
ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.alert,
      surface: AppColors.surface,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.secondary,
  );

  TextStyle inter(TextStyle? s) => GoogleFonts.inter(textStyle: s);
  TextStyle nunito(TextStyle? s) => GoogleFonts.nunito(textStyle: s);

  final text = base.textTheme.copyWith(
    displayLarge: nunito(base.textTheme.displayLarge),
    displayMedium: nunito(base.textTheme.displayMedium),
    displaySmall: nunito(base.textTheme.displaySmall),
    headlineLarge: nunito(base.textTheme.headlineLarge),
    headlineMedium: nunito(base.textTheme.headlineMedium),
    headlineSmall: nunito(base.textTheme.headlineSmall),
    titleLarge: nunito(base.textTheme.titleLarge),
    titleMedium: nunito(base.textTheme.titleMedium),
    titleSmall: nunito(base.textTheme.titleSmall),
    bodyLarge: inter(base.textTheme.bodyLarge),
    bodyMedium: inter(base.textTheme.bodyMedium),
    bodySmall: inter(base.textTheme.bodySmall),
    labelLarge: inter(base.textTheme.labelLarge),
    labelMedium: inter(base.textTheme.labelMedium),
    labelSmall: inter(base.textTheme.labelSmall),
  );

  return base.copyWith(
    textTheme: text.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.muted,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.primary : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.primary.withValues(alpha: 0.4)
            : null,
      ),
    ),
  );
}
