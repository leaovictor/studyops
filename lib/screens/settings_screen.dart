import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../controllers/auth_controller.dart';
import '../controllers/goal_controller.dart';
import '../core/theme/theme_provider.dart';
import '../core/design_system/design_tokens.dart';
import '../core/design_system/typography_scale.dart';
import '../core/design_system/spacing_system.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

// ─── User Model Provider ───────────────────────────────────────────────────────

final settingsUserProvider =
    FutureProvider.autoDispose<UserModel?>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;
  final doc = await FirebaseFirestore.instance
      .collection(AppConstants.colUsers)
      .doc(user.uid)
      .get();
  if (!doc.exists || doc.data() == null) return null;
  return UserModel.fromMap(doc.data()!);
});

// ─── Screen ──────────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _contextCtrl = TextEditingController();
  bool _isSavingContext = false;
  bool _contextSaved = false;

  @override
  void dispose() {
    _contextCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeProvider);
    final user = ref.watch(authStateProvider).valueOrNull;
    final activeGoal = ref.watch(activeGoalProvider);
    final userAsync = ref.watch(settingsUserProvider);

    // Pre-fill personal context from loaded user model
    userAsync.whenData((userModel) {
      if (_contextCtrl.text.isEmpty &&
          userModel?.personalContext != null &&
          userModel!.personalContext!.isNotEmpty) {
        _contextCtrl.text = userModel.personalContext!;
      }
    });

    final Color bg1 = isDark ? DesignTokens.darkBg1 : DesignTokens.lightBg1;
    final Color bg2 = isDark ? DesignTokens.darkBg2 : DesignTokens.lightBg2;
    const Color primary = DesignTokens.primary;
    final Color textPrimary =
        isDark ? DesignTokens.darkTextPrimary : DesignTokens.lightTextPrimary;
    final Color textSecondary = isDark
        ? DesignTokens.darkTextSecondary
        : DesignTokens.lightTextSecondary;
    final Color cardBorder =
        isDark ? DesignTokens.darkBg3 : const Color(0xFFDDE3EC);

    return Material(
      color: bg1,
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text(
              'Configurações',
              style: AppTypography.headingSm.copyWith(color: textPrimary),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header Subtitle ────────────────────────────────────
                      Text(
                        'Personalize sua experiência',
                        style:
                            AppTypography.bodySm.copyWith(color: textSecondary),
                      ),
                      const SizedBox(height: Spacing.xl),

                      // ── Conta ──────────────────────────────────────────────────
                      _SectionHeader(title: 'CONTA', isDark: isDark),
                      _SettingsCard(
                        isDark: isDark,
                        bg: bg2,
                        border: cardBorder,
                        child: Column(
                          children: [
                            // Avatar + info
                            Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        DesignTokens.primary,
                                        DesignTokens.secondary,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Center(
                                    child: Text(
                                      (user?.displayName?.isNotEmpty == true
                                              ? user!.displayName![0]
                                              : user?.email?.isNotEmpty == true
                                                  ? user!.email![0]
                                                  : 'U')
                                          .toUpperCase(),
                                      style: AppTypography.headingSm.copyWith(
                                        color: Colors.white,
                                        fontSize: 22,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: Spacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user?.displayName ?? 'Usuário',
                                        style: AppTypography.bodyMd.copyWith(
                                          color: textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        user?.email ?? '',
                                        style: AppTypography.bodySm.copyWith(
                                          color: textSecondary,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: Spacing.sm, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: DesignTokens.accent
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Text(
                                    'PRO',
                                    style: AppTypography.overline.copyWith(
                                      color: DesignTokens.accent,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: Spacing.md),
                            const Divider(height: 1),
                            const SizedBox(height: Spacing.sm),
                            // Profile quick-nav
                            _ListTile(
                              icon: Icons.person_outline_rounded,
                              iconColor: primary,
                              label: 'Meu Perfil',
                              subtitle: 'Foto, nome, objetivos',
                              isDark: isDark,
                              onTap: () => context.go('/profile'),
                              trailing: Icon(Icons.chevron_right_rounded,
                                  color: textSecondary, size: 18),
                            ),
                            _ListTile(
                              icon: Icons.logout_rounded,
                              iconColor: DesignTokens.error,
                              label: 'Sair da conta',
                              subtitle: null,
                              isDark: isDark,
                              onTap: () => ref
                                  .read(authControllerProvider.notifier)
                                  .signOut(),
                              trailing: null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Spacing.xl),

                      // ── Aparência ──────────────────────────────────────────────
                      _SectionHeader(title: 'APARÊNCIA', isDark: isDark),
                      _SettingsCard(
                        isDark: isDark,
                        bg: bg2,
                        border: cardBorder,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.1),
                                    borderRadius: DesignTokens.brMd,
                                  ),
                                  child: const Icon(Icons.palette_rounded,
                                      color: DesignTokens.primary, size: 18),
                                ),
                                const SizedBox(width: Spacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Tema',
                                          style: AppTypography.bodySm.copyWith(
                                              color: textPrimary,
                                              fontWeight: FontWeight.w600)),
                                      Text(
                                        themeMode == ThemeMode.dark
                                            ? 'Modo escuro'
                                            : themeMode == ThemeMode.light
                                                ? 'Modo claro'
                                                : 'Sistema',
                                        style: AppTypography.overline.copyWith(
                                            color: textSecondary, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: Spacing.md),
                            // Theme options row
                            Row(
                              children: [
                                _ThemeChip(
                                  icon: Icons.wb_sunny_rounded,
                                  label: 'Claro',
                                  selected: themeMode == ThemeMode.light,
                                  color: const Color(0xFFFFB300),
                                  onTap: () => ref
                                      .read(themeProvider.notifier)
                                      .setThemeMode(ThemeMode.light),
                                ),
                                const SizedBox(width: Spacing.sm),
                                _ThemeChip(
                                  icon: Icons.nightlight_round,
                                  label: 'Escuro',
                                  selected: themeMode == ThemeMode.dark,
                                  color: DesignTokens.primary,
                                  onTap: () => ref
                                      .read(themeProvider.notifier)
                                      .setThemeMode(ThemeMode.dark),
                                ),
                                const SizedBox(width: Spacing.sm),
                                _ThemeChip(
                                  icon: Icons.brightness_auto_rounded,
                                  label: 'Sistema',
                                  selected: themeMode == ThemeMode.system,
                                  color: textSecondary,
                                  onTap: () => ref
                                      .read(themeProvider.notifier)
                                      .setThemeMode(ThemeMode.system),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Spacing.xl),

                      // ── IA Personalizada ───────────────────────────────────────
                      _SectionHeader(title: 'IA PERSONALIZADA', isDark: isDark),
                      _SettingsCard(
                        isDark: isDark,
                        bg: bg2,
                        border: cardBorder,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: DesignTokens.secondary
                                        .withValues(alpha: 0.1),
                                    borderRadius: DesignTokens.brMd,
                                  ),
                                  child: const Icon(Icons.psychology_rounded,
                                      color: DesignTokens.secondary, size: 18),
                                ),
                                const SizedBox(width: Spacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Contexto pessoal para o Mentor IA',
                                        style: AppTypography.bodySm.copyWith(
                                            color: textPrimary,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        'O Mentor usa isso para personalizar suas respostas',
                                        style: AppTypography.overline.copyWith(
                                            color: textSecondary, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: Spacing.md),
                            TextField(
                              controller: _contextCtrl,
                              maxLines: 4,
                              onChanged: (_) =>
                                  setState(() => _contextSaved = false),
                              style: AppTypography.bodySm
                                  .copyWith(color: textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                hintText:
                                    'Ex: Sou funcionário público, estudo para o concurso do TRF. Tenho dificuldade em Direito Administrativo e estudo 3h por dia...',
                                hintStyle: AppTypography.bodySm.copyWith(
                                  color: textSecondary,
                                  fontSize: 12,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? DesignTokens.darkBg3
                                    : DesignTokens.lightBg1,
                                border: OutlineInputBorder(
                                  borderRadius: DesignTokens.brMd,
                                  borderSide: BorderSide(
                                      color: DesignTokens.secondary
                                          .withValues(alpha: 0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: DesignTokens.brMd,
                                  borderSide: BorderSide(
                                      color: DesignTokens.secondary
                                          .withValues(alpha: 0.2)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: DesignTokens.brMd,
                                  borderSide: const BorderSide(
                                      color: DesignTokens.secondary),
                                ),
                                contentPadding:
                                    const EdgeInsets.all(Spacing.md),
                              ),
                            ),
                            const SizedBox(height: Spacing.sm),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (_contextSaved)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        right: Spacing.sm),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle_rounded,
                                            color: DesignTokens.accent,
                                            size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Salvo!',
                                          style: AppTypography.overline
                                              .copyWith(
                                                  color: DesignTokens.accent,
                                                  fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                FilledButton.icon(
                                  onPressed: _isSavingContext
                                      ? null
                                      : () => _savePersonalContext(user?.uid),
                                  icon: _isSavingContext
                                      ? const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white))
                                      : const Icon(Icons.save_rounded,
                                          size: 14),
                                  label: const Text('Salvar contexto'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: DesignTokens.secondary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: Spacing.md),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Spacing.xl),

                      // ── Plano Ativo ────────────────────────────────────────────
                      _SectionHeader(title: 'PLANO ATIVO', isDark: isDark),
                      _SettingsCard(
                        isDark: isDark,
                        bg: bg2,
                        border: cardBorder,
                        child: Builder(builder: (context) {
                          final goal = activeGoal;
                          if (goal == null) {
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: DesignTokens.warning
                                            .withValues(alpha: 0.1),
                                        borderRadius: DesignTokens.brMd,
                                      ),
                                      child: const Icon(Icons.flag_rounded,
                                          color: DesignTokens.warning,
                                          size: 18),
                                    ),
                                    const SizedBox(width: Spacing.md),
                                    Expanded(
                                      child: Text(
                                        'Nenhum objetivo ativo',
                                        style: AppTypography.bodySm
                                            .copyWith(color: textSecondary),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: Spacing.md),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => context.go('/onboarding'),
                                    icon:
                                        const Icon(Icons.add_rounded, size: 16),
                                    label: const Text('Criar objetivo'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: primary,
                                      side: const BorderSide(
                                          color: DesignTokens.primary),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: primary.withValues(alpha: 0.1),
                                      borderRadius: DesignTokens.brMd,
                                    ),
                                    child: const Icon(Icons.flag_rounded,
                                        color: DesignTokens.primary, size: 18),
                                  ),
                                  const SizedBox(width: Spacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          goal.name,
                                          style: AppTypography.bodySm.copyWith(
                                              color: textPrimary,
                                              fontWeight: FontWeight.w700),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Criado em: ${_fmtDate(goal.createdAt)}',
                                          style: AppTypography.overline
                                              .copyWith(
                                                  color: textSecondary,
                                                  fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: Spacing.md),
                              const Divider(height: 1),
                              const SizedBox(height: Spacing.sm),
                              _ListTile(
                                icon: Icons.auto_awesome_rounded,
                                iconColor: primary,
                                label: 'Gerenciar Plano de Estudos (IA)',
                                subtitle: null,
                                isDark: isDark,
                                onTap: () => context.go('/checklist'),
                                trailing: Icon(Icons.chevron_right_rounded,
                                    color: textSecondary, size: 18),
                              ),
                            ],
                          );
                        }),
                      ),
                      const SizedBox(height: Spacing.xl),

                      // ── Sobre ──────────────────────────────────────────────────
                      _SectionHeader(title: 'SOBRE O APP', isDark: isDark),
                      _SettingsCard(
                        isDark: isDark,
                        bg: bg2,
                        border: cardBorder,
                        child: Column(
                          children: [
                            _ListTile(
                              icon: Icons.book_outlined,
                              iconColor: const Color(0xFF43A047),
                              label: 'Guia do Usuário',
                              subtitle: 'Como funciona cada recurso',
                              isDark: isDark,
                              onTap: () => context.go('/manual'),
                              trailing: Icon(Icons.chevron_right_rounded,
                                  color: textSecondary, size: 18),
                            ),
                            const Divider(height: 1),
                            _ListTile(
                              icon: Icons.info_outline_rounded,
                              iconColor: primary,
                              label: 'Versão',
                              subtitle: '1.12.0 • Sprint 12',
                              isDark: isDark,
                              onTap: null,
                              trailing: null,
                            ),
                            const Divider(height: 1),
                            _ListTile(
                              icon: Icons.code_rounded,
                              iconColor: const Color(0xFFA78BFA),
                              label: 'Feito com Engenharia de Aprendizagem',
                              subtitle: 'StudyOps © 2026',
                              isDark: isDark,
                              onTap: null,
                              trailing: null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Spacing.xxl),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _savePersonalContext(String? uid) async {
    if (uid == null) return;
    setState(() => _isSavingContext = true);
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.colUsers)
          .doc(uid)
          .update({'personalContext': _contextCtrl.text.trim()});
      if (mounted) {
        setState(() {
          _isSavingContext = false;
          _contextSaved = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingContext = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
      }
    }
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.isDark});
  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Text(
        title,
        style: AppTypography.overline.copyWith(
          color:
              isDark ? DesignTokens.darkTextMuted : DesignTokens.lightTextMuted,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.child,
    required this.isDark,
    required this.bg,
    required this.border,
  });
  final Widget child;
  final bool isDark;
  final Color bg;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: DesignTokens.brLg,
        border: Border.all(color: border.withValues(alpha: 0.6)),
        boxShadow: DesignTokens.elevationLow,
      ),
      child: child,
    );
  }
}

class _ListTile extends StatelessWidget {
  const _ListTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
    required this.trailing,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final bool isDark;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? DesignTokens.darkTextPrimary : DesignTokens.lightTextPrimary;
    final textSecondary = isDark
        ? DesignTokens.darkTextSecondary
        : DesignTokens.lightTextSecondary;

    return InkWell(
      borderRadius: DesignTokens.brMd,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: DesignTokens.brSm,
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.bodySm.copyWith(
                      color: iconColor == DesignTokens.error
                          ? DesignTokens.error
                          : textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: AppTypography.overline.copyWith(
                        color: textSecondary,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
          decoration: BoxDecoration(
            color:
                selected ? color.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: DesignTokens.brMd,
            border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.2),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? color : color.withValues(alpha: 0.5),
                  size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.overline.copyWith(
                  color: selected ? color : color.withValues(alpha: 0.6),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
