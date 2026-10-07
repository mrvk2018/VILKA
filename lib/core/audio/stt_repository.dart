import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';

enum SttStatus { idle, listening, error }

class SttState {
  const SttState({
    required this.status,
    this.message = '',
  });

  final SttStatus status;
  final String message;

  static const idle = SttState(status: SttStatus.idle);
}

/// Thin wrapper around speech_to_text. Binary heard / not-heard, no scoring.
abstract class SttRepository {
  Stream<SttState> get state;

  Future<void> listen({
    required void Function(String text) onResult,
    String localeId = 'ko_KR',
  });

  Future<void> stop();

  Future<void> dispose();
}

class SpeechToTextRepository implements SttRepository {
  SpeechToTextRepository({SpeechToText? speech})
      : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  final _controller = StreamController<SttState>.broadcast();
  bool _initialized = false;

  @override
  Stream<SttState> get state => _controller.stream;

  Future<bool> _ensureInitialized() async {
    if (_initialized) {
      return true;
    }
    _initialized = await _speech.initialize(
      onError: (error) {
        _controller.add(
          SttState(
            status: SttStatus.error,
            message: error.errorMsg,
          ),
        );
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _controller.add(SttState.idle);
        }
      },
    );
    return _initialized;
  }

  @override
  Future<void> listen({
    required void Function(String text) onResult,
    String localeId = 'ko_KR',
  }) async {
    final ready = await _ensureInitialized();
    if (!ready) {
      _controller.add(
        const SttState(
          status: SttStatus.error,
          message: 'speech_unavailable',
        ),
      );
      return;
    }
    if (_speech.isListening) {
      await _speech.stop();
    }
    _controller.add(const SttState(status: SttStatus.listening));
    await _speech.listen(
      listenOptions: SpeechListenOptions(localeId: localeId),
      onResult: (result) {
        if (!result.finalResult) {
          return;
        }
        onResult(result.recognizedWords);
        _controller.add(SttState.idle);
      },
    );
  }

  @override
  Future<void> stop() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
    _controller.add(SttState.idle);
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}
