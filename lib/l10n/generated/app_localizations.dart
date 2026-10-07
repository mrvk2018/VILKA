import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'Vilka'**
  String get appTitle;

  /// No description provided for @homeSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Фонетическое погружение'**
  String get homeSubtitle;

  /// No description provided for @learningLanguageLabel.
  ///
  /// In ru, this message translates to:
  /// **'Язык обучения'**
  String get learningLanguageLabel;

  /// No description provided for @korean.
  ///
  /// In ru, this message translates to:
  /// **'Корейский'**
  String get korean;

  /// No description provided for @openTopics.
  ///
  /// In ru, this message translates to:
  /// **'Темы курса'**
  String get openTopics;

  /// No description provided for @topicsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Темы'**
  String get topicsTitle;

  /// No description provided for @phrasesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Фразы'**
  String get phrasesTitle;

  /// No description provided for @topicCount.
  ///
  /// In ru, this message translates to:
  /// **'{count} тем'**
  String topicCount(int count);

  /// No description provided for @phraseCount.
  ///
  /// In ru, this message translates to:
  /// **'{count} фраз'**
  String phraseCount(int count);

  /// No description provided for @emptyTopics.
  ///
  /// In ru, this message translates to:
  /// **'Темы ещё не загружены'**
  String get emptyTopics;

  /// No description provided for @emptyPhrases.
  ///
  /// In ru, this message translates to:
  /// **'В этой теме нет фраз'**
  String get emptyPhrases;

  /// No description provided for @loadError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить данные'**
  String get loadError;

  /// No description provided for @microphonePermissionDenied.
  ///
  /// In ru, this message translates to:
  /// **'Без микрофона голосовой ввод будет недоступен. Разрешение можно включить в настройках.'**
  String get microphonePermissionDenied;

  /// No description provided for @openAppSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get openAppSettings;

  /// No description provided for @lessonTitle.
  ///
  /// In ru, this message translates to:
  /// **'Урок'**
  String get lessonTitle;

  /// No description provided for @listenPhrase.
  ///
  /// In ru, this message translates to:
  /// **'Послушать фразу'**
  String get listenPhrase;

  /// No description provided for @speakButton.
  ///
  /// In ru, this message translates to:
  /// **'Говорить'**
  String get speakButton;

  /// No description provided for @stopSpeaking.
  ///
  /// In ru, this message translates to:
  /// **'Стоп'**
  String get stopSpeaking;

  /// No description provided for @sendMessage.
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get sendMessage;

  /// No description provided for @lessonInputHint.
  ///
  /// In ru, this message translates to:
  /// **'Напишите или скажите фразу учителю'**
  String get lessonInputHint;

  /// No description provided for @lessonEmptyDialog.
  ///
  /// In ru, this message translates to:
  /// **'Начните диалог с учителем'**
  String get lessonEmptyDialog;

  /// No description provided for @dismissError.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть'**
  String get dismissError;

  /// No description provided for @playTopic.
  ///
  /// In ru, this message translates to:
  /// **'Слушать тему'**
  String get playTopic;

  /// No description provided for @playerTitle.
  ///
  /// In ru, this message translates to:
  /// **'Плеер'**
  String get playerTitle;

  /// No description provided for @playerPlay.
  ///
  /// In ru, this message translates to:
  /// **'Играть'**
  String get playerPlay;

  /// No description provided for @playerPause.
  ///
  /// In ru, this message translates to:
  /// **'Пауза'**
  String get playerPause;

  /// No description provided for @playerStop.
  ///
  /// In ru, this message translates to:
  /// **'Стоп'**
  String get playerStop;

  /// No description provided for @examPromptTitle.
  ///
  /// In ru, this message translates to:
  /// **'Экзамен доступен'**
  String get examPromptTitle;

  /// No description provided for @examPromptBody.
  ///
  /// In ru, this message translates to:
  /// **'Тема прослушана. Сдать экзамен сейчас?'**
  String get examPromptBody;

  /// No description provided for @examLater.
  ///
  /// In ru, this message translates to:
  /// **'Позже'**
  String get examLater;

  /// No description provided for @examGo.
  ///
  /// In ru, this message translates to:
  /// **'К экзамену'**
  String get examGo;

  /// No description provided for @examStubMessage.
  ///
  /// In ru, this message translates to:
  /// **'Экран экзамена появится в следующем шаге'**
  String get examStubMessage;

  /// No description provided for @examTitle.
  ///
  /// In ru, this message translates to:
  /// **'Экзамен'**
  String get examTitle;

  /// No description provided for @examAccessDenied.
  ///
  /// In ru, this message translates to:
  /// **'Сначала полностью прослушайте тему или нажмите Стоп после прохода.'**
  String get examAccessDenied;

  /// No description provided for @examProgress.
  ///
  /// In ru, this message translates to:
  /// **'{current} / {total}'**
  String examProgress(int current, int total);

  /// No description provided for @examPassed.
  ///
  /// In ru, this message translates to:
  /// **'Экзамен сдан'**
  String get examPassed;

  /// No description provided for @examFailed.
  ///
  /// In ru, this message translates to:
  /// **'Экзамен не сдан'**
  String get examFailed;

  /// No description provided for @examScoreLabel.
  ///
  /// In ru, this message translates to:
  /// **'{score}%'**
  String examScoreLabel(int score);

  /// No description provided for @examBackToTopics.
  ///
  /// In ru, this message translates to:
  /// **'Назад к темам'**
  String get examBackToTopics;

  /// No description provided for @examRetry.
  ///
  /// In ru, this message translates to:
  /// **'Пересдать'**
  String get examRetry;

  /// No description provided for @srsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Повторение'**
  String get srsTitle;

  /// No description provided for @srsHomeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Интервальное повторение'**
  String get srsHomeTitle;

  /// No description provided for @srsAllDone.
  ///
  /// In ru, this message translates to:
  /// **'На сегодня всё повторено'**
  String get srsAllDone;

  /// No description provided for @srsDueCount.
  ///
  /// In ru, this message translates to:
  /// **'Доступно фраз для повторения: {count}'**
  String srsDueCount(int count);

  /// No description provided for @srsStart.
  ///
  /// In ru, this message translates to:
  /// **'Начать повторение'**
  String get srsStart;

  /// No description provided for @srsShowTranslation.
  ///
  /// In ru, this message translates to:
  /// **'Показать перевод'**
  String get srsShowTranslation;

  /// No description provided for @srsRemember.
  ///
  /// In ru, this message translates to:
  /// **'Помню'**
  String get srsRemember;

  /// No description provided for @srsForgot.
  ///
  /// In ru, this message translates to:
  /// **'Забыл'**
  String get srsForgot;

  /// No description provided for @srsFinished.
  ///
  /// In ru, this message translates to:
  /// **'Все фразы повторены!'**
  String get srsFinished;

  /// No description provided for @srsBack.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get srsBack;

  /// No description provided for @srsProgress.
  ///
  /// In ru, this message translates to:
  /// **'{current} / {total}'**
  String srsProgress(int current, int total);

  /// No description provided for @hangulLearnBanner.
  ///
  /// In ru, this message translates to:
  /// **'Изучить хангыль'**
  String get hangulLearnBanner;

  /// No description provided for @hangulAlphabetTitle.
  ///
  /// In ru, this message translates to:
  /// **'Алфавит Хангыль'**
  String get hangulAlphabetTitle;

  /// No description provided for @hangulAlphabetSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите на букву, чтобы услышать произношение. Иконка карандаша — тренировка письма.'**
  String get hangulAlphabetSubtitle;

  /// No description provided for @hangulSectionConsonants.
  ///
  /// In ru, this message translates to:
  /// **'Согласные'**
  String get hangulSectionConsonants;

  /// No description provided for @hangulSectionVowels.
  ///
  /// In ru, this message translates to:
  /// **'Гласные'**
  String get hangulSectionVowels;

  /// No description provided for @hangulPracticeLetter.
  ///
  /// In ru, this message translates to:
  /// **'Практика письма'**
  String get hangulPracticeLetter;

  /// No description provided for @hangulDrawingTitle.
  ///
  /// In ru, this message translates to:
  /// **'Напиши букву: {letter}'**
  String hangulDrawingTitle(String letter);

  /// No description provided for @hangulDrawingInstruction.
  ///
  /// In ru, this message translates to:
  /// **'Проведите пальцем по экрану, повторяя форму буквы.'**
  String get hangulDrawingInstruction;

  /// No description provided for @hangulClearCanvas.
  ///
  /// In ru, this message translates to:
  /// **'Очистить'**
  String get hangulClearCanvas;

  /// No description provided for @hangulPlayLetter.
  ///
  /// In ru, this message translates to:
  /// **'Прослушать букву'**
  String get hangulPlayLetter;

  /// No description provided for @speechSpeedTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Скорость речи'**
  String get speechSpeedTooltip;

  /// No description provided for @levelsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Уровни'**
  String get levelsTitle;

  /// No description provided for @levelName.
  ///
  /// In ru, this message translates to:
  /// **'Уровень {number}'**
  String levelName(int number);

  /// No description provided for @level0Subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Текущий курс'**
  String get level0Subtitle;

  /// No description provided for @levelLockedSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Скоро'**
  String get levelLockedSubtitle;

  /// No description provided for @levelLockedSnackbar.
  ///
  /// In ru, this message translates to:
  /// **'Этот уровень станет доступен в следующих обновлениях'**
  String get levelLockedSnackbar;

  /// No description provided for @welcomeHeadline.
  ///
  /// In ru, this message translates to:
  /// **'Добро пожаловать'**
  String get welcomeHeadline;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы сохранить профиль ученика и домашние задания.'**
  String get welcomeSubtitle;

  /// No description provided for @signInWithGoogle.
  ///
  /// In ru, this message translates to:
  /// **'Войти через Google'**
  String get signInWithGoogle;

  /// No description provided for @signInWithApple.
  ///
  /// In ru, this message translates to:
  /// **'Войти через Apple'**
  String get signInWithApple;

  /// No description provided for @signInError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось войти. Попробуйте ещё раз.'**
  String get signInError;

  /// No description provided for @homeGreeting.
  ///
  /// In ru, this message translates to:
  /// **'Привет, {name}!'**
  String homeGreeting(String name);

  /// No description provided for @homeLogout.
  ///
  /// In ru, this message translates to:
  /// **'Выход'**
  String get homeLogout;

  /// No description provided for @homeHomeworkTitle.
  ///
  /// In ru, this message translates to:
  /// **'Ваше домашнее задание'**
  String get homeHomeworkTitle;

  /// No description provided for @homeHomeworkFallback.
  ///
  /// In ru, this message translates to:
  /// **'Пройти первый аудиоурок и ознакомиться с фразами'**
  String get homeHomeworkFallback;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
