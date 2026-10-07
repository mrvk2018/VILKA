import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../domain/course/phrase.dart';
import '../../l10n/generated/app_localizations.dart';
import '../level/presentation/level_routes.dart';
import '../player/data/lesson_audio_handler.dart';
import '../settings/presentation/speech_speed_button.dart';
import '../settings/presentation/speech_speed_notifier.dart';

class PhrasesScreen extends ConsumerStatefulWidget {
  const PhrasesScreen({super.key, required this.topicId});

  final int topicId;

  @override
  ConsumerState<PhrasesScreen> createState() => _PhrasesScreenState();
}

class _PhrasesScreenState extends ConsumerState<PhrasesScreen> {
  static const _idleCardColor = Color(0xFFEDE7F6);
  static const _activeCardColor = Color(0xFFE8F5E9);

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(speechSpeedProvider, (previous, next) {
      if (previous == next) {
        return;
      }
      final handler = ref.read(audioHandlerProvider);
      if (handler.currentTopicId != widget.topicId || !handler.hasLoadedQueue) {
        return;
      }
      final items = ref.read(phrasesProvider(widget.topicId)).value;
      if (items == null || items.isEmpty) {
        return;
      }
      unawaited(
        handler.loadTopicQueue(
          widget.topicId,
          items,
          speedCoefficient: next,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(uiLocaleProvider);
    final topic = ref.watch(topicProvider(widget.topicId));
    final phrases = ref.watch(phrasesProvider(widget.topicId));
    final handler = ref.watch(audioHandlerProvider);

    return StreamBuilder<PlaybackState>(
      stream: handler.playbackState,
      builder: (context, playbackSnapshot) {
        return StreamBuilder<MediaItem?>(
          stream: handler.mediaItem,
          builder: (context, mediaSnapshot) {
            final playingThisTopic = _isPlayingThisTopic(
              handler,
              playbackSnapshot.data,
            );
            final activePhraseId = _activePhraseId(
              playingThisTopic: playingThisTopic,
              item: mediaSnapshot.data,
            );

            return Scaffold(
              appBar: AppBar(
                title: Text(
                  topic.when(
                    data: (item) =>
                        item?.titleFor(locale) ?? l10n.phrasesTitle,
                    loading: () => l10n.phrasesTitle,
                    error: (_, _) => l10n.phrasesTitle,
                  ),
                ),
                actions: [
                  const SpeechSpeedButton(),
                  phrases.maybeWhen(
                    data: (items) {
                      if (items.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return IconButton(
                        tooltip: playingThisTopic
                            ? l10n.playerStop
                            : l10n.playTopic,
                        onPressed: _busy
                            ? null
                            : () => _onPlayStopPressed(
                                  items,
                                  playingThisTopic,
                                ),
                        icon: Icon(
                          playingThisTopic
                              ? Icons.stop
                              : Icons.play_circle_outline,
                        ),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
              floatingActionButton: phrases.maybeWhen(
                data: (items) {
                  if (items.isEmpty) {
                    return null;
                  }
                  return FloatingActionButton(
                    tooltip: playingThisTopic
                        ? l10n.playerStop
                        : l10n.playTopic,
                    onPressed: _busy
                        ? null
                        : () => _onPlayStopPressed(items, playingThisTopic),
                    child: _busy
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            playingThisTopic ? Icons.stop : Icons.play_arrow,
                          ),
                  );
                },
                orElse: () => null,
              ),
              body: phrases.when(
                data: (items) {
                  if (items.isEmpty) {
                    return Center(child: Text(l10n.emptyPhrases));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final phrase = items[index];
                      final isActive = activePhraseId == phrase.id;
                      return Card(
                        color: isActive ? _activeCardColor : _idleCardColor,
                        elevation: 0,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isActive
                                ? const Color(0xFFC8E6C9)
                                : const Color(0xFFD1C4E9),
                            child: Text(
                              '${phrase.order}',
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                          title: Text(
                            phrase.learningText,
                            style: const TextStyle(color: Colors.black),
                          ),
                          subtitle: Text(
                            phrase.translationFor(locale),
                            style: const TextStyle(color: Colors.black87),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.black54,
                          ),
                          onTap: () => context.push(
                            LevelRoutes.lesson(widget.topicId, phrase.id),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(l10n.loadError)),
              ),
            );
          },
        );
      },
    );
  }

  bool _isPlayingThisTopic(
    LessonAudioHandler handler,
    PlaybackState? playback,
  ) {
    return (playback?.playing ?? false) &&
        handler.currentTopicId == widget.topicId;
  }

  int? _activePhraseId({
    required bool playingThisTopic,
    required MediaItem? item,
  }) {
    if (!playingThisTopic || item == null) {
      return null;
    }
    if (item.extras?['isIntro'] == true) {
      return null;
    }
    final extraId = item.extras?['phraseId'];
    if (extraId is int) {
      return extraId;
    }
    return int.tryParse(item.id);
  }

  Future<void> _onPlayStopPressed(
    List<Phrase> items,
    bool playingThisTopic,
  ) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    final handler = ref.read(audioHandlerProvider);
    try {
      if (playingThisTopic) {
        await handler.stop();
        return;
      }
      final speed = ref.read(speechSpeedProvider);
      if (handler.currentTopicId == widget.topicId &&
          handler.hasLoadedQueue &&
          (handler.loadedSpeedCoefficient - speed).abs() < 0.001) {
        await handler.play();
        return;
      }
      await handler.loadTopicQueue(
        widget.topicId,
        items,
        speedCoefficient: speed,
      );
      await handler.play();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}
