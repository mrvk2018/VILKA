import 'package:flutter_tts/flutter_tts.dart';

import '../../domain/llm/llm_teacher_reply_parser.dart';

/// Thin wrapper around flutter_tts. Korean speech only after sanitize.
abstract class TtsEngine {
  Future<void> speakKorean(String text, {double speedCoefficient = 1.0});

  Future<void> stop();

  Future<void> dispose();
}

class FlutterTtsEngine implements TtsEngine {
  FlutterTtsEngine({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  static const koreanLocale = 'ko-KR';

  final FlutterTts _tts;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }
    await _tts.setLanguage(koreanLocale);
    _initialized = true;
  }

  @override
  Future<void> speakKorean(
    String text, {
    double speedCoefficient = 1.0,
  }) async {
    final speechText = LlmTeacherReplyParser.sanitizeForKoreanTts(text);
    if (speechText.isEmpty) {
      return;
    }
    await _ensureInitialized();
    await _tts.setSpeechRate(0.45 * speedCoefficient);
    await _tts.stop();
    await _tts.speak(speechText);
  }

  @override
  Future<void> stop() {
    return _tts.stop();
  }

  @override
  Future<void> dispose() async {
    await _tts.stop();
  }
}
