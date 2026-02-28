import 'package:flutter/material.dart';
import '../../core/design_system/design_tokens.dart';
import '../../core/design_system/typography_scale.dart';
import '../../core/design_system/spacing_system.dart';

/// ──────────────────────────────────────────────────────────────────────────
/// AppLoadingView
/// ──────────────────────────────────────────────────────────────────────────
/// Centered loading spinner with optional message.
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(DesignTokens.primary),
              backgroundColor:
                  isDark ? DesignTokens.darkBg4 : DesignTokens.lightBg3,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: Spacing.md),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(
                color: isDark
                    ? DesignTokens.darkTextSecondary
                    : DesignTokens.lightTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ──────────────────────────────────────────────────────────────────────────
/// AppEmptyView
/// ──────────────────────────────────────────────────────────────────────────
/// Empty state with icon, title, optional subtitle and optional CTA button.
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_rounded,
    this.iconColor,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ic = iconColor ?? DesignTokens.darkTextMuted;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(Spacing.lg),
              decoration: BoxDecoration(
                color: ic.withValues(alpha: 0.08),
                borderRadius: DesignTokens.brXl,
              ),
              child: Icon(icon, size: 48, color: ic),
            ),
            const SizedBox(height: Spacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.headingSm.copyWith(
                color: isDark
                    ? DesignTokens.darkTextPrimary
                    : DesignTokens.lightTextPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: Spacing.xs),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(
                  color: isDark
                      ? DesignTokens.darkTextSecondary
                      : DesignTokens.lightTextSecondary,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: Spacing.lg),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  backgroundColor: DesignTokens.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.lg,
                    vertical: Spacing.sm + Spacing.xs,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: DesignTokens.brMd,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ──────────────────────────────────────────────────────────────────────────
/// AppErrorView
/// ──────────────────────────────────────────────────────────────────────────
/// Error state with icon, message and optional retry button.
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Tentar novamente',
    this.icon = Icons.wifi_off_rounded,
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(Spacing.lg),
              decoration: BoxDecoration(
                color: DesignTokens.error.withValues(alpha: 0.1),
                borderRadius: DesignTokens.brXl,
              ),
              child: Icon(icon, size: 48, color: DesignTokens.error),
            ),
            const SizedBox(height: Spacing.md),
            Text(
              'Algo deu errado',
              style: AppTypography.headingSm.copyWith(
                color: isDark
                    ? DesignTokens.darkTextPrimary
                    : DesignTokens.lightTextPrimary,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(
                color: isDark
                    ? DesignTokens.darkTextSecondary
                    : DesignTokens.lightTextSecondary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: Spacing.lg),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(retryLabel),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DesignTokens.primary,
                  side: const BorderSide(color: DesignTokens.primary),
                  shape: const RoundedRectangleBorder(
                    borderRadius: DesignTokens.brMd,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
