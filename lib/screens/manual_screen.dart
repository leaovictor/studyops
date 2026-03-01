import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../core/design_system/design_tokens.dart';
import '../core/design_system/typography_scale.dart';
import '../core/design_system/spacing_system.dart';

class ManualScreen extends StatelessWidget {
  const ManualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? DesignTokens.darkBg1 : DesignTokens.lightBg1,
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text(
              'Guia do Estudante 📖',
              style: AppTypography.headingSm.copyWith(
                color: isDark
                    ? DesignTokens.darkTextPrimary
                    : DesignTokens.lightTextPrimary,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
              color: isDark
                  ? DesignTokens.darkTextPrimary
                  : DesignTokens.lightTextPrimary,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _WelcomeSection(),
                      const SizedBox(height: Spacing.xl),
                      Text(
                        'Explore as Funcionalidades',
                        style: AppTypography.headingSm.copyWith(
                          color: isDark
                              ? DesignTokens.darkTextPrimary
                              : DesignTokens.lightTextPrimary,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: Spacing.md),
                      const _ManualCard(
                        title: 'Dashboard: Seu Centro de Comando',
                        description:
                            'Aqui você vê o panorama geral da sua evolução. Acompanhe sua consistência (o fogo que não pode apagar!) e sua ofensiva de dias seguidos.',
                        icon: Icons.dashboard_rounded,
                        color: Colors.blue,
                        tips: [
                          'Acompanhe o gráfico de pizza para ver se está cumprindo o planejado.',
                          'A barra de progresso semanal mostra se você está no ritmo certo.'
                        ],
                      ),
                      const _ManualCard(
                        title: 'Checklist: Sua Missão Diária',
                        description:
                            'O coração do app. Aqui aparecem as tarefas que você precisa estudar hoje e as revisões pendentes do seu Caderno de Erros (marcadas em laranja).',
                        icon: Icons.checklist_rounded,
                        color: Colors.green,
                        tips: [
                          'Cumpra as tarefas do topo primeiro!',
                          'Ao concluir uma tarefa, a IA gerará um teste rápido. Use-o para medir seu foco!'
                        ],
                      ),
                      const _ManualCard(
                        title: 'Cronograma: Seu Planejamento Mágico',
                        description:
                            'Crie um Plano de Estudos personalizado definindo quantos dias até a prova e quantas horas quer estudar por dia. O app distribui as matérias magicamente.',
                        icon: Icons.calendar_month_rounded,
                        color: Colors.indigo,
                        tips: [
                          'O wizard visual calcula tudo para você.',
                          'Ajuste o plano aqui a qualquer momento se sua rotina mudar.'
                        ],
                      ),
                      const _ManualCard(
                        title: 'Caderno de Erros: Sua Arma Secreta',
                        description:
                            'Errou uma questão no simulado? Salve aqui! O sistema vai agendar revisões automáticas para garantir que você não erre o mesmo assunto na prova.',
                        icon: Icons.menu_book_rounded,
                        color: Colors.orange,
                        tips: [
                          'Adicione fotos da questão e do seu erro.',
                          'Revise os itens pendentes todos os dias para máxima memorização.'
                        ],
                      ),
                      const _ManualCard(
                        title: 'Flashcards: Memória de Elefante',
                        description:
                            'Use a Repetição Espaçada (SRS) para decorar conceitos, fórmulas e leis. É a forma mais eficiente de memorização de longo prazo.',
                        icon: Icons.style_rounded,
                        color: Colors.purple,
                        tips: [
                          'Seja honesto na avaliação da dificuldade da carta.',
                          'O algoritmo FSRS cuida de quando você deve ver a carta novamente.'
                        ],
                      ),
                      const _ManualCard(
                        title: 'Edital Inteligente (T, R, E)',
                        description:
                            'O StudyOps permite o controle total do seu edital. Para cada tópico, você pode marcar se já cumpriu a Teoria (T), Revisão (R) e Exercícios (E).',
                        icon: Icons.checklist_rtl_rounded,
                        color: Colors.teal,
                        tips: [
                          'Acompanhe a barra de progresso em cada matéria para saber quanto falta para "fechar" o edital.',
                          'Use a Importação com IA para cadastrar centenas de tópicos em segundos.'
                        ],
                      ),
                      const _ManualCard(
                        title: 'Mentor e Explicações com IA',
                        description:
                            'Use o poder do Gemini 1.5 Flash para acelerar seu aprendizado. A IA pode analisar sua performance, explicar questões difíceis e gerar flashcards automaticamente.',
                        icon: Icons.auto_awesome_rounded,
                        color: AppTheme.accent,
                        tips: [
                          'Na tela de Performance, clique em "Analisar com IA" para receber um feedback estratégico.',
                          'No Caderno de Erros, peça explicações à IA para entender o fundamento jurídico ou teórico de qualquer questão.'
                        ],
                      ),
                      const _ManualCard(
                        title: 'Banco Global e Crowdsourcing',
                        description:
                            'Ajude a comunidade e seja ajudado. Você pode subir PDFs de provas anteriores e nossa IA extrairá as questões para o banco global automaticamente.',
                        icon: Icons.cloud_upload_rounded,
                        color: Colors.lightBlue,
                        tips: [
                          'O sistema remove duplicatas automaticamente usando hashing SHA-256.',
                          'Quanto mais provas a comunidade sobe, maior fica o banco de questões para todos.'
                        ],
                      ),
                      const _ManualCard(
                        title: 'Objetivos e Planos',
                        description:
                            'Você pode gerenciar múltiplos concursos ao mesmo tempo. Cada um tem seu próprio cronograma e matérias.',
                        icon: Icons.flag_rounded,
                        color: AppTheme.primary,
                        tips: [
                          'Troque de objetivo rapidamente no menu lateral.',
                          'Gerencie os Assuntos do seu concurso na aba Matérias.'
                        ],
                      ),
                      const _ManualCard(
                        title: 'Simulado (Banco Global)',
                        description:
                            'Pratique seus conhecimentos com questões reais extraídas pela comunidade. Receba feedback imediato e envie seus erros para revisão.',
                        icon: Icons.quiz_rounded,
                        color: Colors.pinkAccent,
                        tips: [
                          'Errou? A questão vai direto para o seu Caderno de Erros automaticamente.',
                          'Peça a ajuda da inteligência artificial clicando em "Explicação IA" em qualquer questão!'
                        ],
                      ),
                      const _ManualCard(
                        title: 'Validação Rápida de Conhecimento (IA)',
                        description:
                            'Ao marcar uma tarefa do Checklist como concluída, a IA gera um mini-teste de 5 questões sobre o tópico estudado para fixação. Sua nota define a rentabilidade do seu estudo!',
                        icon: Icons.psychology_rounded,
                        color: Colors.deepOrange,
                        tips: [
                          'Acerte mais de 60% para converter seu Tempo Bruto em Tempo Líquido no Dashboard.',
                          'A IA explica as respostas para cada questão instantaneamente caso você erre.'
                        ],
                      ),
                      const _ManualCard(
                        title: 'Modo Foco Hardcore (Pomodoro)',
                        description:
                            'Chega de se enganar. O seu tempo Pomodoro só roda quando você está efetivamente no app.',
                        icon: Icons.timer_rounded,
                        color: Colors.redAccent,
                        tips: [
                          'Se você sair do app enquanto o timer estiver rodando, ele é pausado automaticamente.',
                          'Combine o Modo Hardcore com a Validação da IA para ter 100% de certeza do seu rendimento.'
                        ],
                      ),
                      const SizedBox(height: Spacing.xl),
                      const _GamificationFooter(),
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
}

class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.15),
            AppTheme.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: DesignTokens.brLg,
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            'Bem-vindo ao seu Guia de Sobrevivência!',
            style: AppTypography.headingSm.copyWith(
              color: isDark
                  ? DesignTokens.darkTextPrimary
                  : DesignTokens.lightTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'O StudyOps foi criado para que você não precise pensar no "o que estudar", apenas no "estudar". Aqui está como tirar o máximo proveito de cada ferramenta.',
            style: AppTypography.bodySm.copyWith(
              color: isDark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.lightTextSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ManualCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> tips;

  const _ManualCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.tips,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.md),
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkBg2 : DesignTokens.lightBg2,
        borderRadius: DesignTokens.brLg,
        border: Border.all(
          color: isDark ? DesignTokens.darkBg3 : const Color(0xFFDDE3EC),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Spacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.labelMd.copyWith(
                    color: isDark
                        ? DesignTokens.darkTextPrimary
                        : DesignTokens.lightTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Text(
            description,
            style: AppTypography.bodySm.copyWith(
              color: isDark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.lightTextSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: Spacing.md),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: Spacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Text(
                        tip,
                        style: AppTypography.overline.copyWith(
                          color: isDark
                              ? DesignTokens.darkTextMuted
                              : DesignTokens.lightTextMuted,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _GamificationFooter extends StatelessWidget {
  const _GamificationFooter();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: DesignTokens.brLg,
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 40),
          const SizedBox(height: Spacing.md),
          Text(
            'Vire um Mestre nos Estudos!',
            style: AppTypography.labelMd.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark
                  ? DesignTokens.darkTextPrimary
                  : DesignTokens.lightTextPrimary,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Quanto mais você estuda e revisa, mais pontos você ganha. Não quebre sua ofensiva (streak) — a consistência é a chave da aprovação!',
            style: AppTypography.bodySm.copyWith(
              color: isDark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.lightTextSecondary,
              height: 1.5,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
