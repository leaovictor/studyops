import 'package:flutter/material.dart';
import '../models/question_model.dart';

class QuestionFormModal extends StatefulWidget {
  final Question? initialQuestion;
  final String subjectId;
  final String? goalId;
  final Function(Question) onSave;

  const QuestionFormModal({
    super.key,
    this.initialQuestion,
    required this.subjectId,
    this.goalId,
    required this.onSave,
  });

  @override
  State<QuestionFormModal> createState() => _QuestionFormModalState();
}

class _QuestionFormModalState extends State<QuestionFormModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _textController;
  late TextEditingController _explanationController;
  late List<TextEditingController> _optionControllers;
  int _correctOptionIndex = 0;
  int _difficulty = 3;

  @override
  void initState() {
    super.initState();
    _textController =
        TextEditingController(text: widget.initialQuestion?.text ?? '');
    _explanationController =
        TextEditingController(text: widget.initialQuestion?.explanation ?? '');

    _optionControllers = List.generate(
      4,
      (index) => TextEditingController(
        text: widget.initialQuestion != null &&
                widget.initialQuestion!.options.length > index
            ? widget.initialQuestion!.options[index]
            : '',
      ),
    );

    if (widget.initialQuestion != null) {
      _correctOptionIndex = widget.initialQuestion!.correctOptionIndex;
      _difficulty = widget.initialQuestion!.difficulty;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _explanationController.dispose();
    for (var c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final newQuestion = Question(
        id: widget.initialQuestion?.id ?? '', // Handled by service if empty
        text: _textController.text,
        options: _optionControllers.map((c) => c.text).toList(),
        correctOptionIndex: _correctOptionIndex,
        explanation: _explanationController.text,
        subjectId: widget.subjectId,
        goalId: widget.goalId,
        difficulty: _difficulty,
        tags: widget.initialQuestion?.tags ?? [], // Keep old tags or add logic
        ownerId: widget.initialQuestion?.ownerId ?? '', // Fill at call site
      );
      widget.onSave(newQuestion);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic padding to prevent PWA keyboard overlap
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomPadding,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.initialQuestion == null
                      ? 'Nova Questão'
                      : 'Editar Questão',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _textController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Enunciado da Questão (Markdown)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Alternativas',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(4, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Radio<int>(
                                value: index,
                                groupValue: _correctOptionIndex,
                                onChanged: (val) {
                                  setState(() {
                                    _correctOptionIndex = val!;
                                  });
                                },
                              ),
                              Expanded(
                                child: TextFormField(
                                  controller: _optionControllers[index],
                                  decoration: InputDecoration(
                                    labelText: 'Alternativa ${index + 1}',
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (v) =>
                                      v!.isEmpty ? 'Obrigatório' : null,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _explanationController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Explicação / Comentário',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Dificuldade: '),
                          Expanded(
                            child: Slider(
                              value: _difficulty.toDouble(),
                              min: 1,
                              max: 5,
                              divisions: 4,
                              label: _difficulty.toString(),
                              onChanged: (val) {
                                setState(() {
                                  _difficulty = val.toInt();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _save,
                        child: Text(widget.initialQuestion == null
                            ? 'Salvar Questão'
                            : 'Atualizar Questão'),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
