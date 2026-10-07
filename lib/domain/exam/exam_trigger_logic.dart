import '../progress/lesson_progress.dart';

/// Port of legacy `ExamTriggerLogic`. Used by progress writes, not UI yet.
class ExamTriggerLogic {
  static LessonProgress onFullPlaythroughCompleted(LessonProgress progress) {
    return progress.copyWith(
      timesCompletedFullPlaythrough: progress.timesCompletedFullPlaythrough + 1,
      examAvailable: true,
    );
  }

  static LessonProgress onStopPressed(
    LessonProgress? progress, {
    required String userId,
    required int lessonId,
    int? timestamp,
  }) {
    final now = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    final base = progress ??
        LessonProgress(userId: userId, lessonId: lessonId);
    return base.copyWith(
      userId: userId,
      lessonId: lessonId,
      lastStopPressedAt: now,
      examAvailable: base.timesCompletedFullPlaythrough >= 1,
    );
  }
}
