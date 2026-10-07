import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../core/providers.dart';

class ExamRepository {
  ExamRepository(this._db);

  static const userId = 'local_user';
  static const passScore = 80;

  final AppDatabase _db;

  Future<int> saveAttempt({
    required int topicId,
    required int score,
    required String answersJson,
  }) async {
    final db = await _db.database;
    final attemptNumber = await countAttempts(topicId) + 1;
    return db.insert(
      'exam_attempts',
      {
        'userId': userId,
        'lessonId': topicId,
        'attemptNumber': attemptNumber,
        'score': score,
        'date': DateTime.now().millisecondsSinceEpoch,
        'answersJson': answersJson,
      },
    );
  }

  Future<int> countAttempts(int topicId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM exam_attempts '
      'WHERE userId = ? AND lessonId = ?',
      [userId, topicId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<bool> hasPassedTopic(int topicId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT MAX(score) AS s FROM exam_attempts '
      'WHERE userId = ? AND lessonId = ?',
      [userId, topicId],
    );
    final maxScore = Sqflite.firstIntValue(result);
    return maxScore != null && maxScore >= passScore;
  }
}

final examRepositoryProvider = Provider<ExamRepository>((ref) {
  return ExamRepository(ref.watch(appDatabaseProvider));
});
