import 'package:flutter/material.dart';
import '../core/design_system/design_tokens.dart';
import '../core/design_system/typography_scale.dart';

/// Shows a premium XP award overlay at the bottom of the screen.
/// Used after a Pomodoro session is saved or any gamification event.
///
/// Usage:
/// ```dart
/// XpToast.show(context, xp: 50, label: 'Pomodoro Completo!');
/// ```
abstract final class XpToast {
  XpToast._();

  static void show(
    BuildContext context, {
    required int xp,
    required String label,
    IconData icon = Icons.bolt_rounded,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _XpToastWidget(
        xp: xp,
        label: label,
        icon: icon,
        duration: duration,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _XpToastWidget extends StatefulWidget {
  const _XpToastWidget({
    required this.xp,
    required this.label,
    required this.icon,
    required this.duration,
    required this.onDismiss,
  });

  final int xp;
  final String label;
  final IconData icon;
  final Duration duration;
  final VoidCallback onDismiss;

  @override
  State<_XpToastWidget> createState() => _XpToastWidgetState();
}

class _XpToastWidgetState extends State<_XpToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slideUp;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _slideUp = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    _ctrl.forward();

    Future.delayed(widget.duration, () async {
      if (mounted) {
        await _ctrl.reverse();
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 80,
      left: 24,
      right: 24,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, _slideUp.value),
          child: Opacity(opacity: _fade.value, child: child),
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C6FFF), Color(0xFF00D9AA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: DesignTokens.brXl,
              boxShadow: [
                BoxShadow(
                  color: DesignTokens.primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        style: AppTypography.bodySm.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      Text(
                        '+${widget.xp} XP',
                        style: AppTypography.headingSm.copyWith(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.stars_rounded, color: Colors.white, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
