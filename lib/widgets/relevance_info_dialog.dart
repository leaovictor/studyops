import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class RelevanceInfoDialog extends StatelessWidget {
  const RelevanceInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: (Theme.of(context).cardTheme.color ??
          Theme.of(context).colorScheme.surface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.psychology_alt_rounded, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Lógica de Relevância',
              style: TextStyle(
                  color: (Theme.of(context).textTheme.bodyLarge?.color ??
                      Colors.white),
                  fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'O StudyOps utiliza uma fórmula matemática para priorizar o que você deve estudar hoje:',
            style: TextStyle(
                color: (Theme.of(context).textTheme.bodySmall?.color ??
                    Colors.grey),
                fontSize: 14),
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
            context,
            Icons.star_rounded,
            'Prioridade (1-5)',
            'Sua importância pessoal para a matéria agora.',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            Icons.fitness_center_rounded,
            'Peso (1-10)',
            'Importância da matéria no edital ou prova.',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            Icons.speed_rounded,
            'Dificuldade (1-5)',
            'Média de dificuldade dos tópicos da matéria.',
          ),
          const SizedBox(height: 20),
          Text(
            'O tempo total do seu plano é distribuído proporcionalmente ao score resultante de cada matéria.',
            style: TextStyle(
              color: (Theme.of(context).textTheme.labelSmall?.color ??
                  Colors.grey),
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

  Widget _buildInfoRow(
      BuildContext context, IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon,
            color:
                (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
            size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: (Theme.of(context).textTheme.bodyLarge?.color ??
                      Colors.white),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                desc,
                style: TextStyle(
                    color: (Theme.of(context).textTheme.labelSmall?.color ??
                        Colors.grey),
                    fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
