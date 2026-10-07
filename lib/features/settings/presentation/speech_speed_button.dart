import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import 'speech_speed_notifier.dart';

class SpeechSpeedButton extends ConsumerWidget {
  const SpeechSpeedButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final speed = ref.watch(speechSpeedProvider);
    return Tooltip(
      message: l10n.speechSpeedTooltip,
      child: TextButton.icon(
        onPressed: () {
          ref.read(speechSpeedProvider.notifier).toggleSpeed();
        },
        icon: const Icon(Icons.speed, size: 20),
        label: Text(SpeechSpeedNotifier.labelFor(speed)),
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }
}
