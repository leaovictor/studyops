import 'package:flutter/material.dart';
import '../../core/design_system/design_tokens.dart';
import '../../core/design_system/typography_scale.dart';

/// Animated progress bar with gradient fill, animated percentage label,
/// and optional title row.
///
/// Usage:
/// ```dart
/// AnimatedProgress(
///   value: 0.72,
///   label: 'Direito Constitucional',
///   gradient: DesignTokens.primaryGradient,
/// )
/// ```
class AnimatedProgress extends StatefulWidget {
  const AnimatedProgress({
    super.key,
    required this.value,
    this.label,
    this.subtitle,
    this.gradient,
    this.backgroundColor,
    this.height = 8,
    this.animationDuration,
    this.showPercentage = true,
    this.borderRadius,
    this.trailing,
  }) : assert(value >= 0 && value <= 1, 'value must be between 0.0 and 1.0');

  /// Progress value between 0.0 and 1.0.
  final double value;
  final String? label;
  final String? subtitle;
  final LinearGradient? gradient;
  final Color? backgroundColor;
  final double height;
  final Duration? animationDuration;
  final bool showPercentage;
  final double? borderRadius;

  /// Widget placed at trailing end of the label row.
  final Widget? trailing;

  @override
  State<AnimatedProgress> createState() => _AnimatedProgressState();
}

class _AnimatedProgressState extends State<AnimatedProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _animation;
  double _targetValue = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.animationDuration ?? DesignTokens.durationXSlow,
    );
    _targetValue = widget.value;
    _animation = Tween<double>(begin: 0, end: _targetValue).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgress old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      final from = _animation.value;
      _targetValue = widget.value;
      _animation = Tween<double>(begin: from, end: _targetValue).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
      );
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  LinearGradient get _gradient =>
      widget.gradient ?? DesignTokens.primaryGradient;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = widget.backgroundColor ??
        (isDark ? DesignTokens.darkBg4 : DesignTokens.lightBg3);
    final br = widget.borderRadius ?? DesignTokens.radiusFull;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final pct = _animation.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.label != null || widget.showPercentage) ...[
              Row(
                children: [
                  if (widget.label != null)
                    Expanded(
                      child: Text(
                        widget.label!,
                        style: AppTypography.labelMd.copyWith(
                          color: isDark
                              ? DesignTokens.darkTextPrimary
                              : DesignTokens.lightTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (widget.trailing != null) widget.trailing!,
                  if (widget.showPercentage && widget.trailing == null)
                    Text(
                      '${(pct * 100).toStringAsFixed(0)}%',
                      style: AppTypography.labelSm.copyWith(
                        color: DesignTokens.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            Stack(
              children: [
                // Background track
                Container(
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(br),
                  ),
                ),
                // Filled portion
                FractionallySizedBox(
                  widthFactor: pct.clamp(0.0, 1.0),
                  child: Container(
                    height: widget.height,
                    decoration: BoxDecoration(
                      gradient: _gradient,
                      borderRadius: BorderRadius.circular(br),
                      boxShadow: [
                        BoxShadow(
                          color: DesignTokens.primary.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.subtitle!,
                style: AppTypography.caption.copyWith(
                  color: isDark
                      ? DesignTokens.darkTextMuted
                      : DesignTokens.lightTextMuted,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
