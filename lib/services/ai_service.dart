import 'dart:convert';
import 'dart:typed_data';
import 'package:dart_openai/dart_openai.dart';
import '../models/subject_model.dart';
import '../models/topic_model.dart';
import '../models/daily_task_model.dart';
import '../core/utils/app_date_utils.dart';
import 'usage_service.dart';
import 'package:uuid/uuid.dart';
import '../models/knowledge_check_model.dart';

class AISyllabusImportResult {
  final List<Subject> subjects;
  final List<Topic> topics;

  AISyllabusImportResult({required this.subjects, required this.topics});
}

class AIService {
  final String apiKey;
  final UsageService _usageService;
  static const String _model = "llama-3.3-70b-versatile";
  static const String _visionModel = "llama-3.2-11b-vision-preview";

  AIService({required this.apiKey, required UsageService usageService})
      : _usageService = usageService {
    OpenAI.apiKey = apiKey;
    OpenAI.baseUrl = "https://api.groq.com/openai";
  }

  Future<AISyllabusImportResult> parseSyllabus(
      String rawText, String userId, String? goalId) async {
    await _usageService.logAIUsage(userId, 'syllabus_import');
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

    final response = await OpenAI.instance.chat.create(
      model: _model,
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt)
          ],
          role: OpenAIChatMessageRole.user,
        ),
      ],
      responseFormat: {"type": "json_object"},
    );

    final String? responseText =
        response.choices.first.message.content?.first.text;
    if (responseText == null) {
      throw Exception('FALHA_GERACAO_IA: Resposta vazia.');
    }

    final jsonResponse = jsonDecode(responseText) as Map<String, dynamic>;
    final List<Subject> subjects = [];
    final List<Topic> topics = [];

    final subjectsData = jsonResponse['subjects'] as List;

    for (var sData in subjectsData) {
      final subjectName = sData['name'] as String;
      final topicNames = sData['topics'] as List;

      final subjectId = DateTime.now().millisecondsSinceEpoch.toString() +
          subjects.length.toString();

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

  Future<List<Map<String, dynamic>>> suggestSubjectsForObjective(
      String userId, String objective) async {
    await _usageService.logAIUsage(userId, 'subject_suggestion');
    final prompt = '''
Com base no objetivo de estudo "$objective", sugira as 6 a 10 matérias mais importantes e comuns que um estudante precisa focar para ser aprovado.
Para cada matéria, inclua também de 5 a 10 tópicos principais (assuntos) que costumam ser cobrados.
Atribua a cada matéria uma cor em hex (cores vibrantes), uma prioridade de 1 a 5 e um peso de prova de 1 a 10.

Retorne um JSON seguindo EXATAMENTE esta estrutura:
{
  "subjects": [
    {
      "name": "Nome da Matéria",
      "color": "#7C6FFF",
      "priority": 4,
      "weight": 8,
      "topics": ["Tópico 1", "Tópico 2", "Tópico 3"]
    }
  ]
}

Regras:
1. Seja preciso nos nomes das matérias e tópicos.
2. Se o objetivo for genérico, use matérias e tópicos base (ex: Português -> Gramática, Interpretação, etc).
3. Retorne APENAS o JSON, sem explicações.
''';

    final response = await OpenAI.instance.chat.create(
      model: _model,
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt)
          ],
          role: OpenAIChatMessageRole.user,
        ),
      ],
      responseFormat: {"type": "json_object"},
    );

    final String? responseText =
        response.choices.first.message.content?.first.text;
    if (responseText == null)
      throw Exception('FALHA_GERACAO_IA: Resposta vazia.');

    final jsonResponse = jsonDecode(responseText) as Map<String, dynamic>;
    return (jsonResponse['subjects'] as List).cast<Map<String, dynamic>>();
  }

  Future<String> getDailyInsight({
    required String userId,
    required String objective,
    required List<String> taskNames,
    int streak = 0,
    double consistency = 0.0,
  }) async {
    await _usageService.logAIUsage(userId, 'daily_insight');

    final tasksContext = taskNames.isEmpty
        ? "Nenhuma tarefa planejada para hoje."
        : "Tarefas de hoje: ${taskNames.join(', ')}.";

    final streakContext = streak > 0
        ? "O aluno está em uma sequência de $streak dias!"
        : "O aluno está começando ou voltando aos estudos hoje.";

    final consistencyContext =
        "A constância semanal é de ${(consistency * 100).toInt()}%.";

    final prompt = '''
Você é um Coach de Estudos motivador e pragmático.
Com base no objetivo "$objective", nas tarefas de hoje e no desempenho recente, forneça um briefing curto (máximo 2-3 frases) e encorajador.

DADOS DO ALUNO:
- Objetivo: $objective
- $tasksContext
- $streakContext
- $consistencyContext

REGRAS:
1. Seja muito breve e direto. Use um tom de "parceiro de estudos".
2. Mencione a sequência (streak) ou constância apenas se for relevante para motivar.
3. Se não houver tarefas, incentive o planejamento ou o descanso produtivo.
4. Fale em Português do Brasil.
5. NÃO use mais de 150 caracteres.
''';

    final response = await OpenAI.instance.chat.create(
      model: _model,
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt)
          ],
          role: OpenAIChatMessageRole.user,
        ),
      ],
    );

    return response.choices.first.message.content?.first.text?.trim() ??
        'Vamos focar nos estudos hoje!';
  }

  Future<List<Map<String, String>>> generateFlashcardsFromError(
      String userId, String question, String answer, String reason) async {
    await _usageService.logAIUsage(userId, 'flashcard_generation');
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

    final response = await OpenAI.instance.chat.create(
      model: _model,
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt)
          ],
          role: OpenAIChatMessageRole.user,
        ),
      ],
      responseFormat: {"type": "json_object"},
    );

    final String? responseText =
        response.choices.first.message.content?.first.text;
    if (responseText == null)
      throw Exception('FALHA_GERACAO_IA: Resposta vazia.');

    final jsonResponse = jsonDecode(responseText) as Map<String, dynamic>;
    final flashcardsData = jsonResponse['flashcards'] as List;

    return flashcardsData
        .map((f) => {
              'front': f['front'] as String,
              'back': f['back'] as String,
            })
        .toList();
  }

  Future<String> analyzePerformance({
    required String userId,
    required Map<String, double> accuracyBySubjectName,
    required int totalQuestions,
    required double consistencyPct,
    required int streakDays,
  }) async {
    await _usageService.logAIUsage(userId, 'performance_analysis');

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

    final response = await OpenAI.instance.chat.create(
      model: _model,
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt)
          ],
          role: OpenAIChatMessageRole.user,
        ),
      ],
    );

    return response.choices.first.message.content?.first.text?.trim() ??
        'Não foi possível gerar a análise.';
  }

  Future<String> getQuickHint({
    required String userId,
    required String question,
    required List<String> options,
  }) async {
    await _usageService.logAIUsage(userId, 'question_hint');

    final prompt = '''
Você é um Tutor IA pedagógico. O aluno está tentando resolver uma questão e precisa de uma DICA.
JAMAIS dê a resposta direta. Forneça uma pista que ajude o aluno a raciocinar por conta própria.

Questão:
$question

Alternativas:
${options.join('\n')}

Regras:
1. Seja breve (máximo 2 sentenças).
2. Use um tom instigante.
3. Foque no conceito ou na lógica por trás do problema.
''';

    final response = await OpenAI.instance.chat.create(
      model: _model,
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt)
          ],
          role: OpenAIChatMessageRole.user,
        ),
      ],
    );

    return response.choices.first.message.content?.first.text?.trim() ??
        'Pense na base do conceito discutido.';
  }

  Future<List<String>> eliminateAlternatives({
    required String userId,
    required String question,
    required Map<String, String> options,
    required String correctAnswer,
  }) async {
    await _usageService.logAIUsage(userId, 'eliminate_alternatives');

    final prompt = '''
Você é um assistente de exames. Dada a questão e as alternativas abaixo, identifique EXATAMENTE duas alternativas incorretas que podem ser eliminadas para ajudar o aluno.

Questão:
$question

Alternativas:
${options.entries.map((e) => "${e.key}: ${e.value}").join('\n')}

Resposta Correta:
$correctAnswer

Retorne apenas as letras das duas alternativas incorretas separadas por vírgula (ex: B, D).
''';

    final response = await OpenAI.instance.chat.create(
      model: _model,
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt)
          ],
          role: OpenAIChatMessageRole.user,
        ),
      ],
    );

    final text =
        response.choices.first.message.content?.first.text?.trim() ?? '';
    return text.split(',').map((e) => e.trim().toUpperCase()).toList();
  }

  Future<String> explainConcept({
    required String userId,
    required String question,
  }) async {
    await _usageService.logAIUsage(userId, 'explain_concept');

    final prompt = '''
Você é um Professor Especialista. O aluno quer entender o CONCEITO TEÓRICO por trás desta questão, sem necessariamente ver a explicação da resposta ainda.

Questão:
$question

Explique o tema central desta questão de forma didática e técnica. No máximo 100 palavras.
''';

    final response = await OpenAI.instance.chat.create(
      model: _model,
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt)
          ],
          role: OpenAIChatMessageRole.user,
        ),
      ],
    );

    return response.choices.first.message.content?.first.text?.trim() ??
        'Não foi possível extrair o conceito agora.';
  }

  Future<String> getDetailedExplanation({
    required String userId,
    required String question,
    required String correctAnswer,
  }) async {
    await _usageService.logAIUsage(userId, 'question_explanation');

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

    final response = await OpenAI.instance.chat.create(
      model: _model,
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt)
          ],
          role: OpenAIChatMessageRole.user,
        ),
      ],
    );

    return response.choices.first.message.content?.first.text?.trim() ??
        'Não foi possível gerar a explanation.';
  }

  Future<List<KnowledgeCheckQuestion>> generateKnowledgeCheck({
    required String subject,
    required String topic,
  }) async {
    final prompt = '''
Você é um especialista em $subject.
O aluno acabou de estudar o tópico "$topic".
Gere exatamente 5 perguntas de VERDADEIRO ou FALSO (fáceis para médias) sobre este tópico para verificar o aprendizado rápido.
Retorne um objeto JSON com uma chave "questions", cujo valor seja um array com o seguinte formato exato (sem formatação markdown como ```json):
{
  "questions": [
    {
      "statement": "O Sol gira ao redor da Terra.",
      "isTrue": false,
      "explanation": "No modelo heliocêntrico, a Terra gira ao redor do Sol."
    }
  ]
}
Apenas retorne o JSON.
''';

    final response = await OpenAI.instance.chat.create(
      model: _model,
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt)
          ],
          role: OpenAIChatMessageRole.user,
        ),
      ],
      responseFormat: {
        "type": "json_object"
      }, // Not always supported by all models, but groq handles json output if instructed. Wait, we usually parse it raw. Let's just ask for JSON without json_object to be safe with standard models.
    );

    final rawText =
        response.choices.first.message.content?.first.text?.trim() ?? '[]';
    final cleanText =
        rawText.replaceAll('```json', '').replaceAll('```', '').trim();

    try {
      final dynamic decoded = jsonDecode(cleanText);
      List<dynamic> questionsList = [];

      if (decoded is Map<String, dynamic>) {
        questionsList = decoded['questions'] ?? [];
        if (questionsList.isEmpty) {
          final lists = decoded.values.whereType<List<dynamic>>();
          if (lists.isNotEmpty) questionsList = lists.first;
        }
      } else if (decoded is List<dynamic>) {
        questionsList = decoded;
      }

      return questionsList
          .map((e) => KnowledgeCheckQuestion.fromJson(e))
          .toList();
    } catch (e) {
      print('Failed to parse knowledge check JSON: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> extractQuestionsFromFiles(
      String userId, List<Uint8List> filesBytes, String mimeType) async {
    await _usageService.logAIUsage(userId, 'exam_extraction');
    // Note: OpenAI vision models expect URLs or base64 data.
    // For simplicity in this refactor, we are using the legacy prompt but OpenAI vision would be better.
    // However, since the goal is a refactor, we adapt.

    final List<OpenAIChatCompletionChoiceMessageContentItemModel> content = [
      OpenAIChatCompletionChoiceMessageContentItemModel.text('''
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
      "subjectName": "Nome provável da matéria",
      "topicName": "Nome provável do tópico"
    }
  ]
}

Regras:
1. Ignore cabeçalhos, rodapés e números de página.
2. Se não houver certeza do gabarito, tente inferir pela lógica ou deixe em branco.
3. Não invente questões. Extraia apenas o que está no arquivo.
'''),
    ];

    for (var bytes in filesBytes) {
      final base64Image = base64Encode(bytes);
      content.add(OpenAIChatCompletionChoiceMessageContentItemModel.imageUrl(
        'data:image/jpeg;base64,$base64Image',
      ));
    }

    final response = await OpenAI.instance.chat.create(
      model: _visionModel,
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          content: content,
          role: OpenAIChatMessageRole.user,
        ),
      ],
    ); // Removed responseFormat to avoid 400 with vision in some Groq models

    final String? responseText =
        response.choices.first.message.content?.first.text;
    if (responseText == null)
      throw Exception('FALHA_GERACAO_IA: Resposta vazia.');

    // Manual extraction of JSON if model returns text around it
    final jsonStart = responseText.indexOf('{');
    final jsonEnd = responseText.lastIndexOf('}');
    if (jsonStart == -1 || jsonEnd == -1) {
      throw Exception('FALHA_GERACAO_IA: Resposta não contém JSON válido.');
    }
    final cleanText = responseText.substring(jsonStart, jsonEnd + 1);

    final jsonResponse = jsonDecode(cleanText) as Map<String, dynamic>;
    return (jsonResponse['questions'] as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> generateQuestionsForBank({
    required String subject,
    required String topic,
    int count = 5,
  }) async {
    final prompt = '''
Você é um Especialista em Bancas de Concurso Público.
Gere $count questões inéditas e de alta qualidade sobre a matéria "$subject" e o tópico "$topic".
As questões devem ser de múltipla escolha com 5 alternativas (A, B, C, D, E).

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
      "subjectName": "$subject",
      "topicName": "$topic"
    }
  ]
}

Regras:
1. As questões devem ser desafiadoras e similares às de bancas reais (ex: FCC, FGV, Cebraspe).
2. Não use questões óbvias.
3. Retorne APENAS o JSON.
''';

    final response = await OpenAI.instance.chat.create(
      model: _model,
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt)
          ],
          role: OpenAIChatMessageRole.user,
        ),
      ],
      responseFormat: {"type": "json_object"},
    );

    final String? responseText =
        response.choices.first.message.content?.first.text;
    if (responseText == null)
      throw Exception('FALHA_GERACAO_IA: Resposta vazia.');

    final jsonResponse = jsonDecode(responseText) as Map<String, dynamic>;
    return (jsonResponse['questions'] as List).cast<Map<String, dynamic>>();
  }

  Future<List<DailyTask>> generateSmartSchedule({
    required String userId,
    required String goalId,
    required List<Subject> subjects,
    required List<Topic> topics,
    required DateTime startDate,
    required int durationDays,
    required String routineContext,
  }) async {
    await _usageService.logAIUsage(userId, 'schedule_generation');

    final subjectsInfo = subjects.map((s) {
      final subjectTopics =
          topics.where((t) => t.subjectId == s.id).map((t) => t.name).toList();
      return '- ${s.name} (ID: ${s.id}, Peso: ${s.weight}, Dificuldade: ${s.difficulty}): ${subjectTopics.join(", ")}';
    }).join('\n');

    final prompt = '''
Você é um Mentor de Estudos especialista em concursos. Sua tarefa é criar um cronograma de estudos inteligente e realista.

DADOS DO ALUNO:
- Objetivo: Plano de $durationDays dias começando em ${AppDateUtils.displayDate(startDate)}.
- Matérias e Tópicos:
$subjectsInfo

CONTEXTO DA ROTINA:
$routineContext

REGRAS CRÍTICAS PARA O CRONOGRAMA:
1. LIMITE E SEQUÊNCIA (Obrigatório): JAMAIS sugira mais de 2 matérias por dia. O ideal é 1 ou 2 para manter o foco.
2. PROGRESSÃO LÓGICA: Comece pelos tópicos fundamentais e siga uma ordem didática.
3. REVISÃO: Reserve um dia na semana (preferencialmente domingo) EXCLUSIVO para revisão. Não coloque matéria nova no dia de revisão.
4. CARGA HORÁRIA: Respeite a rotina. Se o aluno descreveu poucas horas, diminua a quantidade de tarefas, não as diminua o tempo de cada uma para menos de 45min.
5. DESCRIÇÃO: Tente alocar os tópicos de forma que o aluno termine um antes de começar o outro, se possível.

Retorne um JSON seguindo EXATAMENTE esta estrutura:
{
  "schedule": [
    {
      "dayOffset": 0,
      "tasks": [
        {
          "subjectId": "ID_DA_MATERIA",
          "subjectName": "NOME_DA_MATERIA (Apenas para referência)",
          "topicName": "NOME_DO_TOPICO_EXATO",
          "minutes": 90
        }
      ]
    }
  ]
}

IMPORTANTE: 
- O "dayOffset" é o número de dias a partir da data de início (0 = primeiro dia).
- Gere tarefas para TODOS os $durationDays dias.
- Use os nomes de tópicos e IDs de matérias fornecidos exatamente.
- Retorne APENAS o JSON.
''';

    final response = await OpenAI.instance.chat.create(
      model: _model,
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt)
          ],
          role: OpenAIChatMessageRole.user,
        ),
      ],
      responseFormat: {"type": "json_object"},
    );

    final String? responseText =
        response.choices.first.message.content?.first.text;
    if (responseText == null)
      throw Exception('FALHA_GERACAO_IA: Resposta vazia.');

    try {
      final jsonResponse = jsonDecode(responseText) as Map<String, dynamic>;
      final scheduleData = jsonResponse['schedule'] as List;
      final List<DailyTask> tasks = [];
      const uuid = Uuid();

      final topicNameToId = {for (final t in topics) t.name: t.id};

      for (var dayData in scheduleData) {
        final dayOffset = dayData['dayOffset'] as int;
        final date = startDate.add(Duration(days: dayOffset));
        final dateKey = AppDateUtils.toKey(date);
        final dayTasks = dayData['tasks'] as List;

        for (var taskData in dayTasks) {
          final sId = taskData['subjectId'] as String;
          final tName = taskData['topicName'] as String;
          final mins = taskData['minutes'] as int;
          final tId = topicNameToId[tName] ?? '';

          tasks.add(DailyTask(
            id: uuid.v4(),
            userId: userId,
            goalId: goalId,
            date: dateKey,
            subjectId: sId,
            topicId: tId,
            plannedMinutes: mins,
            done: false,
            actualMinutes: 0,
          ));
        }
      }
      return tasks;
    } catch (e) {
      print('Erro ao parsear cronograma IA: $e');
      throw Exception('FALHA_GERACAO_IA: Não foi possível estruturar o plano.');
    }
  }

  Future<Map<String, dynamic>> suggestStudyPlanConfig({
    required String userId,
    required String objective,
    required String routineContext,
  }) async {
    await _usageService.logAIUsage(userId, 'plan_suggestion');

    final prompt = '''
Você é um Consultor de Estudos especializado em produtividade.
Com base no objetivo de estudo do aluno e no contexto de sua rotina (disponibilidade, trabalho, etc), sugira uma configuração ideal para o plano de estudos.

OBJETIVO: $objective
ROTINA/CONTEXTO: $routineContext

Retorne um JSON seguindo EXATAMENTE esta estrutura:
{
  "startDate": "YYYY-MM-DD",
  "durationDays": 90,
  "dailyHours": 4.5,
  "reasoning": "Breve explicação do porquê dessas sugestões (max 100 caracteres)."
}

Regras:
1. "startDate": Sugira uma data de início razoável, formatada como YYYY-MM-DD. Hoje é ${DateTime.now().toString().split(' ')[0]}.
2. "durationDays": Sugira uma duração REALISTA. Se houver muitas matérias (mais de 5), sugira ao menos 60-90 dias. Nunca menos de 30 dias para estudos sérios.
3. "dailyHours": Sugira uma carga horária diária SUSTENTÁVEL. Estudar 8h por dia trabalhando é impossível. Seja um mentor realista (ex: 2h a 4h para quem trabalha).
4. "reasoning": Explique a lógica como um mentor experiente em Português.

Retorne APENAS o JSON.
''';

    final response = await OpenAI.instance.chat.create(
      model: _model,
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt)
          ],
          role: OpenAIChatMessageRole.user,
        ),
      ],
      responseFormat: {"type": "json_object"},
    );

    final String? responseText =
        response.choices.first.message.content?.first.text;
    if (responseText == null) {
      throw Exception('FALHA_GERACAO_IA: Resposta vazia.');
    }

    return jsonDecode(responseText) as Map<String, dynamic>;
  }

  Future<Map<String, String>> generateFlashcardFromQuestion({
    required String question,
    required String answer,
  }) async {
    final prompt = '''
Você é um Especialista em Aprendizado Acelerado.
Com base nesta questão de concurso e seu gabarito, crie um flashcard conciso e eficaz (Frente e Verso).
A frente deve ser uma pergunta ou lacuna desafiadora. O verso deve ser a resposta direta.

QUESTÃO: $question
GABARITO: $answer

Retorne um JSON seguindo EXATAMENTE esta estrutura:
{
  "front": "Texto da frente do flashcard",
  "back": "Texto do verso do flashcard"
}

Regras:
1. Seja muito conciso.
2. Evite repetir todo o enunciado se não for necessário.
3. Foque no conceito chave cobrado na questão.
4. Retorne APENAS o JSON.
''';

    final response = await OpenAI.instance.chat.create(
      model: _model,
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt)
          ],
          role: OpenAIChatMessageRole.user,
        ),
      ],
      responseFormat: {"type": "json_object"},
    );

    final String? responseText =
        response.choices.first.message.content?.first.text;
    if (responseText == null) throw Exception('Resposta da IA vazia.');

    final jsonResponse = jsonDecode(responseText) as Map<String, dynamic>;
    return {
      "front": jsonResponse["front"] as String,
      "back": jsonResponse["back"] as String,
    };
  }
}
