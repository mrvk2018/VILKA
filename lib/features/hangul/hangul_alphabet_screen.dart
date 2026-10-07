import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/ui_locale.dart';
import '../../domain/hangul/hangul_alphabet.dart';
import '../../l10n/generated/app_localizations.dart';
import '../level/presentation/level_routes.dart';
import '../settings/presentation/speech_speed_notifier.dart';

class HangulAlphabetScreen extends ConsumerWidget {
  const HangulAlphabetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final useEnglish = ref.watch(uiLocaleProvider) == UiLocale.en;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.hangulAlphabetTitle)),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  l10n.hangulAlphabetSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            _sectionHeader(context, l10n.hangulSectionConsonants),
            _letterGrid(context, ref, HangulAlphabet.consonants, useEnglish),
            _sectionHeader(context, l10n.hangulSectionVowels),
            _letterGrid(context, ref, HangulAlphabet.vowels, useEnglish),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }

  SliverPadding _sectionHeader(BuildContext context, String title) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      sliver: SliverToBoxAdapter(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  SliverPadding _letterGrid(
    BuildContext context,
    WidgetRef ref,
    List<HangulLetter> letters,
    bool useEnglish,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.68,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final letter = letters[index];
            return _HangulLetterCard(
              letter: letter,
              useEnglish: useEnglish,
              onPlay: () {
                ref.read(ttsEngineProvider).speakKorean(
                      letter.char,
                      speedCoefficient: ref.read(speechSpeedProvider),
                    );
              },
              onPractice: () {
                context.push(LevelRoutes.hangulDraw(letter.char));
              },
            );
          },
          childCount: letters.length,
        ),
      ),
    );
  }
}

class _HangulLetterCard extends StatelessWidget {
  const _HangulLetterCard({
    required this.letter,
    required this.useEnglish,
    required this.onPlay,
    required this.onPractice,
  });

  final HangulLetter letter;
  final bool useEnglish;
  final VoidCallback onPlay;
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onPlay,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                letter.char,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28),
              ),
              Text(
                letter.nameFor(useEnglish: useEnglish),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              IconButton(
                onPressed: onPractice,
                tooltip: l10n.hangulPracticeLetter,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(
                  Icons.edit,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
