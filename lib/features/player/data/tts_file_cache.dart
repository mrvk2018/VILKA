import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../domain/course/phrase.dart';
import '../../../domain/llm/llm_teacher_reply_parser.dart';

/// Disk cache for Korean TTS utterance files, Russian intro, and a shared 2s silence WAV.
class TtsFileCache {
  TtsFileCache({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  static const koreanLocale = 'ko-KR';
  static const russianLocale = 'ru-RU';
  static const speechRate = 0.45;
  static const cacheFolderName = 'tts';
  static const introText =
      'фонетический урок, во время пауз повторяйте фразу на корейском за учителем';
  static const silenceFileName = 'silence_2s.wav';
  static const silenceSampleRate = 22050;
  static const silenceDurationSeconds = 2;
  static const silenceBitsPerSample = 16;
  static const silenceChannels = 1;

  final FlutterTts _tts;

  Directory? _dir;
  bool _ready = false;
  double speedCoefficient = 1.0;

  /// Absolute path to the 2s silence WAV. Valid after [ensureInitialized].
  String get silenceFilePath {
    final dir = _dir;
    if (dir == null) {
      throw StateError('TtsFileCache.ensureInitialized() must run first');
    }
    return p.join(dir.path, silenceFileName);
  }

  Future<void> ensureInitialized() async {
    if (_ready) {
      return;
    }
    final cache = await getApplicationCacheDirectory();
    final dir = Directory(p.join(cache.path, cacheFolderName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _dir = dir;
    await _tts.setLanguage(koreanLocale);
    await _tts.setSpeechRate(_koreanSpeechRate);
    await _tts.awaitSynthCompletion(true);
    await _ensureSilenceWav();
    _ready = true;
  }

  /// Synthesizes the Russian lesson intro. File name includes MD5 of [introText].
  Future<String?> prepareIntroFile() async {
    await ensureInitialized();
    final file = File(_introFilePath());
    if (await file.exists() && await file.length() > 0) {
      return file.path;
    }
    try {
      await _tts.setLanguage(russianLocale);
      await _tts.setSpeechRate(speechRate);
      await _tts.synthesizeToFile(introText, file.path, true);
    } finally {
      await _tts.setLanguage(koreanLocale);
      await _tts.setSpeechRate(_koreanSpeechRate);
    }
    if (await file.exists() && await file.length() > 0) {
      return file.path;
    }
    return null;
  }

  /// Sequential TTS prefetch. Empty sanitized phrases are skipped.
  Future<List<String>> prepareTopicFiles(List<Phrase> phrases) async {
    await ensureInitialized();
    await _tts.setLanguage(koreanLocale);
    await _tts.setSpeechRate(_koreanSpeechRate);
    final paths = <String>[];
    for (final phrase in phrases) {
      final text = LlmTeacherReplyParser.sanitizeForKoreanTts(phrase.koreanText);
      if (text.isEmpty) {
        continue;
      }
      final file = File(_phraseFilePath(phrase.id, text));
      if (!await file.exists() || await file.length() == 0) {
        await _tts.synthesizeToFile(text, file.path, true);
      }
      if (await file.exists() && await file.length() > 0) {
        paths.add(file.path);
      }
    }
    return paths;
  }

  String _introFilePath() {
    final dir = _dir;
    if (dir == null) {
      throw StateError('TtsFileCache.ensureInitialized() must run first');
    }
    final digest = md5.convert(utf8.encode(introText)).toString();
    return p.join(dir.path, 'intro_$digest.$_phraseExtension');
  }

  String _phraseFilePath(int phraseId, String sanitizedText) {
    final dir = _dir;
    if (dir == null) {
      throw StateError('TtsFileCache.ensureInitialized() must run first');
    }
    final digest = phraseDigest(sanitizedText, speedCoefficient);
    return p.join(dir.path, '${phraseId}_$digest.$_phraseExtension');
  }

  /// MD5 of Korean text plus speed so a rate change cannot reuse old files.
  static String phraseDigest(String sanitizedText, double speedCoefficient) {
    return md5.convert(utf8.encode('$sanitizedText$speedCoefficient')).toString();
  }

  double get _koreanSpeechRate => speechRate * speedCoefficient;

  String get _phraseExtension => Platform.isIOS ? 'caf' : 'wav';

  Future<void> _ensureSilenceWav() async {
    final file = File(silenceFilePath);
    final expectedLength = 44 + _silenceDataSize();
    if (await file.exists() && await file.length() == expectedLength) {
      return;
    }
    await file.writeAsBytes(buildSilenceWavBytes(), flush: true);
  }

  /// PCM WAV header + 2 seconds of zeros. 22050 Hz, 16-bit, mono.
  static Uint8List buildSilenceWavBytes({
    int sampleRate = silenceSampleRate,
    int durationSeconds = silenceDurationSeconds,
    int channels = silenceChannels,
    int bitsPerSample = silenceBitsPerSample,
  }) {
    final bytesPerSample = bitsPerSample ~/ 8;
    final dataSize = sampleRate * durationSeconds * channels * bytesPerSample;
    final buffer = ByteData(44 + dataSize);

    void writeAscii(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        buffer.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    writeAscii(0, 'RIFF');
    buffer.setUint32(4, 36 + dataSize, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little);
    buffer.setUint16(22, channels, Endian.little);
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * channels * bytesPerSample, Endian.little);
    buffer.setUint16(32, channels * bytesPerSample, Endian.little);
    buffer.setUint16(34, bitsPerSample, Endian.little);
    writeAscii(36, 'data');
    buffer.setUint32(40, dataSize, Endian.little);
    return buffer.buffer.asUint8List();
  }

  static int _silenceDataSize() {
    return silenceSampleRate *
        silenceDurationSeconds *
        silenceChannels *
        (silenceBitsPerSample ~/ 8);
  }
}
