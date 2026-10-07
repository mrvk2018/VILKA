import '../progress/phrase_srs.dart';

/// Fixed-interval SRS. Port of legacy `SrsScheduler` (not full SM-2).
class SrsScheduler {
  static const intervalsDays = [1, 3, 7, 14, 21, 30];
  static const masteredIntervalDays = 30;
  static const millisPerDay = 86400000;

  static PhraseSrs createInitialEntry({
    required String userId,
    required int phraseId,
    int? nowMillis,
  }) {
    final now = nowMillis ?? DateTime.now().millisecondsSinceEpoch;
    return PhraseSrs(
      userId: userId,
      phraseId: phraseId,
      currentIntervalDays: intervalsDays.first,
      timesReviewed: 0,
      nextReviewDate: now + daysToMillis(intervalsDays.first),
    );
  }

  static PhraseSrs scheduleAfterReview(
    PhraseSrs existing, {
    int? nowMillis,
  }) {
    final now = nowMillis ?? DateTime.now().millisecondsSinceEpoch;
    final found = intervalsDays.indexOf(existing.currentIntervalDays);
    final nextIndex = (found + 1).clamp(0, intervalsDays.length - 1);
    final nextInterval = intervalsDays[nextIndex];
    return existing.copyWith(
      nextReviewDate: now + daysToMillis(nextInterval),
      currentIntervalDays: nextInterval,
      timesReviewed: existing.timesReviewed + 1,
    );
  }

  static bool isMastered(PhraseSrs entry) {
    return entry.currentIntervalDays >= masteredIntervalDays &&
        entry.timesReviewed >= intervalsDays.length - 1;
  }

  static int daysToMillis(int days) => days * millisPerDay;
}
