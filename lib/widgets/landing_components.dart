import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class LandingTheme {
  static const Color background = Color(0xFF0B1220);
  static const Color cardBg = Color(0xFF151A2C);
  static const Color primary = Color(0xFF7C6FFF); // Electric Blue/Purple
  static const Color secondary = Color(0xFF06B6D4);
  static const Color accent = Color(0xFF10B981);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color border = Color(0xFF2D3748);

  static const double horizontalPadding = 24.0;
  static const double maxWidth = 1200.0;
}

class LandingNavbar extends StatelessWidget {
  final VoidCallback onCreateAccount;
  final VoidCallback onLogin;

  const LandingNavbar({
    super.key,
    required this.onCreateAccount,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LandingTheme.horizontalPadding,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: LandingTheme.background.withValues(alpha: 0.8),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: LandingTheme.maxWidth),
          child: Row(
            children: [
              Text(
                'StudyOps',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: LandingTheme.textPrimary,
                  letterSpacing: -1,
                ),
              ),
              const Spacer(),
              if (MediaQuery.of(context).size.width > 600) ...[
                TextButton(
                  onPressed: onLogin,
                  child: Text(
                    'Entrar',
                    style: GoogleFonts.inter(
                      color: LandingTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              ElevatedButton(
                onPressed: onCreateAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LandingTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Criar conta gratuita',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LandingSection extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final double verticalPadding;

  const LandingSection({
    super.key,
    required this.child,
    this.backgroundColor,
    this.verticalPadding = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: backgroundColor ?? LandingTheme.background,
      padding: EdgeInsets.symmetric(
        vertical: verticalPadding,
        horizontal: LandingTheme.horizontalPadding,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: LandingTheme.maxWidth),
          child: child,
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: LandingTheme.cardBg.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: borderColor ?? LandingTheme.border.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlowText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Color glowColor;

  const GlowText({
    super.key,
    required this.text,
    required this.style,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style.copyWith(
        shadows: [
          Shadow(
            color: glowColor.withValues(alpha: 0.5),
            blurRadius: 20,
          ),
        ],
      ),
    );
  }
}
