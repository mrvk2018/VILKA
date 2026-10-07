import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../domain/exam/exam_trigger_logic.dart';
import '../../domain/progress/learning_sub_stage.dart';
import '../../domain/progress/lesson_progress.dart';
import '../../domain/progress/phrase_srs.dart';
import '../../domain/progress/user_progress.dart';
import '../../domain/srs/srs_scheduler.dart';

class ProgressRepository {
  ProgressRepository(this._db);

  static const userId = 'local_user';

  final AppDatabase _db;

  Future<UserProgress?> getUserProgress() async {
    final db = await _db.database;
    final rows = await db.query(
      'user_progress',
      where: 'userId = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return UserProgress.fromSqlMap(rows.first);
  }

  Future<void> markPhraseLearned({
    required int topicId,
    String? topicKey,
    required int phraseId,
  }) async {
    final existing = await getUserProgress();
    final learned = {...?existing?.learnedPhraseIds, phraseId}.toList()..sort();
    final updated = (existing ?? UserProgress(userId: userId)).copyWith(
      currentTopicId: topicId,
      currentTopicKey: topicKey ?? existing?.currentTopicKey,
      currentSubStage: LearningSubStage.speaking.code,
      learnedPhraseIds: learned,
    );
    await _upsertUserProgress(updated);
    await ensureSrsEntries([phraseId]);
  }

  Future<void> enterLlmDialogStage({
    required int topicId,
    String? topicKey,
  }) async {
    final existing = await getUserProgress();
    final updated = (existing ?? UserProgress(userId: userId)).copyWith(
      currentTopicId: topicId,
      currentTopicKey: topicKey ?? existing?.currentTopicKey,
      currentSubStage: LearningSubStage.llmDialog.code,
    );
    await _upsertUserProgress(updated);
  }

  Future<LessonProgress?> getLessonProgress(int topicId) async {
    final db = await _db.database;
    final rows = await db.query(
      'user_lesson_progress',
      where: 'userId = ? AND lessonId = ?',
      whereArgs: [userId, topicId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return LessonProgress.fromSqlMap(rows.first);
  }

  Future<LessonProgress> recordFullPlaythrough(int topicId) async {
    final current = await getLessonProgress(topicId) ??
        LessonProgress(userId: userId, lessonId: topicId);
    final updated = ExamTriggerLogic.onFullPlaythroughCompleted(current);
    await _upsertLessonProgress(updated);
    return updated;
  }

  Future<LessonProgress> recordStopPressed(int topicId) async {
    final updated = ExamTriggerLogic.onStopPressed(
      await getLessonProgress(topicId),
      userId: userId,
      lessonId: topicId,
    );
    await _upsertLessonProgress(updated);
    return updated;
  }

  Future<void> ensureSrsEntries(List<int> phraseIds) async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final phraseId in phraseIds) {
      final existing = await _getSrs(db, phraseId);
      if (existing != null) {
        continue;
      }
      await db.insert(
        'phrase_srs',
        SrsScheduler.createInitialEntry(
          userId: userId,
          phraseId: phraseId,
          nowMillis: now,
        ).toSqlMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> scheduleSrsAfterReview(int phraseId) async {
    final db = await _db.database;
    final existing = await _getSrs(db, phraseId);
    if (existing == null) {
      return;
    }
    await db.insert(
      'phrase_srs',
      SrsScheduler.scheduleAfterReview(existing).toSqlMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<int>> getDueSrsPhraseIds(int now) async {
    final db = await _db.database;
    final rows = await db.query(
      'phrase_srs',
      columns: ['phraseId'],
      where: 'userId = ? AND nextReviewDate <= ?',
      whereArgs: [userId, now],
      orderBy: 'nextReviewDate ASC',
    );
    return [
      for (final row in rows) row['phraseId'] as int,
    ];
  }

  Future<void> _upsertUserProgress(UserProgress progress) async {
    final db = await _db.database;
    await db.insert(
      'user_progress',
      progress.toSqlMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _upsertLessonProgress(LessonProgress progress) async {
    final db = await _db.database;
    await db.insert(
      'user_lesson_progress',
      progress.toSqlMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<PhraseSrs?> _getSrs(Database db, int phraseId) async {
    final rows = await db.query(
      'phrase_srs',
      where: 'userId = ? AND phraseId = ?',
      whereArgs: [userId, phraseId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return PhraseSrs.fromSqlMap(rows.first);
  }
}
