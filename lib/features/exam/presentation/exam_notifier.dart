import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/repositories/exam_repository.dart';
import '../../../domain/exam/exam_question_builder.dart';

class ExamAnswerRecord {
  const ExamAnswerRecord({
    required this.phraseId,
    required this.selectedIndex,
    required this.correctIndex,
    required this.correct,
  });

  final int phraseId;
  final int selectedIndex;
  final int correctIndex;
  final bool correct;

  Map<String, Object?> toJson() {
    return {
      'phraseId': phraseId,
      'selectedIndex': selectedIndex,
      'correctIndex': correctIndex,
      'correct': correct,
    };
  }
}

class ExamState {
  const ExamState({
    this.isLoading = true,
    this.accessDenied = false,
    this.error,
    this.questions = const [],
    this.currentIndex = 0,
    this.correctCount = 0,
    this.selectedIndex,
    this.revealed = false,
    this.finished = false,
    this.score = 0,
    this.answers = const [],
  });

  final bool isLoading;
  final bool accessDenied;
  final String? error;
  final List<ExamQuestion> questions;
  final int currentIndex;
  final int correctCount;
  final int? selectedIndex;
  final bool revealed;
  final bool finished;
  final int score;
  final List<ExamAnswerRecord> answers;

  bool get passed => score >= ExamRepository.passScore;

  ExamQuestion? get currentQuestion {
    if (currentIndex < 0 || currentIndex >= questions.length) {
      return null;
    }
    return questions[currentIndex];
  }

  ExamState copyWith({
    bool? isLoading,
    bool? accessDenied,
    String? error,
    List<ExamQuestion>? questions,
    int? currentIndex,
    int? correctCount,
    int? selectedIndex,
    bool? revealed,
    bool? finished,
    int? score,
    List<ExamAnswerRecord>? answers,
    bool clearSelection = false,
    bool clearError = false,
  }) {
    return ExamState(
      isLoading: isLoading ?? this.isLoading,
      accessDenied: accessDenied ?? this.accessDenied,
      error: clearError ? null : error ?? this.error,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      correctCount: correctCount ?? this.correctCount,
      selectedIndex:
          clearSelection ? null : selectedIndex ?? this.selectedIndex,
      revealed: revealed ?? this.revealed,
      finished: finished ?? this.finished,
      score: score ?? this.score,
      answers: answers ?? this.answers,
    );
  }
}

class ExamNotifier extends Notifier<ExamState> {
  ExamNotifier(this.topicId);

  final int topicId;

  @override
  ExamState build() {
    Future<void>.microtask(_load);
    return const ExamState();
  }

  Future<void> _load() async {
    state = const ExamState(isLoading: true);
    final progress =
        await ref.read(progressRepositoryProvider).getLessonProgress(topicId);
    if (!ref.mounted) {
      return;
    }
    if (progress == null || !progress.examAvailable) {
      state = const ExamState(isLoading: false, accessDenied: true);
      return;
    }
    try {
      final course = ref.read(courseRepositoryProvider);
      final language = ref.read(learningLanguageProvider);
      final locale = ref.read(uiLocaleProvider);
      final topicPhrases = await course.getPhrases(topicId);
      final coursePhrases = await course.getPhrasesByLanguage(language: language);
      if (!ref.mounted) {
        return;
      }
      final questions = ExamQuestionBuilder().build(
        topicPhrases: topicPhrases,
        coursePhrases: coursePhrases,
        locale: locale,
      );
      if (questions.isEmpty) {
        state = const ExamState(
          isLoading: false,
          error: 'empty_exam',
        );
        return;
      }
      state = ExamState(isLoading: false, questions: questions);
    } catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = ExamState(isLoading: false, error: error.toString());
    }
  }

  Future<void> retake() => _load();

  void answerQuestion(int selectedIndex) {
    final question = state.currentQuestion;
    if (question == null || state.revealed || state.finished) {
      return;
    }
    final correct = selectedIndex == question.correctIndex;
    final answer = ExamAnswerRecord(
      phraseId: question.phraseId,
      selectedIndex: selectedIndex,
      correctIndex: question.correctIndex,
      correct: correct,
    );
    state = state.copyWith(
      selectedIndex: selectedIndex,
      revealed: true,
      correctCount: correct ? state.correctCount + 1 : state.correctCount,
      answers: [...state.answers, answer],
    );
  }

  Future<void> advance() async {
    if (!state.revealed || state.finished) {
      return;
    }
    final isLast = state.currentIndex >= state.questions.length - 1;
    if (!isLast) {
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        revealed: false,
        clearSelection: true,
      );
      return;
    }
    final total = state.questions.length;
    final score = total == 0 ? 0 : ((state.correctCount * 100) / total).round();
    await ref.read(examRepositoryProvider).saveAttempt(
          topicId: topicId,
          score: score,
          answersJson: jsonEncode(
            [for (final answer in state.answers) answer.toJson()],
          ),
        );
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(finished: true, score: score);
  }
}

final examProvider =
    NotifierProvider.autoDispose.family<ExamNotifier, ExamState, int>(
  ExamNotifier.new,
);
