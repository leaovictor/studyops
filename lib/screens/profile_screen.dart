import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../core/design_system/design_tokens.dart';
import '../core/design_system/typography_scale.dart';
import '../core/design_system/spacing_system.dart';
import '../core/theme/app_theme.dart';
import '../controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/performance_controller.dart';
import '../core/gamification/gamification_engine.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../core/constants/app_constants.dart';
import '../shared/widgets/animated_progress.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

final userProfileProvider = FutureProvider.autoDispose<UserModel?>((ref) async {
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

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _headerCtrl;
  late final Animation<double> _headerScale;
  late final Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _headerScale = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(
      parent: _headerCtrl,
      curve: Curves.easeOutBack,
    ));
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _headerCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    _headerCtrl.forward();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileAsync = ref.watch(userProfileProvider);
    final dashAsync = ref.watch(dashboardProvider);
    final perf = ref.watch(performanceStatsProvider);
    final gamification = ref.watch(gamificationProvider);

    return Scaffold(
      backgroundColor: isDark ? DesignTokens.darkBg1 : DesignTokens.lightBg1,
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (profile) => CustomScrollView(
          slivers: [
            // ── Header SliverAppBar ───────────────────────────────────────
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor:
                  isDark ? DesignTokens.darkBg2 : DesignTokens.lightBg2,
              flexibleSpace: FlexibleSpaceBar(
                background: _ProfileHeader(
                  profile: profile,
                  gamification: gamification,
                  ctrlScale: _headerScale,
                  ctrlFade: _headerFade,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  tooltip: 'Editar Perfil',
                  onPressed: () => _openEditDialog(profile),
                ),
              ],
            ),

            // ── Body ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: AnimationLimiter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 350),
                      childAnimationBuilder: (w) => SlideAnimation(
                        verticalOffset: 30,
                        child: FadeInAnimation(child: w),
                      ),
                      children: [
                        // Stats row
                        dashAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (data) => _StatsRow(
                            streakDays: data.streakDays,
                            weekMinutes: data.weekMinutes,
                            totalQuestions: perf.totalQuestions,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(height: Spacing.xl),

                        // XP progress
                        _XpSection(gamification: gamification, isDark: isDark),
                        const SizedBox(height: Spacing.xl),

                        // Performance summary
                        _PerformanceSection(perf: perf, isDark: isDark),
                        const SizedBox(height: Spacing.xl),

                        // Account info
                        _AccountSection(
                          profile: profile,
                          isDark: isDark,
                        ),
                        const SizedBox(height: Spacing.xl),

                        // Danger zone
                        _DangerZone(isDark: isDark),
                        const SizedBox(height: Spacing.xxl),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditDialog(UserModel? profile) async {
    final nameCtrl = TextEditingController(text: profile?.displayName ?? '');
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar Perfil'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nome de exibição',
              prefixIcon: Icon(Icons.person_rounded),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Nome obrigatório' : null,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(context, nameCtrl.text.trim());
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (result != null) {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) return;
      await FirebaseFirestore.instance
          .collection(AppConstants.colUsers)
          .doc(user.uid)
          .update({'displayName': result});
      ref.invalidate(userProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado!')),
        );
      }
    }
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.gamification,
    required this.ctrlScale,
    required this.ctrlFade,
  });
  final UserModel? profile;
  final GamificationState gamification;
  final Animation<double> ctrlScale;
  final Animation<double> ctrlFade;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = profile?.displayName ?? profile?.email ?? 'Estudante';
    final photo = profile?.photoUrl;
    final level = XpSystem.levelForXp(gamification.totalXp);
    final rank = XpSystem.rankLabel(level);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.primary.withValues(alpha: 0.8),
            DesignTokens.secondary.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: AnimatedBuilder(
          animation: ctrlFade,
          builder: (_, child) => Opacity(
            opacity: ctrlFade.value,
            child: ScaleTransition(scale: ctrlScale, child: child),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: DesignTokens.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 46,
                  backgroundImage: photo != null ? NetworkImage(photo) : null,
                  backgroundColor: DesignTokens.primary,
                  child: photo == null
                      ? Text(
                          (name.isNotEmpty ? name[0] : 'S').toUpperCase(),
                          style: AppTypography.headingLg.copyWith(
                            color: Colors.white,
                            fontSize: 36,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: AppTypography.headingMd.copyWith(
                  color: Colors.white,
                  shadows: [
                    Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4)
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Rank badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: DesignTokens.brXl,
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '⭐ $rank · Nível $level',
                  style: AppTypography.labelSm.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Ignore isDark — always on gradient bg
              if (!isDark) const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stats Row ───────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.streakDays,
    required this.weekMinutes,
    required this.totalQuestions,
    required this.isDark,
  });
  final int streakDays;
  final int weekMinutes;
  final int totalQuestions;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatTile(
          icon: '🔥',
          label: 'Streak',
          value: '${streakDays}d',
          color: const Color(0xFFFF6B35),
          isDark: isDark,
        ),
        const SizedBox(width: Spacing.sm),
        _StatTile(
          icon: '⏱',
          label: 'Horas/sem',
          value: '${(weekMinutes / 60).toStringAsFixed(1)}h',
          color: DesignTokens.primary,
          isDark: isDark,
        ),
        const SizedBox(width: Spacing.sm),
        _StatTile(
          icon: '📝',
          label: 'Questões',
          value: '$totalQuestions',
          color: DesignTokens.accent,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });
  final String icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: Spacing.md, horizontal: Spacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: DesignTokens.brMd,
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.headingSm.copyWith(
                color: isDark
                    ? DesignTokens.darkTextPrimary
                    : DesignTokens.lightTextPrimary,
              ),
            ),
            Text(
              label,
              style: AppTypography.overline.copyWith(
                color: isDark
                    ? DesignTokens.darkTextMuted
                    : DesignTokens.lightTextMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── XP Section ──────────────────────────────────────────────────────────────

class _XpSection extends StatelessWidget {
  const _XpSection({required this.gamification, required this.isDark});
  final GamificationState gamification;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final level = XpSystem.levelForXp(gamification.totalXp);
    final currentXp = gamification.totalXp;
    final xpForCurrent = XpSystem.cumulativeXpForLevel(level);
    final xpForNext = XpSystem.cumulativeXpForLevel(level + 1);
    final progress = xpForNext > xpForCurrent
        ? ((currentXp - xpForCurrent) / (xpForNext - xpForCurrent))
            .clamp(0.0, 1.0)
        : 1.0;

    return _SectionCard(
      title: '🎮 Progresso & XP',
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$currentXp XP total',
                style: AppTypography.headingSm.copyWith(
                  color: DesignTokens.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Nível $level → ${level + 1}',
                style: AppTypography.bodySm.copyWith(
                  color: isDark
                      ? DesignTokens.darkTextSecondary
                      : DesignTokens.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          AnimatedProgress(
            value: progress,
            height: 8,
            gradient: const LinearGradient(
              colors: [DesignTokens.primary, DesignTokens.secondary],
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            '${currentXp - xpForCurrent} / ${xpForNext - xpForCurrent} XP para o próximo nível',
            style: AppTypography.overline.copyWith(
              color: isDark
                  ? DesignTokens.darkTextMuted
                  : DesignTokens.lightTextMuted,
            ),
          ),
          const SizedBox(height: Spacing.md),
          // Unlocked achievements count
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded,
                  color: DesignTokens.warning, size: 18),
              const SizedBox(width: Spacing.xs),
              Text(
                '${gamification.unlockedAchievements.length} conquistas desbloqueadas',
                style: AppTypography.bodySm.copyWith(
                  color: isDark
                      ? DesignTokens.darkTextSecondary
                      : DesignTokens.lightTextSecondary,
                ),
              ),
              const Spacer(),
              TextButton(
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                onPressed: () => context.go('/achievements'),
                child: const Text('Ver todas →'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Performance Section ──────────────────────────────────────────────────────

class _PerformanceSection extends StatelessWidget {
  const _PerformanceSection({required this.perf, required this.isDark});
  final PerformanceStats perf;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '📊 Desempenho Acumulado',
      isDark: isDark,
      child: Column(
        children: [
          _PerfRow(
            label: 'Total de questões respondidas',
            value: '${perf.totalQuestions}',
            icon: Icons.quiz_rounded,
            isDark: isDark,
          ),
          const Divider(height: Spacing.lg),
          _PerfRow(
            label: 'Taxa de acerto média',
            value: '${perf.averageAccuracy.toStringAsFixed(1)}%',
            icon: Icons.percent_rounded,
            isDark: isDark,
          ),
          const Divider(height: Spacing.lg),
          _PerfRow(
            label: 'Matérias estudadas',
            value: '${perf.accuracyBySubject.length}',
            icon: Icons.book_rounded,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _PerfRow extends StatelessWidget {
  const _PerfRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
  });
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 18,
            color: isDark
                ? DesignTokens.darkTextSecondary
                : DesignTokens.lightTextSecondary),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySm.copyWith(
              color: isDark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.lightTextSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.headingSm.copyWith(
            color: isDark
                ? DesignTokens.darkTextPrimary
                : DesignTokens.lightTextPrimary,
          ),
        ),
      ],
    );
  }
}

// ─── Account Section ─────────────────────────────────────────────────────────

class _AccountSection extends StatelessWidget {
  const _AccountSection({required this.profile, required this.isDark});
  final UserModel? profile;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final sinceStr =
        profile?.createdAt != null ? _formatDate(profile!.createdAt!) : '—';

    return _SectionCard(
      title: '🔐 Conta',
      isDark: isDark,
      child: Column(
        children: [
          _InfoRow(
              label: 'E-mail',
              value: profile?.email ?? '—',
              icon: Icons.email_rounded,
              isDark: isDark),
          const Divider(height: Spacing.lg),
          _InfoRow(
              label: 'Membro desde',
              value: sinceStr,
              icon: Icons.calendar_today_rounded,
              isDark: isDark),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez'
    ];
    return '${dt.day} de ${months[dt.month - 1]} de ${dt.year}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
  });
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 18,
            color: isDark
                ? DesignTokens.darkTextSecondary
                : DesignTokens.lightTextSecondary),
        const SizedBox(width: Spacing.sm),
        Text(
          label,
          style: AppTypography.bodySm.copyWith(
            color: isDark
                ? DesignTokens.darkTextSecondary
                : DesignTokens.lightTextSecondary,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.bodySm.copyWith(
              color: isDark
                  ? DesignTokens.darkTextPrimary
                  : DesignTokens.lightTextPrimary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Danger Zone ─────────────────────────────────────────────────────────────

class _DangerZone extends ConsumerWidget {
  const _DangerZone({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SectionCard(
      title: '⚙️ Sessão',
      isDark: isDark,
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sair da conta'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.error,
            side: const BorderSide(color: AppTheme.error),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Sair da conta?'),
                content: const Text(
                    'Tem certeza que deseja encerrar a sessão atual?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar')),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style:
                        FilledButton.styleFrom(backgroundColor: AppTheme.error),
                    child: const Text('Sair'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await AuthService().signOut();
            }
          },
        ),
      ),
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.title, required this.child, required this.isDark});
  final String title;
  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkBg2 : DesignTokens.lightBg2,
        borderRadius: DesignTokens.brLg,
        boxShadow: DesignTokens.elevationLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTypography.labelMd.copyWith(
                color: isDark
                    ? DesignTokens.darkTextPrimary
                    : DesignTokens.lightTextPrimary,
              )),
          const SizedBox(height: Spacing.md),
          child,
        ],
      ),
    );
  }
}
