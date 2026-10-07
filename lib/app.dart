import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/providers.dart';
import 'data/repositories/profile_repository.dart';
import 'features/auth/presentation/welcome_screen.dart';
import 'features/exam/presentation/exam_screen.dart';
import 'features/hangul/hangul_alphabet_screen.dart';
import 'features/hangul/hangul_drawing_screen.dart';
import 'features/home/home_screen.dart';
import 'features/lesson/lesson_screen.dart';
import 'features/level/presentation/level_selection_screen.dart';
import 'features/phrases/phrases_screen.dart';
import 'features/player/presentation/player_screen.dart';
import 'features/srs/presentation/srs_screen.dart';
import 'features/topics/topics_screen.dart';
import 'l10n/generated/app_localizations.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    redirect: (context, state) async {
      final loggedIn =
          await ref.read(profileRepositoryProvider).checkAuthStatus();
      final isWelcome = state.matchedLocation == '/welcome';
      if (!loggedIn && !isWelcome) {
        return '/welcome';
      }
      if (loggedIn && isWelcome) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const LevelSelectionScreen(),
      ),
      GoRoute(
        path: '/level/0',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'srs',
            builder: (context, state) => const SrsScreen(),
          ),
          GoRoute(
            path: 'hangul',
            builder: (context, state) => const HangulAlphabetScreen(),
            routes: [
              GoRoute(
                path: 'draw/:letter',
                builder: (context, state) {
                  final letter = Uri.decodeComponent(
                    state.pathParameters['letter']!,
                  );
                  return HangulDrawingScreen(letter: letter);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'topics',
            builder: (context, state) => const TopicsScreen(),
            routes: [
              GoRoute(
                path: ':topicId',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['topicId']!);
                  return PhrasesScreen(topicId: id);
                },
                routes: [
                  GoRoute(
                    path: 'phrases/:phraseId',
                    builder: (context, state) {
                      final topicId =
                          int.parse(state.pathParameters['topicId']!);
                      final phraseId =
                          int.parse(state.pathParameters['phraseId']!);
                      return LessonScreen(
                        topicId: topicId,
                        phraseId: phraseId,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'player',
                    builder: (context, state) {
                      final topicId =
                          int.parse(state.pathParameters['topicId']!);
                      return PlayerScreen(topicId: topicId);
                    },
                  ),
                  GoRoute(
                    path: 'exam',
                    builder: (context, state) {
                      final topicId =
                          int.parse(state.pathParameters['topicId']!);
                      return ExamScreen(topicId: topicId);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class VilkaApp extends ConsumerWidget {
  const VilkaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(uiLocaleProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Vilka',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F4E5F),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      locale: Locale(locale.code),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
