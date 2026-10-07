import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../level/presentation/level_routes.dart';
import 'exam_notifier.dart';

class ExamScreen extends ConsumerStatefulWidget {
  const ExamScreen({super.key, required this.topicId});

  final int topicId;

  @override
  ConsumerState<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends ConsumerState<ExamScreen> {
  Timer? _advanceTimer;

  @override
  void dispose() {
    _advanceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final exam = ref.watch(examProvider(widget.topicId));
    final notifier = ref.read(examProvider(widget.topicId).notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.examTitle)),
      body: exam.isLoading
          ? const Center(child: CircularProgressIndicator())
          : exam.accessDenied
              ? Center(child: Text(l10n.examAccessDenied))
              : exam.error != null
                  ? Center(child: Text(l10n.loadError))
                  : exam.finished
                      ? _ExamResult(
                          score: exam.score,
                          passed: exam.passed,
                          onBackToTopics: () => context.go(LevelRoutes.topics),
                          onRetake: notifier.retake,
                        )
                      : _ExamQuestionCard(
                          exam: exam,
                          onSelect: (index) => _onSelect(notifier, index),
                        ),
    );
  }

  void _onSelect(ExamNotifier notifier, int index) {
    final exam = ref.read(examProvider(widget.topicId));
    if (exam.revealed || exam.finished) {
      return;
    }
    notifier.answerQuestion(index);
    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) {
        return;
      }
      ref.read(examProvider(widget.topicId).notifier).advance();
    });
  }
}

class _ExamQuestionCard extends StatelessWidget {
  const _ExamQuestionCard({
    required this.exam,
    required this.onSelect,
  });

  final ExamState exam;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final question = exam.currentQuestion;
    if (question == null) {
      return Center(child: Text(l10n.loadError));
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.examProgress(exam.currentIndex + 1, exam.questions.length),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                question.koreanText,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          const SizedBox(height: 24),
          for (var i = 0; i < question.options.length; i++) ...[
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: _optionColor(context, i, question.correctIndex),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              ),
              onPressed: exam.revealed ? null : () => onSelect(i),
              child: Text(
                question.options[i],
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Color? _optionColor(BuildContext context, int index, int correctIndex) {
    if (!exam.revealed) {
      return null;
    }
    if (index == correctIndex) {
      return Colors.green.shade200;
    }
    if (index == exam.selectedIndex) {
      return Colors.red.shade200;
    }
    return null;
  }
}

class _ExamResult extends StatelessWidget {
  const _ExamResult({
    required this.score,
    required this.passed,
    required this.onBackToTopics,
    required this.onRetake,
  });

  final int score;
  final bool passed;
  final VoidCallback onBackToTopics;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            passed ? l10n.examPassed : l10n.examFailed,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.examScoreLabel(score),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 32),
          if (passed)
            FilledButton(
              onPressed: onBackToTopics,
              child: Text(l10n.examBackToTopics),
            )
          else
            FilledButton(
              onPressed: onRetake,
              child: Text(l10n.examRetry),
            ),
        ],
      ),
    );
  }
}
