import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import 'level_routes.dart';

class LevelSelectionScreen extends StatelessWidget {
  const LevelSelectionScreen({super.key});

  static const _levelCount = 6;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.levelsTitle)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 720;
            final horizontal = wide ? 24.0 : 16.0;
            return GridView.builder(
              padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 24),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: wide ? 2 : 1,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: wide ? 1.7 : 2.35,
              ),
              itemCount: _levelCount,
              itemBuilder: (context, index) {
                return _LevelCard(
                  level: index,
                  unlocked: index == 0,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.unlocked,
  });

  final int level;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final title = l10n.levelName(level);
    final subtitle = unlocked ? l10n.level0Subtitle : l10n.levelLockedSubtitle;

    final card = Card(
      elevation: unlocked ? 4 : 0,
      color: unlocked ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: unlocked
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: 0.12),
              foregroundColor: unlocked
                  ? scheme.onPrimary
                  : scheme.onSurface.withValues(alpha: 0.45),
              child: Text(
                '$level',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: unlocked
                      ? scheme.onPrimary
                      : scheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: unlocked
                          ? scheme.onPrimaryContainer
                          : scheme.onSurface.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: unlocked
                          ? scheme.onPrimaryContainer.withValues(alpha: 0.8)
                          : scheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              unlocked ? Icons.chevron_right : Icons.lock_outline,
              size: 28,
              color: unlocked
                  ? scheme.onPrimaryContainer
                  : scheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );

    if (unlocked) {
      return InkWell(
        onTap: () => context.push(LevelRoutes.level0),
        borderRadius: BorderRadius.circular(12),
        child: card,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(l10n.levelLockedSnackbar)),
          );
      },
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.72,
          child: card,
        ),
      ),
    );
  }
}
