import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_tokens.dart';

/// Semantic typography scale for StudyOps.
/// All text styles use Inter via google_fonts.
abstract final class AppTypography {
  AppTypography._();

  // ─── Display ──────────────────────────────────────────────────────────────
  static TextStyle get displayLg => GoogleFonts.inter(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.5,
        height: 1.1,
      );

  static TextStyle get displayMd => GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        height: 1.15,
      );

  static TextStyle get displaySm => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
      );

  // ─── Heading ──────────────────────────────────────────────────────────────
  static TextStyle get headingLg => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.3,
      );

  static TextStyle get headingMd => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.35,
      );

  static TextStyle get headingSm => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.4,
      );

  // ─── Body ─────────────────────────────────────────────────────────────────
  static TextStyle get bodyLg => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
      );

  static TextStyle get bodyMd => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.55,
      );

  static TextStyle get bodySm => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  // ─── Label ────────────────────────────────────────────────────────────────
  static TextStyle get labelLg => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMd => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );

  static TextStyle get labelSm => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      );

  // ─── Numeric / score ──────────────────────────────────────────────────────
  static TextStyle get scoreLg => GoogleFonts.inter(
        fontSize: 40,
        fontWeight: FontWeight.w900,
        letterSpacing: -2,
        height: 1.0,
      );

  static TextStyle get scoreMd => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        height: 1.0,
      );

  static TextStyle get scoreSm => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.0,
      );

  // ─── Caption / helper ─────────────────────────────────────────────────────
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: DesignTokens.darkTextMuted,
        height: 1.4,
      );

  static TextStyle get overline => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      );

  // ─── Convenience: apply colour ────────────────────────────────────────────
  static TextStyle withColor(TextStyle base, Color color) =>
      base.copyWith(color: color);
}
