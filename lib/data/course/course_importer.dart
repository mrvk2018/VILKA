import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/database/app_database.dart';
import 'course_bundle.dart';

class CourseImporter {
  CourseImporter(this._db);

  static const koreanAssetPath = 'assets/course/ko/course.json';

  final AppDatabase _db;

  Future<void> importIfNeeded({String assetPath = koreanAssetPath}) async {
    final raw = await rootBundle.loadString(assetPath);
    final bundle = CourseBundle.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    final metaKey = 'course_version_${bundle.learningLanguageCode}';
    final stored = await _db.getMeta(metaKey);
    final alreadyImported = stored == bundle.version.toString();
    if (alreadyImported && await _db.topicCount() > 0) {
      return;
    }

    await _db.replaceCourse(
      languageCode: bundle.learningLanguageCode,
      topics: [
        for (final topic in bundle.topics)
          TopicRow(
            id: topic.id,
            key: topic.key,
            titleRu: topic.titleRu,
            titleEn: topic.titleEn,
            orderIndex: topic.order,
            learningLanguageCode: bundle.learningLanguageCode,
          ),
      ],
      phrases: [
        for (final phrase in bundle.phrases)
          PhraseRow(
            id: phrase.id,
            topicId: phrase.topicId,
            koreanText: phrase.koreanText,
            russianTranslation: phrase.russianTranslation,
            englishTranslation: phrase.englishTranslation,
            audioUrlOrPath: phrase.audioUrlOrPath,
            orderIndex: phrase.order,
            learningLanguageCode: bundle.learningLanguageCode,
          ),
      ],
    );
    await _db.setMeta(metaKey, bundle.version.toString());
  }
}
