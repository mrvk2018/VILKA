import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../domain/progress/lesson_progress.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../level/presentation/level_routes.dart';
import '../../settings/presentation/speech_speed_button.dart';
import '../../settings/presentation/speech_speed_notifier.dart';
import 'player_notifier.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key, required this.topicId});

  final int topicId;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  bool _seeking = false;
  double? _seekMs;

  @override
  void initState() {
    super.initState();
    ref.listenManual(phrasesProvider(widget.topicId), (previous, next) {
      final phrases = next.value;
      if (phrases == null || phrases.isEmpty) {
        return;
      }
      ref
          .read(playerProvider(widget.topicId).notifier)
          .initPlayer(widget.topicId, phrases);
    }, fireImmediately: true);
    ref.listenManual(speechSpeedProvider, (previous, next) {
      if (previous == next) {
        return;
      }
      final phrases = ref.read(phrasesProvider(widget.topicId)).value;
      if (phrases == null || phrases.isEmpty) {
        return;
      }
      ref
          .read(playerProvider(widget.topicId).notifier)
          .initPlayer(widget.topicId, phrases);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(uiLocaleProvider);
    final topic = ref.watch(topicProvider(widget.topicId));
    final player = ref.watch(playerProvider(widget.topicId));
    final handler = ref.watch(audioHandlerProvider);
    final title = topic.when(
      data: (item) => item?.titleFor(locale) ?? l10n.playerTitle,
      loading: () => l10n.playerTitle,
      error: (_, _) => l10n.playerTitle,
    );

    ref.listen(examEventsProvider, (previous, next) {
      final progress = next.value;
      if (progress == null) {
        return;
      }
      _maybeShowExamDialog(progress);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: const [SpeechSpeedButton()],
      ),
      body: player.isPreparing
          ? const Center(child: CircularProgressIndicator())
          : player.error != null
              ? Center(child: Text(l10n.loadError))
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 32),
                      Expanded(
                        child: StreamBuilder<MediaItem?>(
                          stream: handler.mediaItem,
                          builder: (context, snapshot) {
                            final korean = snapshot.data?.title ?? '';
                            return Center(
                              child: Text(
                                korean,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            );
                          },
                        ),
                      ),
                      StreamBuilder<MediaItem?>(
                        stream: handler.mediaItem,
                        builder: (context, mediaSnapshot) {
                          final duration =
                              mediaSnapshot.data?.duration ?? Duration.zero;
                          return StreamBuilder<Duration>(
                            stream: AudioService.position,
                            builder: (context, positionSnapshot) {
                              final position =
                                  positionSnapshot.data ?? Duration.zero;
                              return _PositionSlider(
                                position: position,
                                duration: duration,
                                seeking: _seeking,
                                seekMs: _seekMs,
                                onChangeStart: (value) {
                                  setState(() {
                                    _seeking = true;
                                    _seekMs = value;
                                  });
                                },
                                onChanged: (value) {
                                  setState(() => _seekMs = value);
                                },
                                onChangeEnd: (value) async {
                                  await handler.seek(
                                    Duration(milliseconds: value.round()),
                                  );
                                  if (mounted) {
                                    setState(() {
                                      _seeking = false;
                                      _seekMs = null;
                                    });
                                  }
                                },
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<PlaybackState>(
                        stream: handler.playbackState,
                        builder: (context, snapshot) {
                          final playback = snapshot.data;
                          final playing = playback?.playing ?? false;
                          final processing = playback?.processingState;
                          final loading =
                              processing == AudioProcessingState.loading ||
                                  processing == AudioProcessingState.buffering;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (loading)
                                const SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else
                                IconButton(
                                  iconSize: 48,
                                  tooltip: playing
                                      ? l10n.playerPause
                                      : l10n.playerPlay,
                                  onPressed: playing
                                      ? handler.pause
                                      : handler.play,
                                  icon: Icon(
                                    playing
                                        ? Icons.pause_circle
                                        : Icons.play_circle,
                                  ),
                                ),
                              const SizedBox(width: 24),
                              IconButton(
                                iconSize: 40,
                                tooltip: l10n.playerStop,
                                onPressed: handler.stop,
                                icon: const Icon(Icons.stop_circle_outlined),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  Future<void> _maybeShowExamDialog(LessonProgress progress) async {
    if (!progress.examAvailable || progress.lessonId != widget.topicId) {
      return;
    }
    final notifier = ref.read(playerProvider(widget.topicId).notifier);
    if (ref.read(playerProvider(widget.topicId)).examDialogShown) {
      return;
    }
    notifier.markExamDialogShown();
    final handler = ref.read(audioHandlerProvider);
    final wasStopped =
        handler.playbackState.value.processingState == AudioProcessingState.idle;
    if (!wasStopped) {
      await handler.pause();
    }
    if (!mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final goToExam = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.examPromptTitle),
          content: Text(l10n.examPromptBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.examLater),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.examGo),
            ),
          ],
        );
      },
    );
    if (!mounted) {
      return;
    }
    if (goToExam == true) {
      context.push(LevelRoutes.exam(widget.topicId));
      return;
    }
    if (!wasStopped) {
      await handler.play();
    }
  }
}

class _PositionSlider extends StatelessWidget {
  const _PositionSlider({
    required this.position,
    required this.duration,
    required this.seeking,
    required this.seekMs,
    required this.onChangeStart,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final Duration position;
  final Duration duration;
  final bool seeking;
  final double? seekMs;
  final ValueChanged<double> onChangeStart;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final maxMs = duration.inMilliseconds.toDouble();
    final safeMax = maxMs <= 0 ? 1.0 : maxMs;
    final currentMs = seeking
        ? (seekMs ?? position.inMilliseconds.toDouble())
        : position.inMilliseconds.toDouble().clamp(0.0, safeMax).toDouble();
    return Column(
      children: [
        Slider(
          min: 0,
          max: safeMax,
          value: currentMs.clamp(0.0, safeMax).toDouble(),
          onChanged: maxMs <= 0 ? null : onChanged,
          onChangeStart: maxMs <= 0 ? null : onChangeStart,
          onChangeEnd: maxMs <= 0 ? null : onChangeEnd,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_format(position)),
            Text(_format(duration)),
          ],
        ),
      ],
    );
  }

  String _format(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
