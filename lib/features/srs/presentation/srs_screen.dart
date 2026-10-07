import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../settings/presentation/speech_speed_button.dart';
import '../../settings/presentation/speech_speed_notifier.dart';
import 'srs_notifier.dart';

class SrsScreen extends ConsumerStatefulWidget {
  const SrsScreen({super.key});

  @override
  ConsumerState<SrsScreen> createState() => _SrsScreenState();
}

class _SrsScreenState extends ConsumerState<SrsScreen> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(srsProvider.select((value) => value.currentPhrase?.id), (
      previous,
      next,
    ) {
      if (next == null) {
        return;
      }
      final phrase = ref.read(srsProvider).currentPhrase;
      if (phrase == null || ref.read(srsProvider).isRevealed) {
        return;
      }
      unawaited(
        ref.read(ttsEngineProvider).speakKorean(
              phrase.koreanText,
              speedCoefficient: ref.read(speechSpeedProvider),
            ),
      );
    }, fireImmediately: true);
    ref.listenManual(speechSpeedProvider, (previous, next) {
      if (previous == next) {
        return;
      }
      final current = ref.read(srsProvider).currentPhrase;
      if (current == null) {
        return;
      }
      unawaited(
        ref.read(ttsEngineProvider).speakKorean(
              current.koreanText,
              speedCoefficient: next,
            ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(uiLocaleProvider);
    final srs = ref.watch(srsProvider);
    final notifier = ref.read(srsProvider.notifier);
    final phrase = srs.currentPhrase;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.srsTitle),
        actions: const [SpeechSpeedButton()],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: srs.isLoading
              ? const Center(child: CircularProgressIndicator())
              : srs.error != null
                  ? Center(child: Text(l10n.loadError))
                  : srs.isFinished || phrase == null
                      ? _SrsFinished(onBack: () => context.pop())
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  l10n.srsProgress(
                                    srs.currentIndex + 1,
                                    srs.duePhrases.length,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: Center(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: 560,
                                        minHeight: constraints.maxHeight * 0.4,
                                      ),
                                      child: Card(
                                        child: Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                phrase.koreanText,
                                                textAlign: TextAlign.center,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headlineSmall,
                                              ),
                                              if (srs.isRevealed) ...[
                                                const SizedBox(height: 24),
                                                Text(
                                                  phrase.translationFor(locale),
                                                  textAlign: TextAlign.center,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleLarge,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                if (!srs.isRevealed)
                                  FilledButton(
                                    onPressed: notifier.reveal,
                                    child: Text(l10n.srsShowTranslation),
                                  )
                                else
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor:
                                                Colors.red.shade600,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                          ),
                                          onPressed: notifier.markWrong,
                                          child: Text(l10n.srsForgot),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor:
                                                Colors.green.shade600,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                          ),
                                          onPressed: () =>
                                              notifier.markCorrect(phrase.id),
                                          child: Text(l10n.srsRemember),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            );
                          },
                        ),
        ),
      ),
    );
  }
}

class _SrsFinished extends StatelessWidget {
  const _SrsFinished({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 72,
              color: Colors.green.shade600,
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.srsFinished,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onBack,
              child: Text(l10n.srsBack),
            ),
          ],
        ),
      ),
    );
  }
}
