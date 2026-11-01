import '../models/assessment.dart';
import '../models/question.dart';

/// ЖИ бағалауының жергілікті имитациясы.
///
/// Нақты модель кейінгі кезеңде қосылады. Қазір баға жауаптағы негізгі
/// ұғымдар мен мәтін көлеміне қарап есептеледі — интерфейс пен
/// навигацияны тексеруге жеткілікті.
class AssessmentService {
  const AssessmentService({this.delay = const Duration(milliseconds: 900)});

  final Duration delay;

  Future<Assessment> assess(Question question, String answer) async {
    await Future<void>.delayed(delay);
    return evaluate(question, answer);
  }

  Assessment evaluate(Question question, String answer) {
    final text = answer.toLowerCase();
    final matched = <Concept>[];
    final missing = <Concept>[];
    for (final concept in question.concepts) {
      final found = concept.keywords.any(text.contains);
      (found ? matched : missing).add(concept);
    }

    final coverage = question.concepts.isEmpty
        ? 0.0
        : matched.length / question.concepts.length;
    final words = answer
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty);
    final sentences = RegExp(r'[.!?](\s|$)').allMatches(answer.trim()).length;

    const top = Assessment.maxPerCriterion;
    final tooShort = words.length < 4;
    final correctness = tooShort
        ? 1
        : (1 + coverage * (top - 1)).round().clamp(1, top);
    final completeness = (coverage * top).round().clamp(0, top);
    var clarity = switch (words.length) {
      < 4 => 1,
      < 10 => 2,
      < 20 => 3,
      _ => 4,
    };
    if (sentences >= 2 && clarity < top) clarity++;

    final average = (correctness + completeness + clarity) / 3;
    final headline = switch (average) {
      >= 4.3 => 'Жауап толық әрі нақты.',
      >= 3 => 'Негізгі ой дұрыс.',
      >= 2 => 'Бағыт дұрыс, бірақ толық емес.',
      _ => 'Жауап сұраққа толық сәйкес емес.',
    };
    final advice = missing.isEmpty
        ? 'Келесі сұраққа өтуге болады.'
        : '«${missing.first.label}» бөлігін нақтылаңыз.';

    final firstSentence = answer.trim().split(RegExp(r'(?<=[.!?])\s')).first;
    final quote = firstSentence.length > 90
        ? '${firstSentence.substring(0, 90).trimRight()}…'
        : firstSentence;
    final evidence = matched.isEmpty
        ? 'Жауапта сұрақтың негізгі ұғымдары табылмады.'
        : '«$quote» — ${matched.map((c) => c.label).join(', ')} '
              'дұрыс аталған.';

    return Assessment(
      correctness: correctness,
      completeness: completeness,
      clarity: clarity,
      headline: headline,
      advice: advice,
      evidence: evidence,
      missing: missing.map((c) => c.label).toList(),
    );
  }
}
