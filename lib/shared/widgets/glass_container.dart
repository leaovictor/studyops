import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/design_system/design_tokens.dart';

/// A premium glassmorphism container.
///
/// Renders a frosted-glass effect: blurred background, semi-transparent fill,
/// subtle border, and optional glow. Works over gradient or image backgrounds.
///
/// Usage:
/// ```dart
/// GlassContainer(
///   blur: 12,
///   child: Text('Hello'),
/// )
/// ```
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 10,
    this.opacity = 0.08,
    this.borderRadius,
    this.padding,
    this.margin,
    this.borderColor,
    this.borderWidth = 1.0,
    this.backgroundColor,
    this.width,
    this.height,
    this.boxShadow,
    this.gradient,
  });

  final Widget child;

  /// Blur intensity (default 10).
  final double blur;

  /// Fill opacity on top of the blur layer (0–1). Default 0.08.
  final double opacity;

  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final double borderWidth;

  /// Overrides default fill colour. Mostly used for tinted glass.
  final Color? backgroundColor;

  final double? width;
  final double? height;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final br = borderRadius ?? DesignTokens.brMd;

    final fillColor = backgroundColor ??
        (isDark
            ? Colors.white.withValues(alpha: opacity)
            : Colors.white.withValues(alpha: opacity + 0.55));

    final border = borderColor ??
        (isDark
            ? DesignTokens.darkBorderAccent.withValues(alpha: 0.6)
            : DesignTokens.lightBorderAccent.withValues(alpha: 0.7));

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: boxShadow ?? DesignTokens.elevationLow,
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(DesignTokens.radiusMd),
            decoration: BoxDecoration(
              color: fillColor,
              gradient: gradient,
              borderRadius: br,
              border: Border.all(color: border, width: borderWidth),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
