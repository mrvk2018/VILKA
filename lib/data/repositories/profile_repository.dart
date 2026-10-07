import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../core/providers.dart';

class ProfileRepository {
  ProfileRepository(this._db);

  static const currentStudentId = 'current_student';
  static const localUserId = currentStudentId;
  static const defaultHomework =
      'Пройти первый аудиоурок и ознакомиться с фразами';

  final AppDatabase _db;
  late final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<bool> checkAuthStatus() async {
    final firebaseUser = _safeCurrentUser();
    if (firebaseUser == null) {
      return false;
    }
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM user_profile WHERE id = ?',
      [currentStudentId],
    );
    return (Sqflite.firstIntValue(result) ?? 0) > 0;
  }

  Future<void> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return;
      }
      final authentication = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: authentication.idToken,
        accessToken: authentication.accessToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw StateError('Firebase Google sign-in returned no user');
      }
      await _cacheFirebaseProfile(
        uid: user.uid,
        name: _googleDisplayName(user),
      );
    } catch (error) {
      if (_isAuthCanceled(error)) {
        return;
      }
      rethrow;
    }
  }

  Future<void> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final user = userCredential.user;
      if (user == null) {
        throw StateError('Firebase Apple sign-in returned no user');
      }
      await _cacheFirebaseProfile(
        uid: user.uid,
        name: _appleDisplayName(appleCredential, user),
      );
    } catch (error) {
      if (_isAuthCanceled(error)) {
        return;
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // Firebase may be uninitialized in local debug without native config.
    }
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Google Sign-In can be unavailable on desktop test hosts.
    }
    final db = await _db.database;
    await db.delete(
      'user_profile',
      where: 'id = ?',
      whereArgs: [currentStudentId],
    );
  }

  Future<Map<String, dynamic>?> getCachedProfile() async {
    final db = await _db.database;
    final rows = await db.query(
      'user_profile',
      where: 'id = ?',
      whereArgs: [currentStudentId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return Map<String, dynamic>.from(rows.first);
  }

  Future<void> _cacheFirebaseProfile({
    required String uid,
    required String name,
  }) async {
    final db = await _db.database;
    await db.insert(
      'user_profile',
      {
        'id': currentStudentId,
        'uid': uid,
        'name': name,
        'homework_task': defaultHomework,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  User? _safeCurrentUser() {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  String _googleDisplayName(User user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    final emailLocal = user.email?.split('@').first.trim();
    if (emailLocal != null && emailLocal.isNotEmpty) {
      return emailLocal;
    }
    return 'Ученик';
  }

  String _appleDisplayName(
    AuthorizationCredentialAppleID appleCredential,
    User user,
  ) {
    final parts = <String>[
      ?appleCredential.givenName?.trim(),
      ?appleCredential.familyName?.trim(),
    ].where((part) => part.isNotEmpty);
    final fromApple = parts.join(' ').trim();
    if (fromApple.isNotEmpty) {
      return fromApple;
    }
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    return 'Ученик Apple';
  }

  bool _isAuthCanceled(Object error) {
    if (error is SignInWithAppleAuthorizationException) {
      return error.code == AuthorizationErrorCode.canceled;
    }
    final text = error.toString().toLowerCase();
    return text.contains('cancel') ||
        text.contains('sign_in_canceled') ||
        text.contains('sign_in_cancelled');
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(appDatabaseProvider));
});
