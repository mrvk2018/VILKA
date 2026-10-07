import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/providers.dart';
import '../../data/repositories/profile_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../level/presentation/level_routes.dart';
import '../srs/presentation/srs_notifier.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestInitialPermissions();
    });
  }

  Future<void> _requestInitialPermissions() async {
    final result =
        await ref.read(permissionServiceProvider).requestInitialPermissions();
    if (!mounted) {
      return;
    }
    if (result.canUseStt) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.microphonePermissionDenied),
        action: SnackBarAction(
          label: l10n.openAppSettings,
          onPressed: openAppSettings,
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    if (_signingOut) {
      return;
    }
    setState(() => _signingOut = true);
    try {
      await ref.read(profileRepositoryProvider).signOut();
      ref.invalidate(userProfileProvider);
      if (!mounted) {
        return;
      }
      context.go('/welcome');
    } finally {
      if (mounted) {
        setState(() => _signingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final topics = ref.watch(topicsProvider);
    final locale = ref.watch(uiLocaleProvider);
    final dueCount = ref.watch(dueSrsCountProvider);
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          TextButton(
            onPressed: () => ref.read(uiLocaleProvider.notifier).toggle(),
            child: Text(locale.code.toUpperCase()),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    profile.when(
                      data: (data) => _StudentHeader(
                        profile: data,
                        signingOut: _signingOut,
                        onSignOut: _signOut,
                      ),
                      loading: () => const _ProfileSkeleton(),
                      error: (_, _) => _StudentHeader(
                        profile: null,
                        signingOut: _signingOut,
                        onSignOut: _signOut,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _HomeworkCard(profile: profile),
                    const SizedBox(height: 24),
                    Text(
                      l10n.homeSubtitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${l10n.learningLanguageLabel}: ${l10n.korean}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    topics.when(
                      data: (items) => Text(l10n.topicCount(items.length)),
                      loading: () => const LinearProgressIndicator(),
                      error: (error, _) => Text(l10n.loadError),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        onPressed: () => context.push(LevelRoutes.hangul),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                        ),
                        child: Text(l10n.hangulLearnBanner),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SrsHomeCard(dueCount: dueCount),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.push(LevelRoutes.topics),
                  child: Text(l10n.openTopics),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentHeader extends StatelessWidget {
  const _StudentHeader({
    required this.profile,
    required this.signingOut,
    required this.onSignOut,
  });

  final Map<String, dynamic>? profile;
  final bool signingOut;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rawName = profile?['name'] as String?;
    final name = rawName == null || rawName.trim().isEmpty
        ? TeacherPromptDefaults.studentName
        : rawName.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            l10n.homeGreeting(name),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          tooltip: l10n.homeLogout,
          onPressed: signingOut ? null : onSignOut,
          icon: signingOut
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout),
        ),
      ],
    );
  }
}

class TeacherPromptDefaults {
  static const studentName = 'Ученик';
}

class _HomeworkCard extends StatelessWidget {
  const _HomeworkCard({required this.profile});

  final AsyncValue<Map<String, dynamic>?> profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (profile.isLoading) {
      return const _HomeworkSkeleton();
    }
    final data = profile.value;
    final rawTask = data?['homework_task'] as String?;
    final task = rawTask == null || rawTask.trim().isEmpty
        ? l10n.homeHomeworkFallback
        : rawTask.trim();
    return Card(
      elevation: 0,
      color: const Color(0xFFFFF6D8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFFFE082)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.menu_book_outlined, color: Colors.black87),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.homeHomeworkTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.black,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShimmerBar(width: 220, height: 28),
              SizedBox(height: 8),
              _ShimmerBar(width: 140, height: 16),
            ],
          ),
        ),
        _ShimmerBar(width: 36, height: 36, radius: 18),
      ],
    );
  }
}

class _HomeworkSkeleton extends StatelessWidget {
  const _HomeworkSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: 0,
      color: Color(0xFFFFF6D8),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _ShimmerBar(width: 200, height: 18),
            ),
            SizedBox(height: 16),
            _ShimmerBar(width: double.infinity, height: 14),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: _ShimmerBar(width: 260, height: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerBar extends StatefulWidget {
  const _ShimmerBar({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<_ShimmerBar> createState() => _ShimmerBarState();
}

class _ShimmerBarState extends State<_ShimmerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = 0.35 + (_controller.value * 0.35);
        return Opacity(opacity: t, child: child);
      },
      child: Container(
        width: widget.width == double.infinity ? null : widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

class _SrsHomeCard extends StatelessWidget {
  const _SrsHomeCard({required this.dueCount});

  final AsyncValue<int> dueCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.srsHomeTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            dueCount.when(
              data: (count) {
                if (count <= 0) {
                  return Text(l10n.srsAllDone);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.srsDueCount(count)),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.push(LevelRoutes.srs),
                      child: Text(l10n.srsStart),
                    ),
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text(l10n.loadError),
            ),
          ],
        ),
      ),
    );
  }
}
