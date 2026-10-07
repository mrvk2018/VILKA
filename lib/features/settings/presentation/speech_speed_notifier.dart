import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

/// Cycles 1.0 → 0.8 → 0.6 → 1.0 and persists to `content_meta`.
class SpeechSpeedNotifier extends Notifier<double> {
  static const metaKey = 'speech_speed_coefficient';
  static const koreanBaseRate = 0.45;
  static const steps = <double>[1.0, 0.8, 0.6];

  static double normalize(double value) {
    for (final step in steps) {
      if ((step - value).abs() < 0.001) {
        return step;
      }
    }
    return 1.0;
  }

  static double nextCoefficient(double current) {
    final normalized = normalize(current);
    final index = steps.indexOf(normalized);
    return steps[(index + 1) % steps.length];
  }

  static double koreanSpeechRate(double coefficient) =>
      koreanBaseRate * normalize(coefficient);

  static String labelFor(double coefficient) =>
      '${normalize(coefficient).toStringAsFixed(1)}x';

  @override
  double build() {
    Future<void>.microtask(_load);
    return 1.0;
  }

  Future<void> _load() async {
    final raw = await ref.read(appDatabaseProvider).getMeta(metaKey);
    if (!ref.mounted) {
      return;
    }
    final parsed = double.tryParse(raw ?? '');
    state = parsed == null ? 1.0 : normalize(parsed);
    await _applyToHandler();
  }

  Future<void> toggleSpeed() async {
    state = nextCoefficient(state);
    await ref.read(appDatabaseProvider).setMeta(metaKey, state.toString());
    await _applyToHandler();
  }

  Future<void> _applyToHandler() async {
    await ref.read(audioHandlerProvider).setSpeechSpeed(state);
  }
}

final speechSpeedProvider =
    NotifierProvider<SpeechSpeedNotifier, double>(SpeechSpeedNotifier.new);
