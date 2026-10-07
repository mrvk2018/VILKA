// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Vilka';

  @override
  String get homeSubtitle => 'Phonetic immersion';

  @override
  String get learningLanguageLabel => 'Learning language';

  @override
  String get korean => 'Korean';

  @override
  String get openTopics => 'Course topics';

  @override
  String get topicsTitle => 'Topics';

  @override
  String get phrasesTitle => 'Phrases';

  @override
  String topicCount(int count) {
    return '$count topics';
  }

  @override
  String phraseCount(int count) {
    return '$count phrases';
  }

  @override
  String get emptyTopics => 'Topics are not loaded yet';

  @override
  String get emptyPhrases => 'No phrases in this topic';

  @override
  String get loadError => 'Failed to load data';

  @override
  String get microphonePermissionDenied =>
      'Without microphone access, voice input will be unavailable. You can enable it in Settings.';

  @override
  String get openAppSettings => 'Settings';

  @override
  String get lessonTitle => 'Lesson';

  @override
  String get listenPhrase => 'Listen to phrase';

  @override
  String get speakButton => 'Speak';

  @override
  String get stopSpeaking => 'Stop';

  @override
  String get sendMessage => 'Send';

  @override
  String get lessonInputHint => 'Type or say a phrase to the teacher';

  @override
  String get lessonEmptyDialog => 'Start a dialogue with the teacher';

  @override
  String get dismissError => 'Dismiss';

  @override
  String get playTopic => 'Play topic';

  @override
  String get playerTitle => 'Player';

  @override
  String get playerPlay => 'Play';

  @override
  String get playerPause => 'Pause';

  @override
  String get playerStop => 'Stop';

  @override
  String get examPromptTitle => 'Exam available';

  @override
  String get examPromptBody => 'You finished this topic. Take the exam now?';

  @override
  String get examLater => 'Later';

  @override
  String get examGo => 'Take exam';

  @override
  String get examStubMessage => 'The exam screen will be added in a later step';

  @override
  String get examTitle => 'Exam';

  @override
  String get examAccessDenied =>
      'Finish a full playthrough of the topic, or press Stop after one complete pass.';

  @override
  String examProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get examPassed => 'Exam passed';

  @override
  String get examFailed => 'Exam not passed';

  @override
  String examScoreLabel(int score) {
    return '$score%';
  }

  @override
  String get examBackToTopics => 'Back to topics';

  @override
  String get examRetry => 'Retry';

  @override
  String get srsTitle => 'Review';

  @override
  String get srsHomeTitle => 'Spaced repetition';

  @override
  String get srsAllDone => 'You\'re all caught up for today';

  @override
  String srsDueCount(int count) {
    return 'Phrases due for review: $count';
  }

  @override
  String get srsStart => 'Start review';

  @override
  String get srsShowTranslation => 'Show translation';

  @override
  String get srsRemember => 'Remembered';

  @override
  String get srsForgot => 'Forgot';

  @override
  String get srsFinished => 'All phrases reviewed!';

  @override
  String get srsBack => 'Back';

  @override
  String srsProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get hangulLearnBanner => 'Learn Hangul';

  @override
  String get hangulAlphabetTitle => 'Hangul alphabet';

  @override
  String get hangulAlphabetSubtitle =>
      'Tap a letter to hear it. Use the pencil icon to practice writing.';

  @override
  String get hangulSectionConsonants => 'Consonants';

  @override
  String get hangulSectionVowels => 'Vowels';

  @override
  String get hangulPracticeLetter => 'Writing practice';

  @override
  String hangulDrawingTitle(String letter) {
    return 'Write the letter: $letter';
  }

  @override
  String get hangulDrawingInstruction =>
      'Draw on the screen with your finger, following the letter shape.';

  @override
  String get hangulClearCanvas => 'Clear';

  @override
  String get hangulPlayLetter => 'Play letter sound';

  @override
  String get speechSpeedTooltip => 'Speech speed';

  @override
  String get levelsTitle => 'Levels';

  @override
  String levelName(int number) {
    return 'Level $number';
  }

  @override
  String get level0Subtitle => 'Current course';

  @override
  String get levelLockedSubtitle => 'Coming soon';

  @override
  String get levelLockedSnackbar =>
      'This level will become available in future updates';

  @override
  String get welcomeHeadline => 'Welcome';

  @override
  String get welcomeSubtitle =>
      'Sign in to save your student profile and homework.';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signInWithApple => 'Sign in with Apple';

  @override
  String get signInError => 'Could not sign in. Please try again.';

  @override
  String homeGreeting(String name) {
    return 'Hi, $name!';
  }

  @override
  String get homeLogout => 'Log out';

  @override
  String get homeHomeworkTitle => 'Your homework';

  @override
  String get homeHomeworkFallback =>
      'Complete the first audio lesson and review the phrases';
}
