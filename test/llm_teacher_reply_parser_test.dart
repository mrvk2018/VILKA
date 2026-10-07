import 'package:flutter_test/flutter_test.dart';
import 'package:vilka/domain/llm/llm_teacher_reply_parser.dart';

void main() {
  group('LlmTeacherReplyParser', () {
    test('splits Korean and RU explanation on [RU] marker', () {
      const raw = '안녕하세요! [RU] Здравствуйте!';
      final parsed = LlmTeacherReplyParser.parse(raw, 'ru');
      expect(parsed.koreanPart, '안녕하세요!');
      expect(parsed.explanationPart, 'Здравствуйте!');
      expect(parsed.displayText, '안녕하세요!\n\nЗдравствуйте!');
    });

    test('marker is case-insensitive and allows spaces', () {
      const raw = '안녕하세요! [ ru ] Привет';
      final parsed = LlmTeacherReplyParser.parse(raw, 'ru');
      expect(parsed.koreanPart, '안녕하세요!');
      expect(parsed.explanationPart, 'Привет');
    });

    test('returns whole text as Korean when marker is missing', () {
      const raw = '안녕하세요!';
      final parsed = LlmTeacherReplyParser.parse(raw, 'ru');
      expect(parsed.koreanPart, raw);
      expect(parsed.explanationPart, isEmpty);
      expect(parsed.displayText, raw);
    });

    test('sanitizeForKoreanTts strips Cyrillic and Latin', () {
      const raw = '안녕하세요 Hello Привет 123!';
      expect(
        LlmTeacherReplyParser.sanitizeForKoreanTts(raw),
        '안녕하세요 123!',
      );
    });

    test('sanitizeForKoreanTts can yield empty speechText', () {
      expect(LlmTeacherReplyParser.sanitizeForKoreanTts('Hello Привет'), isEmpty);
    });
  });
}
