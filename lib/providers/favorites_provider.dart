import 'package:flutter/foundation.dart';
import '../data/storage_factory.dart';
import '../data/storage_interface.dart';
import '../models/restaurant.dart';

class FavoritesProvider extends ChangeNotifier {
  late final StorageInterface _storage;
  bool _initialized = false;

  List<Restaurant> _favorites = [];
  bool _isLoading = false;
  String _message = '';

  List<Restaurant> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String get message => _message;

  FavoritesProvider() {
    _storage = StorageFactory.getInstance();
    _ensureInitialized();
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    try {
      await _storage.initialize();
      _initialized = true;
      debugPrint('FavoritesProvider berhasil diinisialisasi');
    } catch (e) {
      debugPrint('Gagal menginisialisasi FavoritesProvider: $e');
    }
  }

  Future<void> getFavorites() async {
    await _ensureInitialized();

    _isLoading = true;
    notifyListeners();

    try {
      _favorites = await _storage.getFavorites();
      _message = _favorites.isEmpty ? 'Belum ada restoran favorit' : '';
    } catch (e) {
      _message = 'Gagal memuat daftar favorit: $e';
      debugPrint('Gagal memuat daftar favorit: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addFavorite(Restaurant restaurant) async {
    await _ensureInitialized();

    try {
      await _storage.insertFavorite(restaurant);

      // Optimized: Add to local list instead of full reload
      _favorites.removeWhere((r) => r.id == restaurant.id);
      _favorites.insert(0, restaurant);

      _message = '${restaurant.name} ditambahkan ke favorit';
      debugPrint('Berhasil menambahkan ke favorit: ${restaurant.name}');
      notifyListeners();
      return true;
    } catch (e) {
      _message = 'Gagal menambahkan ke favorit: $e';
      debugPrint('Gagal menambahkan ke favorit: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeFavorite(String restaurantId) async {
    await _ensureInitialized();

    try {
      await _storage.removeFavorite(restaurantId);

      // Optimized: Remove from local list instead of full reload
      _favorites.removeWhere((r) => r.id == restaurantId);

      _message = 'Dihapus dari favorit';
      debugPrint('Berhasil menghapus dari favorit: $restaurantId');
      notifyListeners();
      return true;
    } catch (e) {
      _message = 'Gagal menghapus dari favorit: $e';
      debugPrint('Gagal menghapus dari favorit: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> isFavorite(String restaurantId) async {
    await _ensureInitialized();

    try {
      // Optimized: Check local list first before storage
      if (_favorites.any((r) => r.id == restaurantId)) {
        return true;
      }
      return await _storage.isFavorite(restaurantId);
    } catch (e) {
      debugPrint('Gagal memeriksa status favorit: $e');
      return false;
    }
  }

  Future<void> toggleFavorite(Restaurant restaurant) async {
    final isFav = await isFavorite(restaurant.id);
    if (isFav) {
      await removeFavorite(restaurant.id);
    } else {
      await addFavorite(restaurant);
    }
    // Auto refresh the favorites list after toggle
    await getFavorites();
  }

  void sortFavorites(String sortType) {
    switch (sortType) {
      case 'name_asc':
        _favorites.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'name_desc':
        _favorites.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'rating_desc':
        _favorites.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'rating_asc':
        _favorites.sort((a, b) => a.rating.compareTo(b.rating));
        break;
    }
    notifyListeners();
  }
}
