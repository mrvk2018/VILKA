import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vilka/core/ui_locale.dart';
import 'package:vilka/domain/course/phrase.dart';
import 'package:vilka/domain/exam/exam_question_builder.dart';

Phrase _phrase({
  required int id,
  required int topicId,
  required String ko,
  required String ru,
  required String en,
}) {
  return Phrase(
    id: id,
    topicId: topicId,
    koreanText: ko,
    russianTranslation: ru,
    englishTranslation: en,
    audioUrlOrPath: '',
    order: id,
    learningLanguageCode: 'ko',
  );
}

void main() {
  test('builds four unique options with a matching correct index', () {
    final topic = [
      _phrase(id: 1, topicId: 1, ko: '안녕', ru: 'Привет', en: 'Hi'),
      _phrase(id: 2, topicId: 1, ko: '고마워', ru: 'Спасибо', en: 'Thanks'),
      _phrase(id: 3, topicId: 1, ko: '네', ru: 'Да', en: 'Yes'),
      _phrase(id: 4, topicId: 1, ko: '아니요', ru: 'Нет', en: 'No'),
    ];
    final questions = ExamQuestionBuilder(random: Random(1)).build(
      topicPhrases: topic,
      coursePhrases: const [],
      locale: UiLocale.ru,
    );
    expect(questions, hasLength(4));
    for (final question in questions) {
      expect(question.options.toSet(), hasLength(4));
      expect(question.options[question.correctIndex], isNotEmpty);
      final source = topic.firstWhere((item) => item.id == question.phraseId);
      expect(question.options[question.correctIndex], source.russianTranslation);
      expect(question.koreanText, source.koreanText);
    }
  });

  test('fills distractors from other topics when the local pool is small', () {
    final topic = [
      _phrase(id: 1, topicId: 1, ko: '안녕', ru: 'Привет', en: 'Hi'),
      _phrase(id: 2, topicId: 1, ko: '고마워', ru: 'Спасибо', en: 'Thanks'),
    ];
    final course = [
      ...topic,
      _phrase(id: 10, topicId: 2, ko: '네', ru: 'Да', en: 'Yes'),
      _phrase(id: 11, topicId: 2, ko: '아니요', ru: 'Нет', en: 'No'),
    ];
    final questions = ExamQuestionBuilder(random: Random(2)).build(
      topicPhrases: topic,
      coursePhrases: course,
      locale: UiLocale.en,
    );
    expect(questions, hasLength(2));
    for (final question in questions) {
      expect(question.options, hasLength(4));
      expect(question.options.toSet(), hasLength(4));
    }
  });
}
