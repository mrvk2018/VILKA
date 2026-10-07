import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vilka/core/database/app_database.dart';
import 'package:vilka/data/repositories/profile_repository.dart';

void main() {
  late Database db;
  late ProfileRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS user_profile (
            id TEXT PRIMARY KEY,
            uid TEXT NOT NULL,
            name TEXT NOT NULL,
            homework_task TEXT,
            created_at INTEGER
          )
        ''');
      },
    );
    repository = ProfileRepository(AppDatabase(forTesting: db));
  });

  tearDown(() async {
    await db.close();
  });

  test('checkAuthStatus is false until Firebase and local cache agree', () async {
    expect(await repository.checkAuthStatus(), isFalse);
    expect(await repository.getCachedProfile(), isNull);

    await db.insert('user_profile', {
      'id': ProfileRepository.currentStudentId,
      'uid': 'firebase-uid',
      'name': 'Анна',
      'homework_task': ProfileRepository.defaultHomework,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });

    expect(await repository.getCachedProfile(), isNotNull);
    expect(
      (await repository.getCachedProfile())!['name'],
      'Анна',
    );
    expect(
      (await repository.getCachedProfile())!['homework_task'],
      ProfileRepository.defaultHomework,
    );
    expect(
      await repository.checkAuthStatus(),
      isFalse,
      reason: 'Local cache without Firebase currentUser is a desync',
    );
  });

  test('signOut deletes the current_student cache row', () async {
    await db.insert('user_profile', {
      'id': ProfileRepository.currentStudentId,
      'uid': 'firebase-uid',
      'name': 'Ученик Apple',
      'homework_task': ProfileRepository.defaultHomework,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    await repository.signOut();
    expect(await repository.getCachedProfile(), isNull);
  });
}
