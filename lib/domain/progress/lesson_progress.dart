class LessonProgress {
  const LessonProgress({
    required this.userId,
    required this.lessonId,
    this.timesCompletedFullPlaythrough = 0,
    this.lastStopPressedAt,
    this.examAvailable = false,
  });

  final String userId;
  final int lessonId;
  final int timesCompletedFullPlaythrough;
  final int? lastStopPressedAt;
  final bool examAvailable;

  LessonProgress copyWith({
    String? userId,
    int? lessonId,
    int? timesCompletedFullPlaythrough,
    int? lastStopPressedAt,
    bool? examAvailable,
  }) {
    return LessonProgress(
      userId: userId ?? this.userId,
      lessonId: lessonId ?? this.lessonId,
      timesCompletedFullPlaythrough:
          timesCompletedFullPlaythrough ?? this.timesCompletedFullPlaythrough,
      lastStopPressedAt: lastStopPressedAt ?? this.lastStopPressedAt,
      examAvailable: examAvailable ?? this.examAvailable,
    );
  }

  Map<String, Object?> toSqlMap() {
    return {
      'userId': userId,
      'lessonId': lessonId,
      'timesCompletedFullPlaythrough': timesCompletedFullPlaythrough,
      'lastStopPressedAt': lastStopPressedAt,
      'examAvailable': examAvailable ? 1 : 0,
    };
  }

  factory LessonProgress.fromSqlMap(Map<String, Object?> map) {
    return LessonProgress(
      userId: map['userId'] as String,
      lessonId: map['lessonId'] as int,
      timesCompletedFullPlaythrough:
          map['timesCompletedFullPlaythrough'] as int? ?? 0,
      lastStopPressedAt: map['lastStopPressedAt'] as int?,
      examAvailable: (map['examAvailable'] as int? ?? 0) != 0,
    );
  }
}
