import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseInit {
  static bool _initialized = false;

  /// Initialize database factory for the current platform
  static void initialize() {
    if (_initialized) return;

    if (kIsWeb) {
      // Web platform - SQLite is not supported
      debugPrint('Platform web terdeteksi, SQLite tidak didukung');
      return;
    }

    // Check if running on desktop platform
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Desktop platforms - use FFI
      debugPrint('Platform desktop terdeteksi, menginisialisasi SQLite FFI');
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    } else {
      // Mobile platforms (Android/iOS) - use default SQLite
      debugPrint('Platform mobile terdeteksi, menggunakan SQLite default');
    }

    _initialized = true;
    debugPrint('Database factory berhasil diinisialisasi');
  }

  /// Check if database is properly initialized
  static bool get isInitialized => _initialized;

  /// Get current platform info
  static String getPlatformInfo() {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isMacOS) return 'macOS';
    return 'Unknown';
  }
}
