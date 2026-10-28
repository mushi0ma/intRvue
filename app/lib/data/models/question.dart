/// Бағалау кезінде жауаптан ізделетін ұғым.
class Concept {
  const Concept(this.label, this.keywords);

  /// «Нені толықтыру керек» бөлімінде көрсетілетін атау.
  final String label;

  /// Жауапта кездессе, ұғым ашылған деп саналады (кіші әріппен).
  final List<String> keywords;
}

class Question {
  const Question({
    required this.id,
    required this.topicId,
    required this.text,
    required this.modelAnswer,
    required this.concepts,
    this.hint = 'Өз сөзіңізбен түсіндіріп, мысал келтіріңіз.',
  });

  final String id;
  final String topicId;
  final String text;
  final String hint;
  final String modelAnswer;
  final List<Concept> concepts;
}
