import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vilka/features/player/data/tts_file_cache.dart';

void main() {
  test('lesson intro text is the phonetic-repeat prompt', () {
    expect(
      TtsFileCache.introText,
      'фонетический урок, во время пауз повторяйте фразу на корейском за учителем',
    );
  });

  test('intro cache key uses MD5 of the current intro text', () {
    final digest = md5.convert(utf8.encode(TtsFileCache.introText)).toString();
    expect(digest, hasLength(32));
    expect(
      digest,
      isNot(md5.convert(utf8.encode('Интро: метод фонетического погружения')).toString()),
    );
  });
}
