import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class PermissionRequestResult {
  const PermissionRequestResult({
    required this.microphoneGranted,
    required this.speechGranted,
  });

  final bool microphoneGranted;
  final bool speechGranted;

  bool get canUseStt => microphoneGranted && speechGranted;

  bool get canActivatePlayAndRecord => microphoneGranted;
}

class PermissionService {
  bool _askedThisSession = false;

  Future<PermissionRequestResult> requestInitialPermissions() async {
    if (_askedThisSession) {
      return status();
    }
    _askedThisSession = true;

    if (!(Platform.isAndroid || Platform.isIOS)) {
      return const PermissionRequestResult(
        microphoneGranted: true,
        speechGranted: true,
      );
    }

    final mic = await Permission.microphone.request();
    final speech = Platform.isIOS
        ? await Permission.speech.request()
        : mic;

    return PermissionRequestResult(
      microphoneGranted: mic.isGranted,
      speechGranted: speech.isGranted,
    );
  }

  Future<PermissionRequestResult> status() async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return const PermissionRequestResult(
        microphoneGranted: true,
        speechGranted: true,
      );
    }
    final mic = await Permission.microphone.status;
    final speech = Platform.isIOS
        ? await Permission.speech.status
        : mic;
    return PermissionRequestResult(
      microphoneGranted: mic.isGranted,
      speechGranted: speech.isGranted,
    );
  }
}
