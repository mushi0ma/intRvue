/// ЖИ бағасы: үш өлшем, әрқайсысы 0–5.
class Assessment {
  const Assessment({
    required this.correctness,
    required this.completeness,
    required this.clarity,
    required this.headline,
    required this.advice,
    required this.evidence,
    required this.missing,
  });

  final int correctness;
  final int completeness;
  final int clarity;

  /// «Негізгі ой дұрыс.»
  final String headline;

  /// «Күйдің өмірлік циклін нақтылаңыз.»
  final String advice;

  /// «Жауабыңыздағы дәлел» бөлімі.
  final String evidence;

  /// «Нені толықтыру керек» бөлімі.
  final List<String> missing;

  static const int maxPerCriterion = 5;
  static const int maxTotal = 15;

  int get total => correctness + completeness + clarity;
}
