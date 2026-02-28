import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/landing_components.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LandingTheme.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            LandingNavbar(
              onCreateAccount: () => context.go('/login'),
              onLogin: () => context.go('/login'),
            ),
            const HeroSection(),
            const ProblemSection(),
            const SolutionSection(),
            const EngineeringEnginesSection(),
            const ProcessFlowSection(),
            const DifferentiatorsSection(),
            const TechnicalAuthoritySection(),
            const FinalCTASection(),
            const LandingFooter(),
          ],
        ),
      ),
    );
  }
}

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      verticalPadding: 120,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: LandingTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                  color: LandingTheme.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              'ESTUDYOPS — ENGENHARIA DE APRENDIZAGEM',
              style: GoogleFonts.inter(
                color: LandingTheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.white, Color(0xFFA78BFA)],
            ).createShader(bounds),
            child: Text(
              'Engenharia de aprendizado\naplicada à aprovação.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 64,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.1,
                letterSpacing: -2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Uma plataforma que combina inteligência artificial, ciência cognitiva e engenharia de software para maximizar foco, retenção e aprovação.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 20,
              color: LandingTheme.textSecondary,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => context.go('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LandingTheme.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 20,
                  shadowColor: LandingTheme.primary.withValues(alpha: 0.5),
                ),
                child: Text(
                  'Criar conta gratuita',
                  style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 20),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  side: BorderSide(color: LandingTheme.border, width: 2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Ver como funciona',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProblemSection extends StatelessWidget {
  const ProblemSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      backgroundColor: const Color(0xFF0F172A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'POR QUE A MAIORIA FALHA?',
            style: GoogleFonts.inter(
              color: Colors.redAccent,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'O estudo tradicional é ineficiente.',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              _ProblemCard(
                title: 'Cronogramas Irreais',
                description:
                    'Planilhas estáticas que não se adaptam à sua rotina e geram frustração.',
                icon: Icons.event_busy,
              ),
              _ProblemCard(
                title: 'Esquecimento Rápido',
                description:
                    'Estudar hoje e esquecer amanhã por falta de um sistema de revisão científica.',
                icon: Icons.psychology_outlined,
              ),
              _ProblemCard(
                title: 'Falsa Produtividade',
                description:
                    'Passar horas na frente dos livros sem de fato reter o conteúdo essencial.',
                icon: Icons.timer_off_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProblemCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _ProblemCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.redAccent, size: 32),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.inter(
              color: LandingTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class SolutionSection extends StatelessWidget {
  const SolutionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      child: Column(
        children: [
          Text(
            'A SOLUÇÃO STUDYOPS',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: LandingTheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sistema fechado de aprendizagem adaptativa',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 64),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _SolutionPillar(
                title: 'Planejamento Inteligente',
                icon: Icons.auto_awesome_outlined,
              ),
              _SolutionPillar(
                title: 'Execução com Foco Real',
                icon: Icons.track_changes_outlined,
              ),
              _SolutionPillar(
                title: 'Validação Cognitiva',
                icon: Icons.fact_check_outlined,
              ),
              _SolutionPillar(
                title: 'Feedback Estratégico',
                icon: Icons.analytics_outlined,
              ),
              _SolutionPillar(
                title: 'Ajuste Automático',
                icon: Icons.sync_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SolutionPillar extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SolutionPillar({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: LandingTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: LandingTheme.primary, size: 32),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class EngineeringEnginesSection extends StatelessWidget {
  const EngineeringEnginesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      backgroundColor: const Color(0xFF0F172A),
      child: Column(
        children: [
          Text(
            'OS MOTORES DE ENGENHARIA COGNITIVA',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Propulsão técnica para acelerar sua curva.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 48),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900 ? 2 : 1;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                childAspectRatio: constraints.maxWidth > 600 ? 2.2 : 1.5,
                children: [
                  _EngineCard(
                    tag: 'SSE',
                    name: 'Smart Schedule Engine',
                    desc: 'Alocação dinâmica baseada em peso e dificuldade.',
                    color: Colors.blueAccent,
                  ),
                  _EngineCard(
                    tag: 'FVP',
                    name: 'Focus Validation Protocol',
                    desc: 'Garantia de que o tempo estudado é tempo aprendido.',
                    color: Colors.redAccent,
                  ),
                  _EngineCard(
                    tag: 'CFE',
                    name: 'Cognitive Feedback Engine',
                    desc: 'Mentor analítico que transforma erros em precisão.',
                    color: Colors.greenAccent,
                  ),
                  _EngineCard(
                    tag: 'ALL',
                    name: 'Adaptive Learning Loop',
                    desc:
                        'Otimização contínua via algoritmos de repetição FSRS.',
                    color: Colors.purpleAccent,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EngineCard extends StatelessWidget {
  final String tag;
  final String name;
  final String desc;
  final Color color;

  const _EngineCard({
    required this.tag,
    required this.name,
    required this.desc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: color.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tag,
              style: GoogleFonts.jetBrainsMono(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: GoogleFonts.inter(
              color: LandingTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class ProcessFlowSection extends StatelessWidget {
  const ProcessFlowSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      child: Column(
        children: [
          Text(
            'FLUXO DE ALTA PERFORMANCE',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: LandingTheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Como o StudyOps orquestra seu sucesso',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 64),
          _ProcessStep(
            number: '01',
            title: 'Importação e Verticalização',
            desc:
                'A IA importa seu edital e organiza os tópicos por relevância técnica.',
            icon: Icons.upload_file_outlined,
          ),
          _ProcessDivider(),
          _ProcessStep(
            number: '02',
            title: 'Cronograma Inteligente',
            desc:
                'O SSE aloca matérias baseando-se no seu tempo e peso da disciplina.',
            icon: Icons.calendar_month_outlined,
          ),
          _ProcessDivider(),
          _ProcessStep(
            number: '03',
            title: 'Execução FocusLock',
            desc:
                'O FVP garante que cada minuto de estudo seja validado cognitivamente.',
            icon: Icons.lock_clock_outlined,
          ),
          _ProcessDivider(),
          _ProcessStep(
            number: '04',
            title: 'Evolução e Feedback',
            desc:
                'O CFE analisa seus erros e ajusta o loop de aprendizagem em tempo real.',
            icon: Icons.trending_up_outlined,
          ),
        ],
      ),
    );
  }
}

class _ProcessStep extends StatelessWidget {
  final String number;
  final String title;
  final String desc;
  final IconData icon;

  const _ProcessStep({
    required this.number,
    required this.title,
    required this.desc,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: LandingTheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border:
                Border.all(color: LandingTheme.primary.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.jetBrainsMono(
                color: LandingTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                desc,
                style: GoogleFonts.inter(
                  color: LandingTheme.textSecondary,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProcessDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 31, top: 8, bottom: 8),
      height: 48,
      width: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            LandingTheme.primary.withValues(alpha: 0.5),
            LandingTheme.primary.withValues(alpha: 0.1),
          ],
        ),
      ),
    );
  }
}

class DifferentiatorsSection extends StatelessWidget {
  const DifferentiatorsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      backgroundColor: const Color(0xFF0F172A),
      child: Column(
        children: [
          Text(
            'DIFERENCIAIS COMPETITIVOS',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.amberAccent,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Por que o StudyOps é a escolha da elite.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 64),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900
                  ? 3
                  : (constraints.maxWidth > 600 ? 2 : 1);
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                childAspectRatio: constraints.maxWidth > 600 ? 1.4 : 2.0,
                children: [
                  _DiffCard(
                    title: 'Tempo Líquido Real',
                    desc:
                        'Apenas minutos de foco comprovado são contabilizados.',
                    icon: Icons.verified_outlined,
                  ),
                  _DiffCard(
                    title: 'Simulado com Tutor IA',
                    desc:
                        'Explicações pedagógicas imediatas durante a prática.',
                    icon: Icons.auto_awesome_outlined,
                  ),
                  _DiffCard(
                    title: 'Algoritmo FSRS',
                    desc: 'O estado da arte em repetição espaçada moderna.',
                    icon: Icons.psychology_outlined,
                  ),
                  _DiffCard(
                    title: 'Gap Analysis',
                    desc:
                        'Identificação exata de quais tópicos você precisa reforçar.',
                    icon: Icons.analytics_outlined,
                  ),
                  _DiffCard(
                    title: 'Arquitetura Enterprise',
                    desc:
                        'Velocidade e estabilidade para sua rotina de estudos.',
                    icon: Icons.dns_outlined,
                  ),
                  _DiffCard(
                    title: 'Mobile First',
                    desc:
                        'Estude em qualquer lugar com interface sincronizada.',
                    icon: Icons.smartphone_outlined,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DiffCard extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;

  const _DiffCard({
    required this.title,
    required this.desc,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: LandingTheme.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.amberAccent, size: 28),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            style: GoogleFonts.inter(
              color: LandingTheme.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class TechnicalAuthoritySection extends StatelessWidget {
  const TechnicalAuthoritySection({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      child: GlassCard(
        borderColor: LandingTheme.primary.withValues(alpha: 0.2),
        padding: const EdgeInsets.all(64),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_user_outlined,
                    color: LandingTheme.accent, size: 32),
                const SizedBox(width: 16),
                Text(
                  'AUDITADO TECNICAMENTE',
                  style: GoogleFonts.inter(
                    color: LandingTheme.accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Engenharia Real Comprovada',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 48),
            Wrap(
              spacing: 48,
              runSpacing: 32,
              alignment: WrapAlignment.center,
              children: [
                _AuditItem(
                  label: 'Algoritmos Próprios',
                  desc: 'Motores SSE e FVP desenvolvidos in-house.',
                ),
                _AuditItem(
                  label: 'Validação de Foco',
                  desc: 'Protocolos rigorosos de detecção de atenção.',
                ),
                _AuditItem(
                  label: 'Arquitetura Enterprise',
                  desc: 'Escalabilidade e segurança de nível bancário.',
                ),
                _AuditItem(
                  label: 'IA Integrada',
                  desc: 'LLMs orquestrados para pedagogia ativa.',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditItem extends StatelessWidget {
  final String label;
  final String desc;

  const _AuditItem({required this.label, required this.desc});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: LandingTheme.textMuted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class FinalCTASection extends StatelessWidget {
  const FinalCTASection({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      child: GlassCard(
        borderColor: LandingTheme.primary.withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
        child: Column(
          children: [
            Text(
              'Comece hoje a estudar com inteligência.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: LandingTheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Criar conta gratuita agora',
                style: GoogleFonts.inter(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LandingFooter extends StatelessWidget {
  const LandingFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: LandingTheme.border)),
      ),
      child: Center(
        child: Text(
          '© 2024 StudyOps — Engineering the future of education.',
          style: GoogleFonts.inter(color: LandingTheme.textMuted),
        ),
      ),
    );
  }
}
