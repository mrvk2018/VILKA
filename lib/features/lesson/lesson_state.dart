import '../../domain/course/phrase.dart';
import '../../domain/course/topic.dart';
import '../../domain/llm/llm_chat_message.dart';

class LessonState {
  const LessonState({
    this.phrase,
    this.topic,
    this.inputText = '',
    this.messages = const [],
    this.assistantReply = '',
    this.isLlmLoading = false,
    this.isListening = false,
    this.isPhraseLoading = true,
    this.errorBanner,
  });

  final Phrase? phrase;
  final Topic? topic;
  final String inputText;
  final List<LlmChatMessage> messages;
  final String assistantReply;
  final bool isLlmLoading;
  final bool isListening;
  final bool isPhraseLoading;
  final String? errorBanner;

  LessonState copyWith({
    Phrase? phrase,
    Topic? topic,
    String? inputText,
    List<LlmChatMessage>? messages,
    String? assistantReply,
    bool? isLlmLoading,
    bool? isListening,
    bool? isPhraseLoading,
    String? errorBanner,
    bool clearError = false,
  }) {
    return LessonState(
      phrase: phrase ?? this.phrase,
      topic: topic ?? this.topic,
      inputText: inputText ?? this.inputText,
      messages: messages ?? this.messages,
      assistantReply: assistantReply ?? this.assistantReply,
      isLlmLoading: isLlmLoading ?? this.isLlmLoading,
      isListening: isListening ?? this.isListening,
      isPhraseLoading: isPhraseLoading ?? this.isPhraseLoading,
      errorBanner: clearError ? null : (errorBanner ?? this.errorBanner),
    );
  }
}
