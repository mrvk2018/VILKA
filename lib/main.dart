import 'package:audio_service/audio_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/database/database_init.dart';
import 'core/providers.dart';
import 'data/course/course_importer.dart';
import 'features/player/data/lesson_audio_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization info: $e');
  }
  initDatabaseFactory();
  late final LessonAudioHandler audioHandler;
  final container = ProviderContainer(
    overrides: [
      audioHandlerProvider.overrideWith((_) => audioHandler),
    ],
  );
  await CourseImporter(container.read(appDatabaseProvider)).importIfNeeded();
  audioHandler = await AudioService.init(
    builder: () => LessonAudioHandler(
      container.read(progressRepositoryProvider),
    ),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.vilka.teacher.channel.audio',
      androidNotificationChannelName: 'Vilka Audio Lesson',
      androidNotificationOngoing: true,
    ),
  );
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const VilkaApp(),
    ),
  );
}
