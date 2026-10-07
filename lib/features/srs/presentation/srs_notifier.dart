import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../domain/course/phrase.dart';

class SrsState {
  const SrsState({
    this.isLoading = true,
    this.error,
    this.duePhrases = const [],
    this.currentIndex = 0,
    this.isRevealed = false,
  });

  final bool isLoading;
  final String? error;
  final List<Phrase> duePhrases;
  final int currentIndex;
  final bool isRevealed;

  bool get isFinished => !isLoading && currentIndex >= duePhrases.length;

  Phrase? get currentPhrase {
    if (currentIndex < 0 || currentIndex >= duePhrases.length) {
      return null;
    }
    return duePhrases[currentIndex];
  }

  SrsState copyWith({
    bool? isLoading,
    String? error,
    List<Phrase>? duePhrases,
    int? currentIndex,
    bool? isRevealed,
    bool clearError = false,
  }) {
    return SrsState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      duePhrases: duePhrases ?? this.duePhrases,
      currentIndex: currentIndex ?? this.currentIndex,
      isRevealed: isRevealed ?? this.isRevealed,
    );
  }
}

class SrsNotifier extends Notifier<SrsState> {
  @override
  SrsState build() {
    ref.onDispose(() {
      unawaited(ref.read(ttsEngineProvider).stop());
      ref.invalidate(dueSrsCountProvider);
    });
    Future<void>.microtask(_load);
    return const SrsState();
  }

  Future<void> _load() async {
    state = const SrsState(isLoading: true);
    try {
      final progress = ref.read(progressRepositoryProvider);
      final course = ref.read(courseRepositoryProvider);
      final language = ref.read(learningLanguageProvider);
      final allPhrases = await course.getPhrasesByLanguage(language: language);
      await progress.ensureSrsEntries([
        for (final phrase in allPhrases) phrase.id,
      ]);
      final dueIds = await progress.getDueSrsPhraseIds(
        DateTime.now().millisecondsSinceEpoch,
      );
      final duePhrases = await course.getPhrasesByIds(dueIds);
      if (!ref.mounted) {
        return;
      }
      state = SrsState(isLoading: false, duePhrases: duePhrases);
    } catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = SrsState(isLoading: false, error: error.toString());
    }
  }

  void reveal() {
    if (state.currentPhrase == null || state.isRevealed) {
      return;
    }
    state = state.copyWith(isRevealed: true);
  }

  Future<void> markCorrect(int phraseId) async {
    if (state.currentPhrase?.id != phraseId || !state.isRevealed) {
      return;
    }
    await ref.read(progressRepositoryProvider).scheduleSrsAfterReview(phraseId);
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
      isRevealed: false,
    );
  }

  /// Legacy-style fail: keep DB interval, requeue the card at the end of this session.
  void markWrong() {
    final phrase = state.currentPhrase;
    if (phrase == null || !state.isRevealed) {
      return;
    }
    state = state.copyWith(
      duePhrases: [...state.duePhrases, phrase],
      currentIndex: state.currentIndex + 1,
      isRevealed: false,
    );
  }
}

final srsProvider = NotifierProvider.autoDispose<SrsNotifier, SrsState>(
  SrsNotifier.new,
);

final dueSrsCountProvider = FutureProvider<int>((ref) async {
  final progress = ref.watch(progressRepositoryProvider);
  final course = ref.watch(courseRepositoryProvider);
  final language = ref.watch(learningLanguageProvider);
  final phrases = await course.getPhrasesByLanguage(language: language);
  await progress.ensureSrsEntries([
    for (final phrase in phrases) phrase.id,
  ]);
  final ids = await progress.getDueSrsPhraseIds(
    DateTime.now().millisecondsSinceEpoch,
  );
  return ids.length;
});
