import 'dart:io';
import 'package:flutter/foundation.dart';
import 'storage_interface.dart';
import 'database_helper.dart';
import 'web_storage.dart';

/// Factory for creating appropriate storage based on platform
class StorageFactory {
  static StorageInterface? _instance;

  /// Get storage instance for current platform
  static StorageInterface getInstance() {
    if (_instance != null) return _instance!;

    if (kIsWeb) {
      // Web platform - use SharedPreferences
      debugPrint('Membuat web storage menggunakan SharedPreferences');
      _instance = WebStorage();
    } else if (Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isWindows ||
        Platform.isLinux ||
        Platform.isMacOS) {
      // Mobile/Desktop platforms - use SQLite
      debugPrint('Membuat SQLite storage untuk platform mobile/desktop');
      _instance = DatabaseHelper();
    } else {
      // Fallback to web storage
      debugPrint(
        'Platform tidak dikenal, menggunakan web storage sebagai fallback',
      );
      _instance = WebStorage();
    }

    return _instance!;
  }

  /// Initialize storage for current platform
  static Future<void> initialize() async {
    try {
      final storage = getInstance();
      await storage.initialize();
      debugPrint('Storage factory berhasil diinisialisasi');
    } catch (e) {
      debugPrint('Gagal menginisialisasi storage factory: $e');
      rethrow;
    }
  }

  /// Reset instance (for testing)
  static void reset() {
    _instance = null;
  }
}
