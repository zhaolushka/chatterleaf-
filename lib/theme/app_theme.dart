import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../logic/mood.dart';

/// Tamyr design tokens — same values as the Figma/canvas mockups.
class AppColors {
  static const background = Color(0xFFFAF7F0); // milk
  static const ink = Color(0xFF2A2530);
  static const muted = Color(0xFF6E6878);
  static const black = Color(0xFF211D26); // primary buttons, active nav
  static const lime = Color(0xFFC9F26B); // brand accent
  static const limeDark = Color(0xFF9BCB2E);
  static const red = Color(0xFFE5484D);
  static const yellow = Color(0xFFF5B82E);
  static const green = Color(0xFF3E9B5A);
  static const sky = Color(0xFF5AA9F7);
  static const field = Color(0xFFF6F2EA);
  static const track = Color(0xFFF0EBE1);

  /// Pastel card colour of each plant.
  static Color pastel(String cropKey) => switch (cropKey) {
        'tomato' => const Color(0xFFFFE3DD),
        'cucumber' => const Color(0xFFDFF2DC),
        'strawberry' => const Color(0xFFFFE2EA),
        _ => const Color(0xFFEAF3D6),
      };

  /// Glow behind the character.
  static Color glow(String cropKey) => switch (cropKey) {
        'tomato' => const Color(0xFFFFC9BE),
        'cucumber' => const Color(0xFFBFE6B8),
        'strawberry' => const Color(0xFFFFC4D3),
        _ => const Color(0xFFD6EBAE),
      };

  static Color forMood(Mood m) => switch (m) {
        Mood.happy => green,
        Mood.hot => red,
        Mood.cold => sky,
        Mood.thirsty => yellow,
        Mood.sleepy => muted,
      };

  static const softShadow = [
    BoxShadow(color: Color(0x0A211D26), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x12211D26), blurRadius: 32, offset: Offset(0, 12)),
  ];
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.green,
      primary: AppColors.black,
      onPrimary: Colors.white,
      secondary: AppColors.lime,
      onSecondary: AppColors.ink,
      error: AppColors.red,
      surface: Colors.white,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.background,
  );

  // google_fonts' TextTheme helpers target flutter/material types, so fonts are applied per style.
  TextStyle n(TextStyle? s, FontWeight w) => GoogleFonts.nunito(textStyle: s, fontWeight: w);
  final t = base.textTheme;
  final text = t.copyWith(
    displayLarge: n(t.displayLarge, FontWeight.w900),
    displayMedium: n(t.displayMedium, FontWeight.w900),
    displaySmall: n(t.displaySmall, FontWeight.w900),
    headlineLarge: n(t.headlineLarge, FontWeight.w900),
    headlineMedium: n(t.headlineMedium, FontWeight.w900),
    headlineSmall: n(t.headlineSmall, FontWeight.w900),
    titleLarge: n(t.titleLarge, FontWeight.w900),
    titleMedium: n(t.titleMedium, FontWeight.w800),
    titleSmall: n(t.titleSmall, FontWeight.w800),
    bodyLarge: n(t.bodyLarge, FontWeight.w600),
    bodyMedium: n(t.bodyMedium, FontWeight.w600),
    bodySmall: n(t.bodySmall, FontWeight.w600),
    labelLarge: n(t.labelLarge, FontWeight.w800),
    labelMedium: n(t.labelMedium, FontWeight.w800),
    labelSmall: n(t.labelSmall, FontWeight.w800),
  );

  return base.copyWith(
    textTheme: text.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
    appBarTheme: const AppBarTheme(backgroundColor: AppColors.background, foregroundColor: AppColors.ink, elevation: 0),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.black,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentTextStyle: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: AppColors.limeDark, width: 2),
      ),
    ),
  );
}

/// Shortcut for the Nunito text style used across screens.
TextStyle nunito(double size, FontWeight weight, {Color color = AppColors.ink, double? height, double? spacing}) =>
    GoogleFonts.nunito(fontSize: size, fontWeight: weight, color: color, height: height, letterSpacing: spacing);
