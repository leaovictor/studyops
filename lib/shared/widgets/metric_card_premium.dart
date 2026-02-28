import 'package:flutter/material.dart';
import '../../core/design_system/design_tokens.dart';
import '../../core/design_system/typography_scale.dart';
import '../../core/design_system/spacing_system.dart';

/// Trend direction for the metric delta indicator.
enum MetricTrend { up, down, neutral }

/// Premium metric card with gradient icon, animated value,
/// trend indicator and optional shimmer loading state.
///
/// Usage:
/// ```dart
/// MetricCardPremium(
///   icon: Icons.bolt,
///   label: 'Study Score',
///   value: '847',
///   subtitle: '+12 esta semana',
///   trend: MetricTrend.up,
///   gradient: DesignTokens.primaryGradient,
/// )
/// ```
class MetricCardPremium extends StatefulWidget {
  const MetricCardPremium({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.trend = MetricTrend.neutral,
    this.gradient,
    this.accentColor,
    this.onTap,
    this.isLoading = false,
    this.badge,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final MetricTrend trend;
  final LinearGradient? gradient;
  final Color? accentColor;
  final VoidCallback? onTap;
  final bool isLoading;

  /// Small badge widget in the top-right corner (e.g. chip or dot).
  final Widget? badge;

  @override
  State<MetricCardPremium> createState() => _MetricCardPremiumState();
}

class _MetricCardPremiumState extends State<MetricCardPremium>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: DesignTokens.durationSlow,
    );
    _fadeIn = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));
    _enterCtrl.forward();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  Color get _accent => widget.accentColor ?? DesignTokens.primary;

  LinearGradient get _gradient =>
      widget.gradient ?? DesignTokens.primaryGradient;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? DesignTokens.darkBg3 : DesignTokens.lightBg1;
    final borderColor =
        isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder;

    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideIn,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: DesignTokens.durationNormal,
            padding: Spacing.cardPaddingSm,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: DesignTokens.brMd,
              border: Border.all(color: borderColor),
              boxShadow: DesignTokens.elevationLow,
            ),
            child: widget.isLoading
                ? _buildShimmer(isDark)
                : _buildContent(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            // Gradient icon box
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: _gradient,
                borderRadius: DesignTokens.brSm,
                boxShadow: DesignTokens.glowPrimary,
              ),
              child: Icon(widget.icon, color: Colors.white, size: 18),
            ),
            const Spacer(),
            if (widget.badge != null) widget.badge!,
            if (widget.trend != MetricTrend.neutral) _buildTrendChip(),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            widget.value,
            style: AppTypography.scoreSm.copyWith(color: _accent),
          ),
        ),
        const SizedBox(height: Spacing.xxs),
        Text(
          widget.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelMd.copyWith(
            color: isDark
                ? DesignTokens.darkTextSecondary
                : DesignTokens.lightTextSecondary,
          ),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            widget.subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: isDark
                  ? DesignTokens.darkTextMuted
                  : DesignTokens.lightTextMuted,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTrendChip() {
    final isUp = widget.trend == MetricTrend.up;
    final color = isUp ? DesignTokens.accent : DesignTokens.error;
    final icon = isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: DesignTokens.brXl,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            isUp ? '↑' : '↓',
            style: AppTypography.labelSm.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    final shimmerColor = isDark
        ? DesignTokens.darkBg4.withValues(alpha: 0.6)
        : DesignTokens.lightBg3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _shimmerBox(shimmerColor, 36, 36),
        const SizedBox(height: Spacing.sm),
        _shimmerBox(shimmerColor, 60, 20),
        const SizedBox(height: Spacing.xxs),
        _shimmerBox(shimmerColor, double.infinity, 12),
      ],
    );
  }

  Widget _shimmerBox(Color c, double w, double h) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: c,
          borderRadius: DesignTokens.brSm,
        ),
      );
}
