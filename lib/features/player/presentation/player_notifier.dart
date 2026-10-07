import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../domain/course/phrase.dart';
import '../../../domain/progress/lesson_progress.dart';
import '../../settings/presentation/speech_speed_notifier.dart';

class PlayerState {
  const PlayerState({
    required this.topicId,
    this.isPreparing = false,
    this.error,
    this.examDialogShown = false,
  });

  final int topicId;
  final bool isPreparing;
  final String? error;
  final bool examDialogShown;

  PlayerState copyWith({
    int? topicId,
    bool? isPreparing,
    String? error,
    bool? examDialogShown,
    bool clearError = false,
  }) {
    return PlayerState(
      topicId: topicId ?? this.topicId,
      isPreparing: isPreparing ?? this.isPreparing,
      error: clearError ? null : error ?? this.error,
      examDialogShown: examDialogShown ?? this.examDialogShown,
    );
  }
}

class PlayerNotifier extends Notifier<PlayerState> {
  PlayerNotifier(this.topicId);

  final int topicId;

  @override
  PlayerState build() {
    return PlayerState(topicId: topicId);
  }

  /// Loads TTS queue only when this topic is not already on the handler.
  Future<void> initPlayer(int topicId, List<Phrase> phrases) async {
    if (state.isPreparing) {
      return;
    }
    final handler = ref.read(audioHandlerProvider);
    final speed = ref.read(speechSpeedProvider);
    final alreadyLoaded = handler.currentTopicId == topicId &&
        handler.hasLoadedQueue &&
        (handler.loadedSpeedCoefficient - speed).abs() < 0.001;
    if (alreadyLoaded) {
      await handler.setSpeechSpeed(speed);
      state = state.copyWith(
        topicId: topicId,
        isPreparing: false,
        clearError: true,
      );
      return;
    }
    state = state.copyWith(
      topicId: topicId,
      isPreparing: true,
      clearError: true,
    );
    try {
      await handler.loadTopicQueue(
        topicId,
        phrases,
        speedCoefficient: speed,
      );
      await handler.play();
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(isPreparing: false);
    } catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        isPreparing: false,
        error: error.toString(),
      );
    }
  }

  void markExamDialogShown() {
    state = state.copyWith(examDialogShown: true);
  }
}

final playerProvider =
    NotifierProvider.autoDispose.family<PlayerNotifier, PlayerState, int>(
  PlayerNotifier.new,
);

final examEventsProvider = StreamProvider.autoDispose<LessonProgress>((ref) {
  return ref.watch(audioHandlerProvider).examEvents;
});
