import 'package:flutter_test/flutter_test.dart';
import 'package:vilka/domain/llm/teacher_prompt_generator.dart';

void main() {
  test('Korean + RU prompt keeps legacy format marker', () {
    final prompt = TeacherPromptGenerator.generate(
      nativeLanguage: 'ru',
      currentTopicKey: 'cafe',
      learnedPhrases: ['메뉴판 주세요.'],
      studentName: 'Анна',
      homeworkTask: 'Повторить фразы кафе',
    );
    expect(prompt, contains('учитель корейского языка'));
    expect(prompt, contains('[RU]'));
    expect(prompt, contains('메뉴판 주세요.'));
    expect(prompt, contains('DO NOT USE ENGLISH UNDER ANY CIRCUMSTANCES'));
    expect(prompt, contains('Name: Анна'));
    expect(prompt, contains('Active Homework Task: Повторить фразы кафе'));
  });

  test('Korean + EN prompt uses [EN] marker', () {
    final prompt = TeacherPromptGenerator.generate(
      nativeLanguage: 'en',
      currentTopicKey: 'cafe',
      learnedPhrases: const [],
      studentName: 'Alex',
      homeworkTask: 'Finish the first audio lesson',
    );
    expect(prompt, contains('Korean teacher'));
    expect(prompt, contains('[EN]'));
    expect(prompt, contains('Name: Alex'));
    expect(
      prompt,
      contains('Active Homework Task: Finish the first audio lesson'),
    );
  });

  test('generateWithProfile prepends the student profile block', () {
    final prompt = TeacherPromptGenerator.generateWithProfile(
      nativeLanguage: 'ru',
      currentTopicKey: 'shop',
      learnedPhrases: const ['이거 얼마예요?'],
      studentName: 'Мария',
      homeworkTask: 'Пройти первый аудиоурок и ознакомиться с фразами',
    );
    expect(prompt.startsWith('[STUDENT_PROFILE]'), isTrue);
    expect(prompt, contains('Name: Мария'));
    expect(prompt, contains('Current Level: 0'));
    expect(
      prompt,
      contains(
        'Active Homework Task: Пройти первый аудиоурок и ознакомиться с фразами',
      ),
    );
    expect(prompt, contains('[/STUDENT_PROFILE]'));
    expect(
      prompt,
      contains('Обращайся к ученику по имени, когда это уместно'),
    );
  });

  test('empty profile fields fall back to Ученик and Пройти урок', () {
    final prompt = TeacherPromptGenerator.generateWithProfile(
      nativeLanguage: 'ru',
      currentTopicKey: 'cafe',
      learnedPhrases: const [],
      studentName: '  ',
      homeworkTask: '',
    );
    expect(prompt, contains('Name: Ученик'));
    expect(prompt, contains('Active Homework Task: Пройти урок'));
  });
}
