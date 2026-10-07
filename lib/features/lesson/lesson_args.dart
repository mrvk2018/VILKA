class LessonArgs {
  const LessonArgs({
    required this.topicId,
    required this.phraseId,
  });

  final int topicId;
  final int phraseId;

  @override
  bool operator ==(Object other) {
    return other is LessonArgs &&
        other.topicId == topicId &&
        other.phraseId == phraseId;
  }

  @override
  int get hashCode => Object.hash(topicId, phraseId);
}
