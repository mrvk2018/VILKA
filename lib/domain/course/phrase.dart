import '../../core/ui_locale.dart';

class Phrase {
  const Phrase({
    required this.id,
    required this.topicId,
    required this.koreanText,
    required this.russianTranslation,
    required this.englishTranslation,
    required this.audioUrlOrPath,
    required this.order,
    required this.learningLanguageCode,
  });

  final int id;
  final int topicId;
  final String koreanText;
  final String russianTranslation;
  final String englishTranslation;
  final String audioUrlOrPath;
  final int order;
  final String learningLanguageCode;

  /// Target-language text. Korean-only for MVP; later switch by code.
  String get learningText => koreanText;

  String translationFor(UiLocale locale) =>
      locale == UiLocale.en ? englishTranslation : russianTranslation;
}
