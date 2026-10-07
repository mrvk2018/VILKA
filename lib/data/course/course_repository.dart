import '../../core/database/app_database.dart';
import '../../core/learning_language.dart';
import '../../domain/course/phrase.dart';
import '../../domain/course/topic.dart';

class CourseRepository {
  CourseRepository(this._db);

  final AppDatabase _db;

  Future<List<Topic>> getTopics({
    LearningLanguage language = LearningLanguage.ko,
  }) async {
    final rows = await _db.topicsByLanguage(language.code);
    return rows.map(_toTopic).toList();
  }

  Future<Topic?> getTopic(int id) async {
    final row = await _db.topicById(id);
    return row == null ? null : _toTopic(row);
  }

  Future<List<Phrase>> getPhrases(int topicId) async {
    final rows = await _db.phrasesByTopic(topicId);
    return rows.map(_toPhrase).toList();
  }

  Future<List<Phrase>> getPhrasesByLanguage({
    LearningLanguage language = LearningLanguage.ko,
  }) async {
    final rows = await _db.phrasesByLanguage(language.code);
    return rows.map(_toPhrase).toList();
  }

  Future<List<Phrase>> getPhrasesByIds(List<int> ids) async {
    final rows = await _db.phrasesByIds(ids);
    final byId = {for (final row in rows) row.id: _toPhrase(row)};
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }

  Topic _toTopic(TopicRow row) {
    return Topic(
      id: row.id,
      key: row.key,
      titleRu: row.titleRu,
      titleEn: row.titleEn,
      order: row.orderIndex,
      learningLanguageCode: row.learningLanguageCode,
    );
  }

  Phrase _toPhrase(PhraseRow row) {
    return Phrase(
      id: row.id,
      topicId: row.topicId,
      koreanText: row.koreanText,
      russianTranslation: row.russianTranslation,
      englishTranslation: row.englishTranslation,
      audioUrlOrPath: row.audioUrlOrPath,
      order: row.orderIndex,
      learningLanguageCode: row.learningLanguageCode,
    );
  }
}
