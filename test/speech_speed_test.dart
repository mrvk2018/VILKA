import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vilka/features/player/data/tts_file_cache.dart';
import 'package:vilka/features/settings/presentation/speech_speed_notifier.dart';

void main() {
  test('speech speed cycles 1.0 → 0.8 → 0.6 → 1.0', () {
    expect(SpeechSpeedNotifier.nextCoefficient(1.0), 0.8);
    expect(SpeechSpeedNotifier.nextCoefficient(0.8), 0.6);
    expect(SpeechSpeedNotifier.nextCoefficient(0.6), 1.0);
  });

  test('korean TTS rate is 0.45 multiplied by the coefficient', () {
    expect(SpeechSpeedNotifier.koreanSpeechRate(1.0), closeTo(0.45, 1e-9));
    expect(SpeechSpeedNotifier.koreanSpeechRate(0.8), closeTo(0.36, 1e-9));
    expect(SpeechSpeedNotifier.koreanSpeechRate(0.6), closeTo(0.27, 1e-9));
  });

  test('phrase cache digest includes the speed coefficient', () {
    const text = '안녕하세요';
    final atFull = TtsFileCache.phraseDigest(text, 1.0);
    final atSlow = TtsFileCache.phraseDigest(text, 0.8);
    expect(atFull, md5.convert(utf8.encode('${text}1.0')).toString());
    expect(atSlow, isNot(atFull));
    expect(
      TtsFileCache.phraseDigest(TtsFileCache.introText, 0.8),
      isNot(md5.convert(utf8.encode(TtsFileCache.introText)).toString()),
    );
  });

  test('speed labels are 1.0x, 0.8x and 0.6x', () {
    expect(SpeechSpeedNotifier.labelFor(1.0), '1.0x');
    expect(SpeechSpeedNotifier.labelFor(0.8), '0.8x');
    expect(SpeechSpeedNotifier.labelFor(0.6), '0.6x');
  });
}
