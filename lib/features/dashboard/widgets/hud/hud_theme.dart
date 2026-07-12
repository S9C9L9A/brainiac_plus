import 'package:flutter/material.dart';

/// Design tokens for the Jarvis-style command HUD: a holographic readout on
/// near-black, cyan as the resting state, amber and red only when the system
/// asks for attention. Colours are load-driven, never decorative.
class HudTheme {
  HudTheme._();

  /// Deep-space base the whole HUD floats on.
  static const Color background = Color(0xFF04070E);
  static const Color panel = Color(0xFF0A121F);

  /// Resting / nominal — the signature hologram cyan.
  static const Color cyan = Color(0xFF38BDF8);
  static const Color cyanGlow = Color(0xFF67E8F9);

  /// Elevated load.
  static const Color amber = Color(0xFFFBBF24);

  /// Critical load.
  static const Color danger = Color(0xFFFB7185);

  static const Color gridLine = Color(0x1A38BDF8);

  /// Load → colour band. Cyan below 50, amber to 85, red above.
  static Color statusColor(double percent) {
    if (percent >= 85) return danger;
    if (percent >= 50) return amber;
    return cyan;
  }

  /// Load → HUD wording for the same bands.
  static String statusLabel(double percent) {
    if (percent >= 85) return 'CRITICAL';
    if (percent >= 50) return 'ELEVATED';
    return 'NOMINAL';
  }

  static double clampPercent(double percent) =>
      percent.clamp(0, 100).toDouble();
}
