import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../domain/llm/llm_chat_message.dart';
import '../../l10n/generated/app_localizations.dart';
import '../settings/presentation/speech_speed_button.dart';
import 'lesson_args.dart';
import 'lesson_notifier.dart';

class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({
    super.key,
    required this.topicId,
    required this.phraseId,
  });

  final int topicId;
  final int phraseId;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _inputController;
  late final LessonArgs _args;

  @override
  void initState() {
    super.initState();
    _args = LessonArgs(topicId: widget.topicId, phraseId: widget.phraseId);
    _inputController = TextEditingController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inputController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      ref.read(lessonProvider(_args).notifier).stopAudioSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(uiLocaleProvider);
    final lesson = ref.watch(lessonProvider(_args));
    final notifier = ref.read(lessonProvider(_args).notifier);

    ref.listen(lessonProvider(_args).select((value) => value.inputText), (
      previous,
      next,
    ) {
      if (_inputController.text != next) {
        _inputController.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      }
    });

    final phrase = lesson.phrase;
    final title = lesson.topic?.titleFor(locale) ?? l10n.lessonTitle;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: const [SpeechSpeedButton()],
      ),
      body: lesson.isPhraseLoading
          ? const Center(child: CircularProgressIndicator())
          : phrase == null
              ? Center(child: Text(l10n.loadError))
              : Column(
                  children: [
                    if (lesson.isLlmLoading) const LinearProgressIndicator(),
                    if (lesson.errorBanner != null)
                      MaterialBanner(
                        content: Text(_errorText(l10n, lesson.errorBanner!)),
                        actions: [
                          TextButton(
                            onPressed: notifier.clearError,
                            child: Text(l10n.dismissError),
                          ),
                        ],
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                phrase.learningText,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(phrase.translationFor(locale)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: lesson.isLlmLoading
                                  ? null
                                  : notifier.speakCurrentPhrase,
                              icon: const Icon(Icons.volume_up),
                              label: Text(l10n.listenPhrase),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: lesson.isLlmLoading
                                  ? null
                                  : notifier.toggleListening,
                              icon: Icon(
                                lesson.isListening ? Icons.stop : Icons.mic,
                              ),
                              label: Text(
                                lesson.isListening
                                    ? l10n.stopSpeaking
                                    : l10n.speakButton,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: lesson.messages.isEmpty
                          ? Center(child: Text(l10n.lessonEmptyDialog))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: lesson.messages.length,
                              itemBuilder: (context, index) {
                                final message = lesson.messages[index];
                                final isUser = message is LlmUserMessage;
                                final text = switch (message) {
                                  LlmUserMessage(:final text) => text,
                                  LlmTeacherMessage(:final text) => text,
                                };
                                return Align(
                                  alignment: isUser
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.sizeOf(context).width *
                                              0.8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isUser
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primaryContainer
                                          : Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(text),
                                  ),
                                );
                              },
                            ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _inputController,
                                enabled: !lesson.isLlmLoading,
                                minLines: 1,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: l10n.lessonInputHint,
                                  border: const OutlineInputBorder(),
                                ),
                                onChanged: notifier.updateInput,
                                onSubmitted: (_) => notifier.sendMessage(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: lesson.isLlmLoading
                                  ? null
                                  : notifier.sendMessage,
                              icon: const Icon(Icons.send),
                              tooltip: l10n.sendMessage,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  String _errorText(AppLocalizations l10n, String code) {
    return switch (code) {
      'microphone_denied' => l10n.microphonePermissionDenied,
      'phrase_not_found' => l10n.loadError,
      _ => code,
    };
  }
}
