import '../../core/ui_locale.dart';

class Topic {
  const Topic({
    required this.id,
    required this.key,
    required this.titleRu,
    required this.titleEn,
    required this.order,
    required this.learningLanguageCode,
  });

  final int id;
  final String key;
  final String titleRu;
  final String titleEn;
  final int order;
  final String learningLanguageCode;

  String titleFor(UiLocale locale) =>
      locale == UiLocale.en ? titleEn : titleRu;
}
