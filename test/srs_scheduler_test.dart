import 'package:flutter_test/flutter_test.dart';
import 'package:vilka/domain/progress/phrase_srs.dart';
import 'package:vilka/domain/progress/user_progress.dart';
import 'package:vilka/domain/srs/srs_scheduler.dart';

void main() {
  group('SrsScheduler', () {
    test('initial interval is 1 day from now', () {
      const now = 1_000_000;
      final entry = SrsScheduler.createInitialEntry(
        userId: 'local_user',
        phraseId: 1001,
        nowMillis: now,
      );
      expect(entry.currentIntervalDays, 1);
      expect(entry.timesReviewed, 0);
      expect(entry.nextReviewDate, now + SrsScheduler.millisPerDay);
    });

    test('successful reviews walk 1→3→7→14→21→30 and then stay at 30', () {
      const now = 0;
      var entry = SrsScheduler.createInitialEntry(
        userId: 'local_user',
        phraseId: 1001,
        nowMillis: now,
      );
      const expected = [3, 7, 14, 21, 30, 30];
      for (var i = 0; i < expected.length; i++) {
        entry = SrsScheduler.scheduleAfterReview(entry, nowMillis: now);
        expect(entry.currentIntervalDays, expected[i]);
        expect(entry.timesReviewed, i + 1);
        expect(
          entry.nextReviewDate,
          now + expected[i] * SrsScheduler.millisPerDay,
        );
      }
    });

    test('isMastered after interval 30 and timesReviewed >= 5', () {
      const notYet = PhraseSrs(
        userId: 'local_user',
        phraseId: 1,
        nextReviewDate: 0,
        currentIntervalDays: 30,
        timesReviewed: 4,
      );
      const mastered = PhraseSrs(
        userId: 'local_user',
        phraseId: 1,
        nextReviewDate: 0,
        currentIntervalDays: 30,
        timesReviewed: 5,
      );
      expect(SrsScheduler.isMastered(notYet), isFalse);
      expect(SrsScheduler.isMastered(mastered), isTrue);
    });
  });

  group('UserProgress learnedPhraseIdsJson', () {
    test('encodes and parses integer ids', () {
      const ids = [1001, 2005, 13015];
      final json = UserProgress.encodeLearnedPhraseIds(ids);
      expect(json, '[1001, 2005, 13015]');
      expect(UserProgress.parseLearnedPhraseIds(json), ids);
    });

    test('empty json is an empty list', () {
      expect(UserProgress.parseLearnedPhraseIds('[]'), isEmpty);
      expect(UserProgress.encodeLearnedPhraseIds(const []), '[]');
    });
  });
}
