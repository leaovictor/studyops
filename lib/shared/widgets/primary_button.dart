import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/design_system/design_tokens.dart';
import '../../core/design_system/typography_scale.dart';

/// Button state enum for PrimaryButton.
enum _BtnState { idle, loading, success }

/// Premium animated primary button with loading and success states.
///
/// Usage:
/// ```dart
/// PrimaryButton(
///   label: 'Começar',
///   icon: Icons.rocket_launch,
///   onPressed: _handlePress,
///   isLoading: state.isLoading,
/// )
/// ```
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isSuccess = false,
    this.gradient,
    this.backgroundColor,
    this.foregroundColor = Colors.white,
    this.width,
    this.height = 52.0,
    this.borderRadius,
    this.fontSize,
    this.disabled = false,
    this.haptic = true,
    this.shadow = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isSuccess;
  final LinearGradient? gradient;
  final Color? backgroundColor;
  final Color foregroundColor;
  final double? width;
  final double height;
  final double? borderRadius;
  final double? fontSize;
  final bool disabled;
  final bool haptic;
  final bool shadow;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _scaleCtrl;
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  _BtnState get _state {
    if (widget.isSuccess) return _BtnState.success;
    if (widget.isLoading) return _BtnState.loading;
    return _BtnState.idle;
  }

  bool get _interactive =>
      !widget.disabled && _state == _BtnState.idle && widget.onPressed != null;

  void _onTapDown(_) {
    if (!_interactive) return;
    _scaleCtrl.reverse();
  }

  void _onTapUp(_) {
    if (!_interactive) return;
    _scaleCtrl.forward();
  }

  void _onTap() {
    if (!_interactive) return;
    if (widget.haptic) HapticFeedback.lightImpact();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final br = widget.borderRadius ?? DesignTokens.radiusMd.toDouble();
    final grad = widget.gradient ?? DesignTokens.primaryGradient;
    final fg = widget.foregroundColor;

    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) => Transform.scale(
        scale: _scale.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: () => _scaleCtrl.forward(),
        onTap: _onTap,
        child: AnimatedContainer(
          duration: DesignTokens.durationNormal,
          curve: DesignTokens.curveDefault,
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: _interactive ? grad : null,
            color: _interactive
                ? null
                : (widget.disabled
                    ? DesignTokens.darkBg4
                    : _state == _BtnState.success
                        ? DesignTokens.accent
                        : DesignTokens.primary),
            borderRadius: BorderRadius.circular(br),
            boxShadow:
                (widget.shadow && _interactive) ? DesignTokens.glowPrimary : [],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: DesignTokens.durationNormal,
              child: _buildContent(fg),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Color fg) {
    switch (_state) {
      case _BtnState.loading:
        return SizedBox(
          key: const ValueKey('loading'),
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(fg),
          ),
        );

      case _BtnState.success:
        return Row(
          key: const ValueKey('success'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, color: fg, size: 20),
            const SizedBox(width: 8),
            Text(
              'Concluído',
              style: AppTypography.labelLg.copyWith(color: fg),
            ),
          ],
        );

      case _BtnState.idle:
        return Row(
          key: const ValueKey('idle'),
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: fg, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              widget.label,
              style: AppTypography.labelLg.copyWith(
                color: widget.disabled ? DesignTokens.darkTextMuted : fg,
                fontSize: widget.fontSize,
              ),
            ),
          ],
        );
    }
  }
}
