import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../data/database_helper.dart';
import 'database_init.dart';

class DatabaseDebug {
  static final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// Print all favorites in database to console
  static Future<void> printAllFavorites() async {
    try {
      final favorites = await _databaseHelper.getFavorites();
      debugPrint('=== FAVORIT DATABASE (${favorites.length} item) ===');

      if (favorites.isEmpty) {
        debugPrint('Tidak ada favorit yang ditemukan di database');
      } else {
        for (int i = 0; i < favorites.length; i++) {
          final restaurant = favorites[i];
          debugPrint('[$i] ID: ${restaurant.id}');
          debugPrint('    Nama: ${restaurant.name}');
          debugPrint('    Kota: ${restaurant.city}');
          debugPrint('    Rating: ${restaurant.rating}');
          debugPrint('    ---------------');
        }
      }
      debugPrint('=== AKHIR FAVORIT DATABASE ===');
    } catch (e) {
      debugPrint('Gagal membaca favorit dari database: $e');
    }
  }

  /// Get database file path
  static Future<String> getDatabasePath() async {
    final path = await getDatabasesPath();
    return '$path/restaurant.db';
  }

  /// Print database info
  static Future<void> printDatabaseInfo() async {
    try {
      final path = await getDatabasePath();
      debugPrint('=== INFO DATABASE ===');
      debugPrint('Platform: ${DatabaseInit.getPlatformInfo()}');
      debugPrint('Database Terinisialisasi: ${DatabaseInit.isInitialized}');
      debugPrint('Path database: $path');
      debugPrint('Tabel: favorites');
      debugPrint('Skema: id, name, description, pictureId, city, rating');
      debugPrint('====================');
    } catch (e) {
      debugPrint('Gagal mendapatkan info database: $e');
    }
  }

  /// Check if specific restaurant is in favorites
  static Future<void> checkRestaurantFavorite(String restaurantId) async {
    try {
      final isFav = await _databaseHelper.isFavorite(restaurantId);
      debugPrint(
        'Restoran ID $restaurantId ${isFav ? 'ADA' : 'TIDAK ADA'} di favorit',
      );
    } catch (e) {
      debugPrint('Gagal memeriksa favorit restoran: $e');
    }
  }
}
