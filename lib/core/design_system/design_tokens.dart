import 'package:flutter/material.dart';

/// Single source of truth for all visual design tokens in StudyOps.
/// Every colour, radius, shadow, gradient and animation duration lives here.
abstract final class DesignTokens {
  DesignTokens._();

  // ─── Brand colours ────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF7C6FFF); // deep indigo-purple
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color primaryDark = Color(0xFF5B4FD9);

  static const Color secondary = Color(0xFF06B6D4); // electric cyan
  static const Color secondaryLight = Color(0xFF67E8F9);
  static const Color secondaryDark = Color(0xFF0891B2);

  static const Color accent = Color(0xFF10B981); // emerald green
  static const Color accentLight = Color(0xFF6EE7B7);
  static const Color accentDark = Color(0xFF059669);

  static const Color warning = Color(0xFFF59E0B); // amber
  static const Color error = Color(0xFFEF4444); // red-500
  static const Color errorLight = Color(0xFFFCA5A5);
  static const Color success = Color(0xFF22C55E); // green-500

  // ─── Dark surface palette ──────────────────────────────────────────────────
  static const Color darkBg0 = Color(0xFF0A0A14); // deepest background
  static const Color darkBg1 = Color(0xFF0F0F1A); // scaffold bg
  static const Color darkBg2 = Color(0xFF16162A); // card surface
  static const Color darkBg3 = Color(0xFF1E1E35); // elevated card
  static const Color darkBg4 = Color(0xFF252540); // input / chip
  static const Color darkBorder = Color(0xFF2A2A45);
  static const Color darkBorderAccent = Color(0xFF3D3D60);

  // ─── Dark text ────────────────────────────────────────────────────────────
  static const Color darkTextPrimary = Color(0xFFF1F1F5);
  static const Color darkTextSecondary = Color(0xFF9898B0);
  static const Color darkTextMuted = Color(0xFF5A5A78);

  // ─── Light surface palette ─────────────────────────────────────────────────
  static const Color lightBg0 = Color(0xFFFAFAFA);
  static const Color lightBg1 = Color(0xFFFFFFFF);
  static const Color lightBg2 = Color(0xFFF0F0F8);
  static const Color lightBg3 = Color(0xFFE8E8F0);
  static const Color lightBorder = Color(0xFFE0E0EE);
  static const Color lightBorderAccent = Color(0xFFC8C8DC);

  // ─── Light text ───────────────────────────────────────────────────────────
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF5A5A78);
  static const Color lightTextMuted = Color(0xFF9898B0);

  // ─── Border radii ─────────────────────────────────────────────────────────
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 9999;

  static const BorderRadius brXs = BorderRadius.all(Radius.circular(radiusXs));
  static const BorderRadius brSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius brXl = BorderRadius.all(Radius.circular(radiusXl));

  // ─── Gradients ────────────────────────────────────────────────────────────
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

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [darkBg1, darkBg0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Shadows ──────────────────────────────────────────────────────────────
  static List<BoxShadow> get elevationLow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevationMid => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get glowPrimary => [
        BoxShadow(
          color: primary.withValues(alpha: 0.35),
          blurRadius: 24,
          spreadRadius: -4,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get glowAccent => [
        BoxShadow(
          color: accent.withValues(alpha: 0.3),
          blurRadius: 20,
          spreadRadius: -4,
          offset: const Offset(0, 6),
        ),
      ];

  // ─── Animation durations ──────────────────────────────────────────────────
  static const Duration durationFast = Duration(milliseconds: 120);
  static const Duration durationNormal = Duration(milliseconds: 220);
  static const Duration durationSlow = Duration(milliseconds: 380);
  static const Duration durationXSlow = Duration(milliseconds: 600);

  static const Curve curveDefault = Curves.easeOutCubic;
  static const Curve curveBounce = Curves.elasticOut;
  static const Curve curveSharp = Curves.easeInOutQuart;
}
