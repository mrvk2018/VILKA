class CourseBundle {
  const CourseBundle({
    required this.learningLanguageCode,
    required this.version,
    required this.topics,
    required this.phrases,
  });

  final String learningLanguageCode;
  final int version;
  final List<CourseTopicJson> topics;
  final List<CoursePhraseJson> phrases;

  factory CourseBundle.fromJson(Map<String, dynamic> json) {
    return CourseBundle(
      learningLanguageCode: json['learningLanguageCode'] as String,
      version: json['version'] as int,
      topics: (json['topics'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(CourseTopicJson.fromJson)
          .toList(),
      phrases: (json['phrases'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(CoursePhraseJson.fromJson)
          .toList(),
    );
  }
}

class CourseTopicJson {
  const CourseTopicJson({
    required this.id,
    required this.key,
    required this.titleRu,
    required this.titleEn,
    required this.order,
  });

  final int id;
  final String key;
  final String titleRu;
  final String titleEn;
  final int order;

  factory CourseTopicJson.fromJson(Map<String, dynamic> json) {
    return CourseTopicJson(
      id: json['id'] as int,
      key: json['key'] as String,
      titleRu: json['titleRu'] as String,
      titleEn: json['titleEn'] as String,
      order: json['order'] as int,
    );
  }
}

class CoursePhraseJson {
  const CoursePhraseJson({
    required this.id,
    required this.topicId,
    required this.koreanText,
    required this.russianTranslation,
    required this.englishTranslation,
    required this.audioUrlOrPath,
    required this.order,
  });

  final int id;
  final int topicId;
  final String koreanText;
  final String russianTranslation;
  final String englishTranslation;
  final String audioUrlOrPath;
  final int order;

  factory CoursePhraseJson.fromJson(Map<String, dynamic> json) {
    return CoursePhraseJson(
      id: json['id'] as int,
      topicId: json['topicId'] as int,
      koreanText: json['koreanText'] as String,
      russianTranslation: json['russianTranslation'] as String,
      englishTranslation: json['englishTranslation'] as String,
      audioUrlOrPath: json['audioUrlOrPath'] as String? ?? '',
      order: json['order'] as int,
    );
  }
}
