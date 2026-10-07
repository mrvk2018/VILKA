import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../level/presentation/level_routes.dart';

class TopicsScreen extends ConsumerWidget {
  const TopicsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(uiLocaleProvider);
    final topics = ref.watch(topicsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.topicsTitle)),
      body: topics.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(child: Text(l10n.emptyTopics));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final topic = items[index];
              return ListTile(
                title: Text(topic.titleFor(locale)),
                subtitle: Text(topic.key),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(LevelRoutes.topic(topic.id)),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(l10n.loadError)),
      ),
    );
  }
}
