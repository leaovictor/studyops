import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';

class ManualScreen extends StatelessWidget {
  const ManualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Guia do Estudante 📖'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _WelcomeSection(),
                const SizedBox(height: 32),
                Text(
                  'Explore as Funcionalidades',
                  style: TextStyle(
                    color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
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
                      'O coração do app. Aqui aparecem as matérias que você precisa estudar hoje, calculadas pelo nosso algoritmo inteligente.',
                  icon: Icons.checklist_rounded,
                  color: Colors.green,
                  tips: [
                    'Cumpra as tarefas do topo primeiro!',
                    'Use o timer Pomodoro para manter o foco total.'
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
                const SizedBox(height: 40),
                const _GamificationFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.15),
            AppTheme.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            'Bem-vindo ao seu Guia de Sobrevivência!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'O StudyOps foi criado para que você não precise pensar no "o que estudar", apenas no "estudar". Aqui está como tirar o máximo proveito de cada ferramenta.',
            style: TextStyle(
              color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
              fontSize: 15,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(
                          color: (Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 40),
          const SizedBox(height: 16),
          Text(
            'Vire um Mestre nos Estudos!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Quanto mais você estuda e revisa, mais pontos você ganha. Não quebre sua ofensiva (streak) — a consistência é a chave da aprovação!',
            style: TextStyle(
              color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}