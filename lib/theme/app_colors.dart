import 'package:material_ui/material_ui.dart';

class AppColors {
  static const primary = Color(0xFF2E7D32); // leaf green
  static const secondary = Color(0xFFE8F5E9); // soft mint
  static const accent = Color(0xFFF9A825); // sun yellow
  static const alert = Color(0xFFE53935); // tomato red
  static const text = Color(0xFF263238); // dark gray
  static const muted = Color(0xFF607D8B);
  static const surface = Color(0xFFF7FBF7);
  static const cardGreen = Color(0xFF66BB6A);
  static const cardYellow = Color(0xFFFFB300);
  static const cardRed = Color(0xFFE53935);

  /// Green / yellow / red for reading cards (M2).
  static Color statusFor({
    required double value,
    required double min,
    required double max,
    bool lightOnly = false,
  }) {
    if (lightOnly) {
      if (value < min) return cardRed;
      if (value < min * 1.2) return cardYellow;
      return cardGreen;
    }
    if (value < min || value > max) return cardRed;
    final margin = (max - min) * 0.15;
    if (value < min + margin || value > max - margin) return cardYellow;
    return cardGreen;
  }
}
