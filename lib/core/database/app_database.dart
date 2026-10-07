import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class TopicRow {
  const TopicRow({
    required this.id,
    required this.key,
    required this.titleRu,
    required this.titleEn,
    required this.orderIndex,
    required this.learningLanguageCode,
  });

  final int id;
  final String key;
  final String titleRu;
  final String titleEn;
  final int orderIndex;
  final String learningLanguageCode;

  factory TopicRow.fromMap(Map<String, Object?> map) {
    return TopicRow(
      id: map['id'] as int,
      key: map['key'] as String,
      titleRu: map['title_ru'] as String,
      titleEn: map['title_en'] as String,
      orderIndex: map['order_index'] as int,
      learningLanguageCode: map['learning_language_code'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'key': key,
      'title_ru': titleRu,
      'title_en': titleEn,
      'order_index': orderIndex,
      'learning_language_code': learningLanguageCode,
    };
  }
}

class PhraseRow {
  const PhraseRow({
    required this.id,
    required this.topicId,
    required this.koreanText,
    required this.russianTranslation,
    required this.englishTranslation,
    required this.audioUrlOrPath,
    required this.orderIndex,
    required this.learningLanguageCode,
  });

  final int id;
  final int topicId;
  final String koreanText;
  final String russianTranslation;
  final String englishTranslation;
  final String audioUrlOrPath;
  final int orderIndex;
  final String learningLanguageCode;

  factory PhraseRow.fromMap(Map<String, Object?> map) {
    return PhraseRow(
      id: map['id'] as int,
      topicId: map['topic_id'] as int,
      koreanText: map['korean_text'] as String,
      russianTranslation: map['russian_translation'] as String,
      englishTranslation: map['english_translation'] as String,
      audioUrlOrPath: map['audio_url_or_path'] as String? ?? '',
      orderIndex: map['order_index'] as int,
      learningLanguageCode: map['learning_language_code'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'topic_id': topicId,
      'korean_text': koreanText,
      'russian_translation': russianTranslation,
      'english_translation': englishTranslation,
      'audio_url_or_path': audioUrlOrPath,
      'order_index': orderIndex,
      'learning_language_code': learningLanguageCode,
    };
  }
}

/// Local course DB. Same columns as legacy Room `course_topics` / `course_phrases`.
/// sqflite is used because drift_dev does not resolve on Flutter 3.38 (SDK-pinned meta).
class AppDatabase {
  AppDatabase({Database? forTesting}) : _testDb = forTesting;

  final Database? _testDb;
  Database? _db;

  Future<Database> get database async {
    final testDb = _testDb;
    if (testDb != null) {
      return testDb;
    }
    return _db ??= await _open();
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    return openDatabase(
      p.join(dir.path, 'vilka.sqlite'),
      version: 3,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE course_topics (
            id INTEGER PRIMARY KEY,
            key TEXT NOT NULL,
            title_ru TEXT NOT NULL,
            title_en TEXT NOT NULL,
            order_index INTEGER NOT NULL,
            learning_language_code TEXT NOT NULL DEFAULT 'ko'
          )
        ''');
        await db.execute('''
          CREATE TABLE course_phrases (
            id INTEGER PRIMARY KEY,
            topic_id INTEGER NOT NULL,
            korean_text TEXT NOT NULL,
            russian_translation TEXT NOT NULL,
            english_translation TEXT NOT NULL,
            audio_url_or_path TEXT NOT NULL DEFAULT '',
            order_index INTEGER NOT NULL,
            learning_language_code TEXT NOT NULL DEFAULT 'ko',
            FOREIGN KEY (topic_id) REFERENCES course_topics (id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE content_meta (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_phrases_topic ON course_phrases(topic_id)',
        );
        await _createProgressTables(db);
        await _createUserProfileTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createProgressTables(db);
        }
        if (oldVersion < 3) {
          await _createUserProfileTable(db);
        }
      },
    );
  }

  /// Room-compatible progress tables. Shared by onCreate (fresh) and onUpgrade (v1→v2).
  /// `lessonId` is stored as in Android; in Flutter it maps to `course_topics.id`
  /// until a dedicated lessons table exists. No FK to `lessons` for that reason.
  Future<void> _createProgressTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_progress (
        userId TEXT PRIMARY KEY,
        currentTopicId INTEGER,
        currentTopicKey TEXT,
        currentSubStage INTEGER NOT NULL DEFAULT 1,
        learnedPhraseIdsJson TEXT NOT NULL DEFAULT '[]'
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_lesson_progress (
        userId TEXT NOT NULL,
        lessonId INTEGER NOT NULL,
        timesCompletedFullPlaythrough INTEGER NOT NULL DEFAULT 0,
        lastStopPressedAt INTEGER,
        examAvailable INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (userId, lessonId)
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS index_user_lesson_progress_lessonId '
      'ON user_lesson_progress(lessonId)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS phrase_srs (
        userId TEXT NOT NULL,
        phraseId INTEGER NOT NULL,
        nextReviewDate INTEGER NOT NULL,
        currentIntervalDays INTEGER NOT NULL,
        timesReviewed INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (userId, phraseId),
        FOREIGN KEY (phraseId) REFERENCES course_phrases (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS index_phrase_srs_phraseId '
      'ON phrase_srs(phraseId)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS index_phrase_srs_nextReviewDate '
      'ON phrase_srs(nextReviewDate)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS exam_attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        lessonId INTEGER NOT NULL,
        attemptNumber INTEGER NOT NULL,
        score INTEGER NOT NULL,
        date INTEGER NOT NULL,
        answersJson TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS index_exam_attempts_lessonId '
      'ON exam_attempts(lessonId)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS index_exam_attempts_userId '
      'ON exam_attempts(userId)',
    );
  }

  Future<void> _createUserProfileTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profile (
        id TEXT PRIMARY KEY,
        uid TEXT NOT NULL,
        name TEXT NOT NULL,
        homework_task TEXT,
        created_at INTEGER
      )
    ''');
  }

  Future<String?> getMeta(String key) async {
    final db = await database;
    final rows = await db.query(
      'content_meta',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['value'] as String?;
  }

  Future<void> setMeta(String key, String value) async {
    final db = await database;
    await db.insert(
      'content_meta',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> topicCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM course_topics',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<TopicRow>> topicsByLanguage(String languageCode) async {
    final db = await database;
    final rows = await db.query(
      'course_topics',
      where: 'learning_language_code = ?',
      whereArgs: [languageCode],
      orderBy: 'order_index ASC',
    );
    return rows.map(TopicRow.fromMap).toList();
  }

  Future<TopicRow?> topicById(int id) async {
    final db = await database;
    final rows = await db.query(
      'course_topics',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return TopicRow.fromMap(rows.first);
  }

  Future<List<PhraseRow>> phrasesByTopic(int topicId) async {
    final db = await database;
    final rows = await db.query(
      'course_phrases',
      where: 'topic_id = ?',
      whereArgs: [topicId],
      orderBy: 'order_index ASC',
    );
    return rows.map(PhraseRow.fromMap).toList();
  }

  Future<List<PhraseRow>> phrasesByIds(List<int> ids) async {
    if (ids.isEmpty) {
      return const [];
    }
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await db.rawQuery(
      'SELECT * FROM course_phrases WHERE id IN ($placeholders)',
      ids,
    );
    return rows.map(PhraseRow.fromMap).toList();
  }

  Future<List<PhraseRow>> phrasesByLanguage(String languageCode) async {
    final db = await database;
    final rows = await db.query(
      'course_phrases',
      where: 'learning_language_code = ?',
      whereArgs: [languageCode],
      orderBy: 'topic_id ASC, order_index ASC',
    );
    return rows.map(PhraseRow.fromMap).toList();
  }

  Future<void> replaceCourse({
    required String languageCode,
    required List<TopicRow> topics,
    required List<PhraseRow> phrases,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'course_phrases',
        where: 'learning_language_code = ?',
        whereArgs: [languageCode],
      );
      await txn.delete(
        'course_topics',
        where: 'learning_language_code = ?',
        whereArgs: [languageCode],
      );
      for (final topic in topics) {
        await txn.insert('course_topics', topic.toMap());
      }
      for (final phrase in phrases) {
        await txn.insert('course_phrases', phrase.toMap());
      }
    });
  }
}
