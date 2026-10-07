/// Language of the app UI and phrase translations.
enum UiLocale {
  ru('ru'),
  en('en');

  const UiLocale(this.code);

  final String code;

  static UiLocale fromCode(String code) {
    return UiLocale.values.firstWhere(
      (item) => item.code == code,
      orElse: () => UiLocale.ru,
    );
  }
}
