import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Windows/Linux desktop has no native sqflite plugin; use FFI there.
void initDatabaseFactory() {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
