import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vilka/features/player/data/tts_file_cache.dart';

void main() {
  test('silence wav is 2s PCM 22050 Hz 16-bit mono', () {
    final bytes = TtsFileCache.buildSilenceWavBytes();
    final data = ByteData.sublistView(bytes);
    expect(ascii.decode(bytes.sublist(0, 4)), 'RIFF');
    expect(ascii.decode(bytes.sublist(8, 12)), 'WAVE');
    expect(ascii.decode(bytes.sublist(12, 16)), 'fmt ');
    expect(ascii.decode(bytes.sublist(36, 40)), 'data');
    expect(data.getUint16(20, Endian.little), 1);
    expect(data.getUint16(22, Endian.little), 1);
    expect(data.getUint32(24, Endian.little), 22050);
    expect(data.getUint16(34, Endian.little), 16);
    const dataSize = 22050 * 2 * 2;
    expect(data.getUint32(40, Endian.little), dataSize);
    expect(bytes.length, 44 + dataSize);
  });
}
