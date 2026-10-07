import 'dart:math';

import '../../core/ui_locale.dart';
import '../course/phrase.dart';

class ExamQuestion {
  const ExamQuestion({
    required this.phraseId,
    required this.koreanText,
    required this.options,
    required this.correctIndex,
  });

  final int phraseId;
  final String koreanText;
  final List<String> options;
  final int correctIndex;
}

/// In-memory multiple-choice builder. Topic phrases first, then course pool.
class ExamQuestionBuilder {
  ExamQuestionBuilder({Random? random}) : _random = random ?? Random();

  static const distractorCount = 3;

  final Random _random;

  List<ExamQuestion> build({
    required List<Phrase> topicPhrases,
    required List<Phrase> coursePhrases,
    required UiLocale locale,
  }) {
    final questions = <ExamQuestion>[];
    for (final phrase in topicPhrases) {
      final question = _questionFor(
        phrase: phrase,
        topicPhrases: topicPhrases,
        coursePhrases: coursePhrases,
        locale: locale,
      );
      if (question != null) {
        questions.add(question);
      }
    }
    questions.shuffle(_random);
    return questions;
  }

  ExamQuestion? _questionFor({
    required Phrase phrase,
    required List<Phrase> topicPhrases,
    required List<Phrase> coursePhrases,
    required UiLocale locale,
  }) {
    final correct = phrase.translationFor(locale).trim();
    if (phrase.koreanText.trim().isEmpty || correct.isEmpty) {
      return null;
    }
    final topicPool = _uniqueTranslations(
      phrases: topicPhrases,
      locale: locale,
      exclude: correct,
    );
    final coursePool = _uniqueTranslations(
      phrases: coursePhrases,
      locale: locale,
      exclude: correct,
    );
    final distractors = <String>[];
    _fillUnique(distractors, topicPool);
    _fillUnique(distractors, coursePool);
    if (distractors.isEmpty) {
      return null;
    }
    final options = [...distractors.take(distractorCount), correct]..shuffle(_random);
    return ExamQuestion(
      phraseId: phrase.id,
      koreanText: phrase.koreanText,
      options: options,
      correctIndex: options.indexOf(correct),
    );
  }

  void _fillUnique(List<String> target, List<String> source) {
    final seen = {for (final item in target) _key(item)};
    final shuffled = [...source]..shuffle(_random);
    for (final item in shuffled) {
      if (target.length >= distractorCount) {
        return;
      }
      if (seen.add(_key(item))) {
        target.add(item);
      }
    }
  }

  List<String> _uniqueTranslations({
    required List<Phrase> phrases,
    required UiLocale locale,
    required String exclude,
  }) {
    final excludeKey = _key(exclude);
    final seen = <String>{};
    final values = <String>[];
    for (final phrase in phrases) {
      final text = phrase.translationFor(locale).trim();
      if (text.isEmpty) {
        continue;
      }
      final key = _key(text);
      if (key == excludeKey) {
        continue;
      }
      if (seen.add(key)) {
        values.add(text);
      }
    }
    return values;
  }

  String _key(String value) => value.trim().toLowerCase();
}
