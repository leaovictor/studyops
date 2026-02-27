import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/subject_model.dart';
import '../models/topic_model.dart';
import 'usage_service.dart';

class AISyllabusImportResult {
  final List<Subject> subjects;
  final List<Topic> topics;

  AISyllabusImportResult({required this.subjects, required this.topics});
}

class AIService {
  final String apiKey;
  final UsageService usageService;
  late final GenerativeModel _model;

  AIService({required this.apiKey, required this.usageService}) {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
  }

  Future<AISyllabusImportResult> parseSyllabus(String rawText, String userId, String? goalId) async {
    await usageService.logAIUsage(userId, 'syllabus_import');
    final prompt = '''
Analise o texto a seguir, que é um conteúdo programático de um edital de concurso público.
Extraia as matérias e seus respectivos tópicos.
Retorne um JSON seguindo EXATAMENTE esta estrutura:
{
  "subjects": [
    {
      "name": "Nome da Matéria",
      "topics": ["Tópico 1", "Tópico 2", "Tópico 3"]
    }
  ]
}

Regras:
1. Agrupe tópicos relacionados sob uma única matéria.
2. Seja conciso nos nomes dos tópicos.
3. Se o texto for confuso, tente o seu melhor para organizar logicamente.

Texto do edital:
$rawText
''';

    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    
    final jsonResponse = jsonDecode(response.text!) as Map<String, dynamic>;
    final List<Subject> subjects = [];
    final List<Topic> topics = [];

    final subjectsData = jsonResponse['subjects'] as List;
    
    for (var sData in subjectsData) {
      final subjectName = sData['name'] as String;
      final topicNames = sData['topics'] as List;

      final subjectId = DateTime.now().millisecondsSinceEpoch.toString() + subjects.length.toString();
      
      subjects.add(Subject(
        id: subjectId,
        userId: userId,
        goalId: goalId,
        name: subjectName,
        color: '#7C6FFF',
        priority: 3,
        weight: 5,
        difficulty: 3,
      ));

      for (var tName in topicNames) {
        topics.add(Topic(
          id: '',
          userId: userId,
          subjectId: subjectId,
          name: tName as String,
          difficulty: 3,
        ));
      }
    }

    return AISyllabusImportResult(subjects: subjects, topics: topics);
  }

  Future<List<Map<String, String>>> generateFlashcardsFromError(String userId, String question, String answer, String reason) async {
    await usageService.logAIUsage(userId, 'flashcard_generation');
    final prompt = '''
Com base no seguinte erro cometido por um estudante em uma questão de concurso, crie 3 flashcards (Pergunta e Resposta) que ajudem a memorizar o conceito correto e evitar o erro novamente.
Retorne um JSON seguindo EXATAMENTE esta estrutura:
{
  "flashcards": [
    {
      "front": "Pergunta do card",
      "back": "Resposta do card"
    }
  ]
}

Dados do erro:
- Questão: $question
- Resposta Correta: $answer
- Por que errou: $reason

Regras:
1. Seja direto e use a técnica de "cloze deletion" ou perguntas simples.
2. Foque no ponto exato da confusão do estudante.
''';

    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    
    final jsonResponse = jsonDecode(response.text!) as Map<String, dynamic>;
    final flashcardsData = jsonResponse['flashcards'] as List;
    
    return flashcardsData.map((f) => {
      'front': f['front'] as String,
      'back': f['back'] as String,
    }).toList();
  }

  Future<String> analyzePerformance({
    required String userId,
    required Map<String, double> accuracyBySubjectName,
    required int totalQuestions,
    required double consistencyPct,
    required int streakDays,
  }) async {
    await usageService.logAIUsage(userId, 'performance_analysis');
    final textModel = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );

    final prompt = '''
Você é um Mentor de Estudos implacável e motivador para concursos públicos.
Analise os seguintes dados de desempenho do aluno e forneça um feedback em 3 parágrafos curtos:
1. Elogio sobre o que está indo bem (se houver).
2. Alerta sobre os pontos fracos (matérias com baixo aproveitamento).
3. Uma sugestão prática de estudo para hoje.

Dados:
- Questões resolvidas: $totalQuestions
- Constância semanal: ${(consistencyPct * 100).toInt()}%
- Dias seguidos de estudo (streak): $streakDays
- Aproveitamento por matéria:
${accuracyBySubjectName.entries.map((e) => '  * ${e.key}: ${e.value.toStringAsFixed(1)}%').join('\n')}

IMPORTANTE: Seja direto, encorajador, mas não passe pano para notas baixas (abaixo de 70%). Não invente dados que não estão aqui.
''';

    final content = [Content.text(prompt)];
    final response = await textModel.generateContent(content);
    return response.text?.trim() ?? 'Não foi possível gerar a análise.';
  }

  Future<String> explainQuestion({
    required String userId,
    required String question,
    required String correctAnswer,
  }) async {
    await usageService.logAIUsage(userId, 'question_explanation');
    final textModel = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );

    final prompt = '''
Você é um Professor Especialista em Concursos Públicos.
Explique de forma didática, concisa e técnica por que a resposta abaixo é a correta para a questão fornecida.

Questão:
$question

Resposta Correta:
$correctAnswer

Estruture sua resposta assim:
1. **Fundamentação**: A base legal ou teórica (seja direto).
2. **O Pulo do Gato**: Destaque a pegadinha ou o ponto-chave que a banca costuma cobrar.
3. **Dica de Ouro**: Como não errar isso na próxima vez.

Use Markdown para negrito e listas. Seja breve (máximo 150 palavras).
''';

    final content = [Content.text(prompt)];
    final response = await textModel.generateContent(content);
    return response.text?.trim() ?? 'Não foi possível gerar a explicação.';
  }

  Future<List<Map<String, dynamic>>> extractQuestionsFromFiles(String userId, List<Uint8List> filesBytes, String mimeType) async {
    await usageService.logAIUsage(userId, 'exam_extraction');
    const prompt = '''
Você é um extrator de dados de alta precisão. Analise as imagens ou PDFs de provas de concurso fornecidos.
Extraia TODAS as questões completas, incluindo o enunciado, as alternativas (A, B, C, D, E) e identifique o gabarito correto.

Retorne um JSON seguindo EXATAMENTE esta estrutura:
{
  "questions": [
    {
      "statement": "Enunciado completo da questão",
      "options": {
        "A": "Texto da alternativa A",
        "B": "Texto da alternativa B",
        "C": "Texto da alternativa C",
        "D": "Texto da alternativa D",
        "E": "Texto da alternativa E"
      },
      "correctAnswer": "A",
      "subjectName": "Nome provável da matéria (ex: Direito Penal)"
    }
  ]
}

Regras:
1. Ignore cabeçalhos, rodapés e números de página.
2. Se não houver certeza do gabarito, tente inferir pela lógica ou deixe em branco.
3. Não invente questões. Extraia apenas o que está no arquivo.
''';

    final content = [
      Content.multi([
        TextPart(prompt),
        ...filesBytes.map((b) => DataPart(mimeType, b)),
      ])
    ];

    final response = await _model.generateContent(content);
    final jsonResponse = jsonDecode(response.text!) as Map<String, dynamic>;
    return (jsonResponse['questions'] as List).cast<Map<String, dynamic>>();
  }
}
