import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../../data/repositories/progress_repository.dart';
import '../../../domain/course/phrase.dart';
import '../../../domain/llm/llm_teacher_reply_parser.dart';
import '../../../domain/progress/lesson_progress.dart';
import 'tts_file_cache.dart';

/// Background lesson player. Owns [AudioPlayer] and writes exam triggers.
class LessonAudioHandler extends BaseAudioHandler {
  LessonAudioHandler(
    this._progressRepository, {
    TtsFileCache? ttsCache,
  }) : _ttsCache = ttsCache ?? TtsFileCache() {
    _player.playbackEventStream.listen(_broadcastState);
    _player.processingStateStream.listen(_onProcessingState);
  }

  final ProgressRepository _progressRepository;
  final TtsFileCache _ttsCache;
  final AudioPlayer _player = AudioPlayer();
  final StreamController<LessonProgress> _examEvents =
      StreamController<LessonProgress>.broadcast();

  int? _currentTopicId;
  bool _sessionActive = false;
  bool _handlingCompleted = false;
  int _introSourceCount = 0;
  MediaItem? _introMediaItem;
  List<MediaItem> _phraseMediaItems = const [];
  double _speedCoefficient = 1.0;
  double _loadedFileSpeed = 1.0;
  double _appliedPlayerSpeed = 1.0;

  int? get currentTopicId => _currentTopicId;

  /// Progress rows written by playthrough/stop. Lives with the singleton handler.
  Stream<LessonProgress> get examEvents => _examEvents.stream;

  bool get hasLoadedQueue => queue.value.isNotEmpty;

  double get loadedSpeedCoefficient => _loadedFileSpeed;

  /// Binds progress writes to [topicId] until the next attach or process death.
  void attachTopic(int topicId) {
    _currentTopicId = topicId;
    _sessionActive = true;
    _handlingCompleted = false;
  }

  /// Updates JustAudio speed. Intro stays at 1.0x; Korean follows [coefficient].
  Future<void> setSpeechSpeed(double coefficient) async {
    _speedCoefficient = coefficient;
    _ttsCache.speedCoefficient = coefficient;
    await _applyPlaybackSpeed();
  }

  /// Prefetches TTS files and loads `[intro, phrase, silence, phrase, silence, ...]`.
  Future<void> loadTopicQueue(
    int topicId,
    List<Phrase> phrases, {
    double? speedCoefficient,
  }) async {
    if (speedCoefficient != null) {
      _speedCoefficient = speedCoefficient;
    }
    _ttsCache.speedCoefficient = _speedCoefficient;
    _loadedFileSpeed = _speedCoefficient;
    attachTopic(topicId);
    await _ttsCache.ensureInitialized();
    await _player.setSkipSilenceEnabled(false);
    final introPath = await _ttsCache.prepareIntroFile();
    final phrasePaths = await _ttsCache.prepareTopicFiles(phrases);
    final mediaItems = _mediaItemsForPreparedPhrases(
      topicId: topicId,
      phrases: phrases,
      preparedPathCount: phrasePaths.length,
    );
    final introItem = introPath == null
        ? null
        : MediaItem(
            id: 'intro',
            title: TtsFileCache.introText,
            album: 'Vilka',
            extras: {'topicId': topicId, 'isIntro': true},
          );
    _introMediaItem = introItem;
    _introSourceCount = introPath == null ? 0 : 1;
    _phraseMediaItems = mediaItems;
    queue.add([
      ?introItem,
      ...mediaItems,
    ]);
    if (mediaItems.isEmpty) {
      _introMediaItem = null;
      _introSourceCount = 0;
      mediaItem.add(null);
      await _player.stop();
      return;
    }
    mediaItem.add(introItem ?? mediaItems.first);

    final silencePath = _ttsCache.silenceFilePath;
    final sources = <AudioSource>[];
    if (introPath != null && introItem != null) {
      sources.add(AudioSource.file(introPath, tag: introItem));
    }
    for (var i = 0; i < phrasePaths.length; i++) {
      sources.add(AudioSource.file(phrasePaths[i], tag: mediaItems[i]));
      sources.add(AudioSource.file(silencePath));
    }

    // ignore: deprecated_member_use
    final playlist = ConcatenatingAudioSource(children: sources);
    await _player.setAudioSource(playlist);
    _appliedPlayerSpeed = -1;
    await _player.setSpeed(_speedCoefficient);
    await _applyPlaybackSpeed();
  }

