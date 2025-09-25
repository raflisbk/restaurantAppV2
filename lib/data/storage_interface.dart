import '../models/restaurant.dart';

/// Abstract interface for storage implementation
abstract class StorageInterface {
  Future<void> insertFavorite(Restaurant restaurant);
  Future<List<Restaurant>> getFavorites();
  Future<Restaurant?> getFavoriteById(String id);
  Future<void> removeFavorite(String id);
  Future<bool> isFavorite(String id);
  Future<void> initialize();
}
