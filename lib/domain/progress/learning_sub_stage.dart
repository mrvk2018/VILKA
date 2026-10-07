/// Sub-stage inside a topic. Codes match legacy `LearningSubStage`.
enum LearningSubStage {
  introduction(1),
  speaking(2),
  llmDialog(3);

  const LearningSubStage(this.code);

  final int code;

  static LearningSubStage fromCode(int code) {
    return LearningSubStage.values.firstWhere(
      (item) => item.code == code,
      orElse: () => LearningSubStage.introduction,
    );
  }
}
