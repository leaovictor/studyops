import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class QuizTopBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onExit;
  final double fontSizeDelta;
  final Function(double) onFontSizeChanged;

  const QuizTopBar({
    super.key,
    required this.title,
    required this.onExit,
    required this.fontSizeDelta,
    required this.onFontSizeChanged,
  });

  @override
  State<QuizTopBar> createState() => _QuizTopBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _QuizTopBarState extends State<QuizTopBar> {
  late Stopwatch _stopwatch;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF0B1220),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: Colors.white70),
        onPressed: widget.onExit,
      ),
      title: Text(
        widget.title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        // Font size controls
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FontSizeButton(
              label: 'A-',
              onTap: () => widget.onFontSizeChanged(widget.fontSizeDelta - 2),
              enabled: widget.fontSizeDelta > -4,
            ),
            _FontSizeButton(
              label: 'A+',
              onTap: () => widget.onFontSizeChanged(widget.fontSizeDelta + 2),
              enabled: widget.fontSizeDelta < 8,
            ),
          ],
        ),
        const SizedBox(width: 8),
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined,
                  size: 14, color: AppTheme.primary),
              const SizedBox(width: 4),
              Text(
                _formatDuration(_stopwatch.elapsed),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FontSizeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  const _FontSizeButton({
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: enabled ? Colors.white70 : Colors.white24,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
