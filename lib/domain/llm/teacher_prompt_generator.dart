import 'llm_teacher_reply_parser.dart';

/// Port of legacy `TeacherPromptGenerator`, parameterized by UI + target language.
class TeacherPromptGenerator {
  static const _learningLanguageNamesRu = {
    'ko': 'корейского языка',
    'ja': 'японского языка',
    'zh': 'китайского языка',
  };

  static const _learningLanguageNamesEn = {
    'ko': 'Korean',
    'ja': 'Japanese',
    'zh': 'Chinese',
  };

  static const defaultStudentName = 'Ученик';
  static const defaultHomeworkTask = 'Пройти урок';

  static String generate({
    required String nativeLanguage,
    required String currentTopicKey,
    required List<String> learnedPhrases,
    String learningLanguageCode = 'ko',
    String? studentName,
    String? homeworkTask,
  }) {
    return generateWithProfile(
      nativeLanguage: nativeLanguage,
      currentTopicKey: currentTopicKey,
      learnedPhrases: learnedPhrases,
      learningLanguageCode: learningLanguageCode,
      studentName: studentName,
      homeworkTask: homeworkTask,
    );
  }

  static String generateWithProfile({
    required String nativeLanguage,
    required String currentTopicKey,
    required List<String> learnedPhrases,
    String learningLanguageCode = 'ko',
    String? studentName,
    String? homeworkTask,
  }) {
    final phrasesBlock = learnedPhrases
        .where((item) => item.trim().isNotEmpty)
        .map((item) => '- $item')
        .join('\n');
    final phrases = phrasesBlock.isEmpty
        ? '- (пока нет заученных фраз)'
        : phrasesBlock;

    final isRussianNative = nativeLanguage.toLowerCase() != 'en';
    final formatMarker = LlmTeacherReplyParser.markerForNativeLanguage(
      nativeLanguage,
    );
    final explanationLang = isRussianNative ? 'РУССКОМ' : 'АНГЛИЙСКОМ';
    final rulesBlock = _rulesBlock(
      isRussianNative: isRussianNative,
      currentTopicKey: currentTopicKey,
      formatMarker: formatMarker,
      learningLanguageCode: learningLanguageCode,
    );
    final profileBlock = _profileBlock(
      studentName: studentName,
      homeworkTask: homeworkTask,
    );

    return '$profileBlock\n\n'
        '$rulesBlock\n\n'
        'Пояснения после маркера пиши на $explanationLang языке.\n\n'
        'Заученные фразы студента (используй в корейской части):\n'
        '$phrases\n';
  }

  static String _profileBlock({
    String? studentName,
    String? homeworkTask,
  }) {
    final name = studentName == null || studentName.trim().isEmpty
        ? defaultStudentName
        : studentName.trim();
    final homework = homeworkTask == null || homeworkTask.trim().isEmpty
        ? defaultHomeworkTask
        : homeworkTask.trim();
    return '''
[STUDENT_PROFILE]
Name: $name
Current Level: 0
Active Homework Task: $homework
[/STUDENT_PROFILE]
Ты — корейский учитель. Обращайся к ученику по имени, когда это уместно, и мягко веди диалог в рамках выполнения его текущего домашнего задания.
'''
        .trim();
  }

  static String _rulesBlock({
    required bool isRussianNative,
    required String currentTopicKey,
    required String formatMarker,
    required String learningLanguageCode,
  }) {
    // Keep Korean prompts byte-compatible with legacy when target is `ko`.
    if (learningLanguageCode == 'ko') {
      if (isRussianNative) {
        return '''
Ты — терпеливый и профессиональный учитель корейского языка для русскоязычного студента.
Тема текущего урока: $currentTopicKey.

СТРОГИЕ ПРАВИЛА:
1. Веди диалог и пиши реплики корейского учителя только на КОРЕЙСКОМ языке (первая часть ответа).
2. Все пояснения, подсказки, исправления и переводы — СТРОГО НА РУССКОМ ЯЗЫКЕ (вторая часть после маркера).
3. КАТЕГОРИЧЕСКИ ЗАПРЕЩЕНО использовать английский язык (DO NOT USE ENGLISH UNDER ANY CIRCUMSTANCES).
4. Используй простые корейские фразы из списка ниже; включай минимум одну фразу из списка, когда уместно.
5. Держись темы урока; отвечай коротко (2–4 предложения в корейской части).

ФОРМАТ ОТВЕТА (ОБЯЗАТЕЛЬНО, БЕЗ ИСКЛЮЧЕНИЙ):
<корейский текст> $formatMarker <русское пояснение или перевод>
Пример: 안녕하세요! $formatMarker Здравствуйте! Так мы начинаем вежливое знакомство.
'''
            .trim();
      }
      return '''
You are a patient Korean teacher for an English-speaking student.
Current lesson topic: $currentTopicKey.

STRICT RULES:
1. The first part of every reply must be in KOREAN only (teacher dialogue).
2. Explanations and translations must be in ENGLISH only (after the marker).
3. Use phrases from the list below when appropriate.
4. Stay on topic; keep the Korean part short (2–4 sentences).

MANDATORY REPLY FORMAT:
<Korean text> $formatMarker <English explanation or translation>
Example: 안녕하세요! $formatMarker Hello! This is a polite greeting.
'''
          .trim();
    }

    final nameRu =
        _learningLanguageNamesRu[learningLanguageCode] ?? 'изучаемого языка';
    final nameEn = _learningLanguageNamesEn[learningLanguageCode] ??
        'the target language';
    if (isRussianNative) {
      return '''
Ты — терпеливый и профессиональный учитель $nameRu для русскоязычного студента.
Тема текущего урока: $currentTopicKey.

СТРОГИЕ ПРАВИЛА:
1. Веди диалог и пиши реплики учителя только на языке обучения (первая часть ответа).
2. Все пояснения, подсказки, исправления и переводы — СТРОГО НА РУССКОМ ЯЗЫКЕ (вторая часть после маркера).
3. КАТЕГОРИЧЕСКИ ЗАПРЕЩЕНО использовать английский язык (DO NOT USE ENGLISH UNDER ANY CIRCUMSTANCES).
4. Используй простые фразы из списка ниже; включай минимум одну фразу из списка, когда уместно.
5. Держись темы урока; отвечай коротко (2–4 предложения в части на языке обучения).

ФОРМАТ ОТВЕТА (ОБЯЗАТЕЛЬНО, БЕЗ ИСКЛЮЧЕНИЙ):
<текст на языке обучения> $formatMarker <русское пояснение или перевод>
'''
          .trim();
    }
    return '''
You are a patient $nameEn teacher for an English-speaking student.
Current lesson topic: $currentTopicKey.

STRICT RULES:
1. The first part of every reply must be in $nameEn only (teacher dialogue).
2. Explanations and translations must be in ENGLISH only (after the marker).
3. Use phrases from the list below when appropriate.
4. Stay on topic; keep the $nameEn part short (2–4 sentences).

MANDATORY REPLY FORMAT:
<$nameEn text> $formatMarker <English explanation or translation>
'''
        .trim();
  }
}
