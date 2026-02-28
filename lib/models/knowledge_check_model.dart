class KnowledgeCheckQuestion {
  final String statement;
  final bool isTrue;
  final String explanation;

  KnowledgeCheckQuestion({
    required this.statement,
    required this.isTrue,
    required this.explanation,
  });

  factory KnowledgeCheckQuestion.fromJson(Map<String, dynamic> json) {
    return KnowledgeCheckQuestion(
      statement: json['statement'] ?? '',
      isTrue: json['isTrue'] ?? false,
      explanation: json['explanation'] ?? '',
    );
  }
}
