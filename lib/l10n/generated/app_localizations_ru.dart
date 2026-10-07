// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Vilka';

  @override
  String get homeSubtitle => 'Фонетическое погружение';

  @override
  String get learningLanguageLabel => 'Язык обучения';

  @override
  String get korean => 'Корейский';

  @override
  String get openTopics => 'Темы курса';

  @override
  String get topicsTitle => 'Темы';

  @override
  String get phrasesTitle => 'Фразы';

  @override
  String topicCount(int count) {
    return '$count тем';
  }

  @override
  String phraseCount(int count) {
    return '$count фраз';
  }

  @override
  String get emptyTopics => 'Темы ещё не загружены';

  @override
  String get emptyPhrases => 'В этой теме нет фраз';

  @override
  String get loadError => 'Не удалось загрузить данные';

  @override
  String get microphonePermissionDenied =>
      'Без микрофона голосовой ввод будет недоступен. Разрешение можно включить в настройках.';

  @override
  String get openAppSettings => 'Настройки';

  @override
  String get lessonTitle => 'Урок';

  @override
  String get listenPhrase => 'Послушать фразу';

  @override
  String get speakButton => 'Говорить';

  @override
  String get stopSpeaking => 'Стоп';

  @override
  String get sendMessage => 'Отправить';

  @override
  String get lessonInputHint => 'Напишите или скажите фразу учителю';

  @override
  String get lessonEmptyDialog => 'Начните диалог с учителем';

  @override
  String get dismissError => 'Скрыть';

  @override
  String get playTopic => 'Слушать тему';

  @override
  String get playerTitle => 'Плеер';

  @override
  String get playerPlay => 'Играть';

  @override
  String get playerPause => 'Пауза';

  @override
  String get playerStop => 'Стоп';

  @override
  String get examPromptTitle => 'Экзамен доступен';

  @override
  String get examPromptBody => 'Тема прослушана. Сдать экзамен сейчас?';

  @override
  String get examLater => 'Позже';

  @override
  String get examGo => 'К экзамену';

  @override
  String get examStubMessage => 'Экран экзамена появится в следующем шаге';

  @override
  String get examTitle => 'Экзамен';

  @override
  String get examAccessDenied =>
      'Сначала полностью прослушайте тему или нажмите Стоп после прохода.';

  @override
  String examProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get examPassed => 'Экзамен сдан';

  @override
  String get examFailed => 'Экзамен не сдан';

  @override
  String examScoreLabel(int score) {
    return '$score%';
  }

  @override
  String get examBackToTopics => 'Назад к темам';

  @override
  String get examRetry => 'Пересдать';

  @override
  String get srsTitle => 'Повторение';

  @override
  String get srsHomeTitle => 'Интервальное повторение';

  @override
  String get srsAllDone => 'На сегодня всё повторено';

  @override
  String srsDueCount(int count) {
    return 'Доступно фраз для повторения: $count';
  }

  @override
  String get srsStart => 'Начать повторение';

  @override
  String get srsShowTranslation => 'Показать перевод';

  @override
  String get srsRemember => 'Помню';

  @override
  String get srsForgot => 'Забыл';

  @override
  String get srsFinished => 'Все фразы повторены!';

  @override
  String get srsBack => 'Назад';

  @override
  String srsProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get hangulLearnBanner => 'Изучить хангыль';

  @override
  String get hangulAlphabetTitle => 'Алфавит Хангыль';

  @override
  String get hangulAlphabetSubtitle =>
      'Нажмите на букву, чтобы услышать произношение. Иконка карандаша — тренировка письма.';

  @override
  String get hangulSectionConsonants => 'Согласные';

  @override
  String get hangulSectionVowels => 'Гласные';

  @override
  String get hangulPracticeLetter => 'Практика письма';

  @override
  String hangulDrawingTitle(String letter) {
    return 'Напиши букву: $letter';
  }

  @override
  String get hangulDrawingInstruction =>
      'Проведите пальцем по экрану, повторяя форму буквы.';

  @override
  String get hangulClearCanvas => 'Очистить';

  @override
  String get hangulPlayLetter => 'Прослушать букву';

  @override
  String get speechSpeedTooltip => 'Скорость речи';

  @override
  String get levelsTitle => 'Уровни';

  @override
  String levelName(int number) {
    return 'Уровень $number';
  }

  @override
  String get level0Subtitle => 'Текущий курс';

  @override
  String get levelLockedSubtitle => 'Скоро';

  @override
  String get levelLockedSnackbar =>
      'Этот уровень станет доступен в следующих обновлениях';

  @override
  String get welcomeHeadline => 'Добро пожаловать';

  @override
  String get welcomeSubtitle =>
      'Войдите, чтобы сохранить профиль ученика и домашние задания.';

  @override
  String get signInWithGoogle => 'Войти через Google';

  @override
  String get signInWithApple => 'Войти через Apple';

  @override
  String get signInError => 'Не удалось войти. Попробуйте ещё раз.';

  @override
  String homeGreeting(String name) {
    return 'Привет, $name!';
  }

  @override
  String get homeLogout => 'Выход';

  @override
  String get homeHomeworkTitle => 'Ваше домашнее задание';

  @override
  String get homeHomeworkFallback =>
      'Пройти первый аудиоурок и ознакомиться с фразами';
}
