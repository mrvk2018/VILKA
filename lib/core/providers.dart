import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/course/course_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/progress_repository.dart';
import '../features/player/data/lesson_audio_handler.dart';
import 'audio/stt_repository.dart';
import 'audio/tts_engine.dart';
import 'database/app_database.dart';
import 'learning_language.dart';
import 'permissions/permission_service.dart';
import 'ui_locale.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepository(ref.watch(appDatabaseProvider));
});

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepository(ref.watch(appDatabaseProvider));
});

/// Overridden in `main()` after `AudioService.init`.
final audioHandlerProvider = Provider<LessonAudioHandler>((ref) {
  throw StateError('audioHandlerProvider must be overridden in main()');
});

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

final ttsEngineProvider = Provider<TtsEngine>((ref) {
  final engine = FlutterTtsEngine();
  ref.onDispose(engine.dispose);
  return engine;
});

final sttRepositoryProvider = Provider<SttRepository>((ref) {
  final repository = SpeechToTextRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

class UiLocaleNotifier extends Notifier<UiLocale> {
  @override
  UiLocale build() => UiLocale.ru;

  void toggle() {
    state = state == UiLocale.ru ? UiLocale.en : UiLocale.ru;
  }
}

final uiLocaleProvider = NotifierProvider<UiLocaleNotifier, UiLocale>(
  UiLocaleNotifier.new,
);

class LearningLanguageNotifier extends Notifier<LearningLanguage> {
  @override
  LearningLanguage build() => LearningLanguage.ko;
}

final learningLanguageProvider =
    NotifierProvider<LearningLanguageNotifier, LearningLanguage>(
  LearningLanguageNotifier.new,
);

final topicsProvider = FutureProvider((ref) {
  final language = ref.watch(learningLanguageProvider);
  return ref.watch(courseRepositoryProvider).getTopics(language: language);
});

final topicProvider = FutureProvider.family((ref, int topicId) {
  return ref.watch(courseRepositoryProvider).getTopic(topicId);
});

final phrasesProvider = FutureProvider.family((ref, int topicId) {
  return ref.watch(courseRepositoryProvider).getPhrases(topicId);
});

final userProfileProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) {
  return ref.watch(profileRepositoryProvider).getCachedProfile();
});
