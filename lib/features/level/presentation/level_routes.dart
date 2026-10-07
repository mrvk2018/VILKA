/// Nested routes under Level 0 (current course home).
abstract final class LevelRoutes {
  static const selection = '/';
  static const level0 = '/level/0';
  static const srs = '/level/0/srs';
  static const hangul = '/level/0/hangul';
  static const topics = '/level/0/topics';

  static String hangulDraw(String letter) =>
      '$hangul/draw/${Uri.encodeComponent(letter)}';

  static String topic(int topicId) => '$topics/$topicId';

  static String lesson(int topicId, int phraseId) =>
      '${topic(topicId)}/phrases/$phraseId';

  static String player(int topicId) => '${topic(topicId)}/player';

  static String exam(int topicId) => '${topic(topicId)}/exam';
}
