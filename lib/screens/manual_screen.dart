import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';

class ManualScreen extends StatelessWidget {
  const ManualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg0,
      appBar: AppBar(
        title: const Text('Guia do Estudante 📖'),
        backgroundColor: AppTheme.bg1,
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WelcomeSection(),
                SizedBox(height: 32),
                Text(
                  'Explore as Funcionalidades',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 16),
                _ManualCard(
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
                _ManualCard(
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
                _ManualCard(
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
                _ManualCard(
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
                _ManualCard(
                  title: 'Objetivos e Planos',
                  description:
                      'Você pode gerenciar múltiplos concursos ao mesmo tempo. Cada um tem seu próprio cronograma e matérias.',
                  icon: Icons.flag_rounded,
                  color: AppTheme.primary,
                  tips: [
                    'Troque de objetivo rapidamente no menu lateral.',
                    'Ajuste seu ritmo nas Configurações sempre que precisar.'
                  ],
                ),
                SizedBox(height: 40),
                _GamificationFooter(),
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
            AppTheme.primary.withOpacity(0.15),
            AppTheme.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: const Column(
        children: [
          Text(
            'Bem-vindo ao seu Guia de Sobrevivência!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            'O StudyOps foi criado para que você não precise pensar no "o que estudar", apenas no "estudar". Aqui está como tirar o máximo proveito de cada ferramenta.',
            style: TextStyle(
              color: AppTheme.textSecondary,
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
        color: AppTheme.bg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
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
            style: const TextStyle(
              color: AppTheme.textSecondary,
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
                        style: const TextStyle(
                          color: AppTheme.textMuted,
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
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: const Column(
        children: [
          Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 40),
          SizedBox(height: 16),
          Text(
            'Vire um Mestre nos Estudos!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Quanto mais você estuda e revisa, mais pontos você ganha. Não quebre sua ofensiva (streak) — a consistência é a chave da aprovação!',
            style: TextStyle(
              color: AppTheme.textSecondary,
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
