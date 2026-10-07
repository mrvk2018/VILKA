/// Target language the user is learning. MVP ships `ko`; more codes later.
enum LearningLanguage {
  ko('ko'),
  ja('ja'),
  zh('zh');

  const LearningLanguage(this.code);

  final String code;

  static LearningLanguage fromCode(String code) {
    return LearningLanguage.values.firstWhere(
      (item) => item.code == code,
      orElse: () => LearningLanguage.ko,
    );
  }
}
