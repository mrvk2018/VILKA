import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/audio/stt_repository.dart';
import '../../core/config/app_config.dart';
import '../../core/providers.dart';
import '../../data/repositories/llm_chat_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/course/phrase.dart';
import '../../domain/llm/llm_chat_message.dart';
import '../../domain/llm/llm_teacher_reply_parser.dart';
import '../../domain/llm/teacher_prompt_generator.dart';
import '../settings/presentation/speech_speed_notifier.dart';
import 'lesson_args.dart';
import 'lesson_state.dart';

final lessonLlmRepositoryProvider =
    Provider.autoDispose.family<LlmChatRepository, LessonArgs>((ref, args) {
  final client = http.Client();
  ref.onDispose(client.close);
  return OpenRouterLlmChatRepository(httpClient: client);
});

class LessonNotifier extends Notifier<LessonState> {
  LessonNotifier(this.args);

  final LessonArgs args;
  StreamSubscription<SttState>? _sttSubscription;

  /// Successful turns only, used as OpenRouter context. Isolated per lesson.
  final List<LlmChatMessage> _apiHistory = [];

  @override
  LessonState build() {
    ref.watch(lessonLlmRepositoryProvider(args));
    ref.onDispose(() {
      unawaited(_sttSubscription?.cancel());
      unawaited(ref.read(ttsEngineProvider).stop());
      unawaited(ref.read(sttRepositoryProvider).stop());
      _apiHistory.clear();
    });
    unawaited(_sttSubscription?.cancel());
    _sttSubscription = ref.read(sttRepositoryProvider).state.listen((stt) {
      state = state.copyWith(
        isListening: stt.status == SttStatus.listening,
        errorBanner: stt.status == SttStatus.error ? stt.message : null,
        clearError: stt.status != SttStatus.error,
      );
    });
    Future<void>.microtask(_load);
    return const LessonState();
  }

  Future<void> _load() async {
    final course = ref.read(courseRepositoryProvider);
    _apiHistory.clear();
    final topic = await course.getTopic(args.topicId);
    final phrases = await course.getPhrases(args.topicId);
    if (!ref.mounted) {
      return;
    }
    Phrase? phrase;
    for (final item in phrases) {
      if (item.id == args.phraseId) {
        phrase = item;
        break;
      }
    }
    if (phrase != null && topic != null) {
      await ref.read(progressRepositoryProvider).enterLlmDialogStage(
        topicId: args.topicId,
        topicKey: topic.key,
      );
    }
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(
      topic: topic,
      phrase: phrase,
      isPhraseLoading: false,
      errorBanner: phrase == null ? 'phrase_not_found' : null,
    );
  }

  void updateInput(String text) {
    state = state.copyWith(inputText: text, clearError: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> stopAudioSession() async {
    await ref.read(sttRepositoryProvider).stop();
    await ref.read(ttsEngineProvider).stop();
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(isListening: false);
  }

  Future<void> speakCurrentPhrase() async {
    final phrase = state.phrase;
    if (phrase == null || state.isLlmLoading) {
      return;
    }
    await ref.read(sttRepositoryProvider).stop();
    await ref.read(ttsEngineProvider).speakKorean(
          phrase.koreanText,
          speedCoefficient: ref.read(speechSpeedProvider),
        );
  }

  Future<void> toggleListening() async {
    if (state.isLlmLoading) {
      return;
    }
    final stt = ref.read(sttRepositoryProvider);
    if (state.isListening) {
      await stt.stop();
      return;
    }
    final permissions = await ref.read(permissionServiceProvider).status();
    if (!permissions.canUseStt) {
      state = state.copyWith(errorBanner: 'microphone_denied');
      return;
    }
    await ref.read(ttsEngineProvider).stop();
    await stt.listen(
      onResult: (text) {
        final merged = '${state.inputText} $text'.trim();
        state = state.copyWith(inputText: merged, isListening: false);
      },
    );
  }

  Future<void> sendMessage() async {
    final text = state.inputText.trim();
    final phrase = state.phrase;
    final topic = state.topic;
    if (text.isEmpty || phrase == null || topic == null || state.isLlmLoading) {
      return;
    }

    await ref.read(sttRepositoryProvider).stop();

    final locale = ref.read(uiLocaleProvider);
    final learningLanguage = ref.read(learningLanguageProvider);
    final cachedProfile =
        await ref.read(profileRepositoryProvider).getCachedProfile();
    if (!ref.mounted) {
      return;
    }
    final studentName = cachedProfile?['name'] as String?;
    final homeworkTask = cachedProfile?['homework_task'] as String?;
    final systemPrompt = TeacherPromptGenerator.generateWithProfile(
      nativeLanguage: locale.code,
      currentTopicKey: topic.key,
      learnedPhrases: [phrase.koreanText],
      learningLanguageCode: learningLanguage.code,
      studentName: studentName,
      homeworkTask: homeworkTask,
    );

    state = state.copyWith(
      messages: [...state.messages, LlmUserMessage(text)],
      inputText: '',
      isLlmLoading: true,
      clearError: true,
    );

    final historyWindow = _apiHistory.length <=
            OpenRouterLlmChatRepository.historyWindowSize
        ? List<LlmChatMessage>.from(_apiHistory)
        : _apiHistory.sublist(
            _apiHistory.length - OpenRouterLlmChatRepository.historyWindowSize,
          );

    final result = await ref.read(lessonLlmRepositoryProvider(args)).sendUserMessage(
          userMessage: text,
          systemPrompt: systemPrompt,
          history: historyWindow,
        );
    if (!ref.mounted) {
      return;
    }

    switch (result) {
      case LlmChatFailure(:final message):
        state = state.copyWith(
          messages: _withoutTrailingUserMessage(state.messages),
          inputText: text,
          isLlmLoading: false,
          errorBanner: message,
        );
      case LlmChatSuccess(:final assistantMessage):
        final parsed = LlmTeacherReplyParser.parse(
          assistantMessage,
          locale.code,
        );
        final speechText =
            LlmTeacherReplyParser.sanitizeForKoreanTts(parsed.koreanPart);
        if (AppConfig.debugLlmLogging) {
          developer.log(
            'rawLen=${assistantMessage.length} '
            'koreanPart=${parsed.koreanPart.length} '
            'speechText=${speechText.length}',
            name: 'LessonNotifier',
          );
        }
        _apiHistory.add(LlmUserMessage(text));
        _apiHistory.add(LlmTeacherMessage(assistantMessage));
        _trimApiHistory();
        state = state.copyWith(
          messages: [...state.messages, LlmTeacherMessage(parsed.displayText)],
          assistantReply: parsed.displayText,
          isLlmLoading: false,
        );
        if (speechText.isNotEmpty) {
          await ref.read(ttsEngineProvider).speakKorean(
                parsed.koreanPart,
                speedCoefficient: ref.read(speechSpeedProvider),
              );
        }
    }
  }

  List<LlmChatMessage> _withoutTrailingUserMessage(
    List<LlmChatMessage> messages,
  ) {
    if (messages.isEmpty || messages.last is! LlmUserMessage) {
      return messages;
    }
    return messages.sublist(0, messages.length - 1);
  }

  void _trimApiHistory() {
    const max = OpenRouterLlmChatRepository.historyWindowSize;
    if (_apiHistory.length <= max) {
      return;
    }
    _apiHistory.removeRange(0, _apiHistory.length - max);
  }
}

final lessonProvider =
    NotifierProvider.autoDispose.family<LessonNotifier, LessonState, LessonArgs>(
  LessonNotifier.new,
);
