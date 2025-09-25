import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/restaurant.dart';
import 'storage_interface.dart';

/// Web-compatible storage using SharedPreferences
class WebStorage implements StorageInterface {
  static const String _favoritesKey = 'favorites_list';
  SharedPreferences? _prefs;

  @override
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      debugPrint(
        'Web storage berhasil diinisialisasi dengan SharedPreferences',
      );
    } catch (e) {
      debugPrint('Gagal menginisialisasi web storage: $e');
    }
  }

  @override
  Future<void> insertFavorite(Restaurant restaurant) async {
    try {
      final favorites = await getFavorites();

      // Remove if already exists to avoid duplicates
      favorites.removeWhere((r) => r.id == restaurant.id);

      // Add to beginning for better UX
      favorites.insert(0, restaurant);

      await _saveFavorites(favorites);
      debugPrint('Berhasil menambahkan ke web favorites: ${restaurant.name}');
    } catch (e) {
      debugPrint('Gagal menambahkan web favorite: $e');
      rethrow;
    }
  }

  @override
  Future<List<Restaurant>> getFavorites() async {
    try {
      if (_prefs == null) await initialize();

      final favoritesJson = _prefs?.getStringList(_favoritesKey) ?? [];
      final favorites = <Restaurant>[];

      for (final json in favoritesJson) {
        try {
          final map = jsonDecode(json) as Map<String, dynamic>;
          favorites.add(Restaurant.fromJson(map));
        } catch (e) {
          debugPrint('Melewati data favorit yang rusak: $e');
        }
      }

      return favorites;
    } catch (e) {
      debugPrint('Gagal memuat web favorites: $e');
      return [];
    }
  }

  @override
  Future<Restaurant?> getFavoriteById(String id) async {
    try {
      final favorites = await getFavorites();
      return favorites.where((r) => r.id == id).firstOrNull;
    } catch (e) {
      debugPrint('Gagal memuat web favorite berdasarkan ID: $e');
      return null;
    }
  }

  @override
  Future<void> removeFavorite(String id) async {
    try {
      final favorites = await getFavorites();
      favorites.removeWhere((r) => r.id == id);
      await _saveFavorites(favorites);
      debugPrint('Berhasil menghapus dari web favorites: $id');
    } catch (e) {
      debugPrint('Gagal menghapus web favorite: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isFavorite(String id) async {
    try {
      final favorites = await getFavorites();
      return favorites.any((r) => r.id == id);
    } catch (e) {
      debugPrint('Gagal memeriksa web favorite: $e');
      return false;
    }
  }

  Future<void> _saveFavorites(List<Restaurant> favorites) async {
    try {
      if (_prefs == null) await initialize();

      final favoritesJson = favorites
          .map((r) => jsonEncode(r.toJson()))
          .toList();

      await _prefs?.setStringList(_favoritesKey, favoritesJson);
    } catch (e) {
      debugPrint('Gagal menyimpan web favorites: $e');
      rethrow;
    }
  }
}