  Future<void> _applyPlaybackSpeed() async {
    final onIntro = _introSourceCount > 0 &&
        (_player.currentIndex ?? 0) < _introSourceCount;
    final baked = _loadedFileSpeed == 0 ? 1.0 : _loadedFileSpeed;
    final koreanSpeed = _speedCoefficient / baked;
    final target = onIntro ? 1.0 : koreanSpeed;
    if ((target - _appliedPlayerSpeed).abs() < 0.001) {
      return;
    }
    _appliedPlayerSpeed = target;
    await _player.setSpeed(target);
  }

  @override
  Future<void> play() {
    if (_currentTopicId != null) {
      _sessionActive = true;
    }
    return _player.play();
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    final topicId = _currentTopicId;
    if (_sessionActive && topicId != null) {
      _sessionActive = false;
      final progress = await _progressRepository.recordStopPressed(topicId);
      _emitExam(progress);
    }
    await _player.stop();
    await super.stop();
  }

  void _onProcessingState(ProcessingState state) {
    if (state != ProcessingState.completed) {
      return;
    }
    unawaited(_onQueueCompleted());
  }

  Future<void> _onQueueCompleted() async {
    if (_handlingCompleted || !_sessionActive) {
      return;
    }
    final topicId = _currentTopicId;
    if (topicId == null) {
      return;
    }
    _handlingCompleted = true;
    try {
      final progress = await _progressRepository.recordFullPlaythrough(topicId);
      _emitExam(progress);
      await _player.seek(Duration.zero);
      await _player.play();
    } finally {
      _handlingCompleted = false;
    }
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    final phraseIndex = _maskedPhraseIndex(event.currentIndex);
    _publishPhraseMediaItem(phraseIndex);
    unawaited(_applyPlaybackSpeed());
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
        ],
        androidCompactActionIndices: const [0, 1],
        systemActions: const {MediaAction.seek},
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: phraseIndex,
      ),
    );
  }

  /// Player indices: optional intro, then even = phrase, odd = silence.
  int? _maskedPhraseIndex(int? playerIndex) {
    if (playerIndex == null || _phraseMediaItems.isEmpty) {
      return null;
    }
    final shifted = playerIndex - _introSourceCount;
    if (shifted < 0) {
      return null;
    }
    final index = shifted ~/ 2;
    if (index < 0) {
      return 0;
    }
    if (index >= _phraseMediaItems.length) {
      return _phraseMediaItems.length - 1;
    }
    return index;
  }

  void _publishPhraseMediaItem(int? phraseIndex) {
    if (phraseIndex == null) {
      final intro = _introMediaItem;
      if (intro != null &&
          _introSourceCount > 0 &&
          (_player.currentIndex ?? 0) < _introSourceCount) {
        _setMediaItem(intro);
      }
      return;
    }
    if (phraseIndex >= _phraseMediaItems.length) {
      return;
    }
    final item = _phraseMediaItems[phraseIndex];
    final duration = _player.duration;
    final next = duration == null ? item : item.copyWith(duration: duration);
    _setMediaItem(next);
  }

  void _setMediaItem(MediaItem next) {
    final current = mediaItem.value;
    if (current?.id == next.id && current?.duration == next.duration) {
      return;
    }
    mediaItem.add(next);
  }

  void _emitExam(LessonProgress progress) {
    if (_examEvents.isClosed) {
      return;
    }
    _examEvents.add(progress);
  }

  List<MediaItem> _mediaItemsForPreparedPhrases({
    required int topicId,
    required List<Phrase> phrases,
    required int preparedPathCount,
  }) {
    final items = <MediaItem>[];
    for (final phrase in phrases) {
      if (items.length >= preparedPathCount) {
        break;
      }
      final text = LlmTeacherReplyParser.sanitizeForKoreanTts(phrase.koreanText);
      if (text.isEmpty) {
        continue;
      }
      items.add(
        MediaItem(
          id: '${phrase.id}',
          title: phrase.koreanText,
          album: 'Vilka',
          extras: {
            'topicId': topicId,
            'phraseId': phrase.id,
          },
        ),
      );
    }
    return items;
  }
}
