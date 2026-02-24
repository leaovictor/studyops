import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class RelevanceInfoDialog extends StatelessWidget {
  const RelevanceInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.bg2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.psychology_alt_rounded, color: AppTheme.primary),
          SizedBox(width: 12),
          Text(
            'Lógica de Relevância',
            style: TextStyle(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w800),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'O StudyOps utiliza uma fórmula matemática para priorizar o que você deve estudar hoje:',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            child: const Center(
              child: Text(
                'Prioridade × Peso × Dificuldade',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            Icons.star_rounded,
            'Prioridade (1-5)',
            'Sua importância pessoal para a matéria agora.',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.fitness_center_rounded,
            'Peso (1-10)',
            'Importância da matéria no edital ou prova.',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.speed_rounded,
            'Dificuldade (1-5)',
            'Média de dificuldade dos tópicos da matéria.',
          ),
          const SizedBox(height: 20),
          const Text(
            'O tempo total do seu plano é distribuído proporcionalmente ao score resultante de cada matéria.',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendi',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.textSecondary, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                desc,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
