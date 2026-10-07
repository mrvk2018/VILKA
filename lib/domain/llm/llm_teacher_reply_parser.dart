/// Port of legacy `LlmTeacherReplyParser`.
class LlmTeacherReplyParser {
  static const markerRu = '[RU]';
  static const markerEn = '[EN]';

  static final _markerRuRegex = RegExp(r'\[\s*ru\s*]', caseSensitive: false);
  static final _markerEnRegex = RegExp(r'\[\s*en\s*]', caseSensitive: false);
  static final _cyrillicRegex = RegExp('[а-яА-ЯёЁ]');
  static final _latinRegex = RegExp('[a-zA-Z]');

  static String markerForNativeLanguage(String nativeLanguage) =>
      nativeLanguage.toLowerCase() == 'en' ? markerEn : markerRu;

  static ParsedReply parse(String raw, String nativeLanguage) {
    final markerRegex = nativeLanguage.toLowerCase() == 'en'
        ? _markerEnRegex
        : _markerRuRegex;
    final match = markerRegex.firstMatch(raw);
    if (match == null) {
      final trimmed = raw.trim();
      return ParsedReply(
        koreanPart: trimmed,
        explanationPart: '',
        displayText: trimmed,
      );
    }
    final korean = raw.substring(0, match.start).trim();
    final explanation = raw.substring(match.end).trim();
    final display = explanation.isEmpty ? korean : '$korean\n\n$explanation';
    return ParsedReply(
      koreanPart: korean,
      explanationPart: explanation,
      displayText: display,
    );
  }

  /// Korean TTS string: strip Cyrillic/Latin so the engine is not silent
  /// or misreads RU/EN. Empty result must be treated as "skip TTS", not crash.
  static String sanitizeForKoreanTts(String text) {
    return text
        .replaceAll(_cyrillicRegex, '')
        .replaceAll(_latinRegex, '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class ParsedReply {
  const ParsedReply({
    required this.koreanPart,
    required this.explanationPart,
    required this.displayText,
  });

  final String koreanPart;
  final String explanationPart;
  final String displayText;
}
