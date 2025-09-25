import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/restaurant.dart';

class CacheService {
  static const String _restaurantListKey = 'cached_restaurant_list';
  static const String _restaurantListTimestampKey =
      'cached_restaurant_list_timestamp';
  static const String _restaurantDetailPrefix = 'cached_restaurant_detail_';
  static const String _searchPrefix = 'cached_search_';

  static const Duration _cacheDuration = Duration(minutes: 15);

  static Future<void> cacheRestaurantList(List<Restaurant> restaurants) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = restaurants.map((r) => r.toJson()).toList();
    await prefs.setString(_restaurantListKey, json.encode(jsonList));
    await prefs.setInt(
      _restaurantListTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<List<Restaurant>?> getCachedRestaurantList() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_restaurantListTimestampKey);

    if (timestamp == null) return null;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (DateTime.now().difference(cacheTime) > _cacheDuration) {
      await clearRestaurantListCache();
      return null;
    }

    final jsonString = prefs.getString(_restaurantListKey);
    if (jsonString == null) return null;

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => Restaurant.fromJson(json)).toList();
  }

  static Future<void> clearRestaurantListCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_restaurantListKey);
    await prefs.remove(_restaurantListTimestampKey);
  }

  static Future<void> cacheRestaurantDetail(
    String id,
    Restaurant restaurant,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_restaurantDetailPrefix$id';
    final timestampKey = '${key}_timestamp';

    await prefs.setString(key, json.encode(restaurant.toJson()));
    await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<Restaurant?> getCachedRestaurantDetail(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_restaurantDetailPrefix$id';
    final timestampKey = '${key}_timestamp';

    final timestamp = prefs.getInt(timestampKey);
    if (timestamp == null) return null;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (DateTime.now().difference(cacheTime) > _cacheDuration) {
      await clearRestaurantDetailCache(id);
      return null;
    }

    final jsonString = prefs.getString(key);
    if (jsonString == null) return null;

    return Restaurant.fromJson(json.decode(jsonString));
  }

  static Future<void> clearRestaurantDetailCache(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_restaurantDetailPrefix$id';
    final timestampKey = '${key}_timestamp';

    await prefs.remove(key);
    await prefs.remove(timestampKey);
  }

  static Future<void> cacheSearchResults(
    String query,
    List<Restaurant> restaurants,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_searchPrefix${query.toLowerCase()}';
    final timestampKey = '${key}_timestamp';

    final jsonList = restaurants.map((r) => r.toJson()).toList();
    await prefs.setString(key, json.encode(jsonList));
    await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<List<Restaurant>?> getCachedSearchResults(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_searchPrefix${query.toLowerCase()}';
    final timestampKey = '${key}_timestamp';

    final timestamp = prefs.getInt(timestampKey);
    if (timestamp == null) return null;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (DateTime.now().difference(cacheTime) > _cacheDuration) {
      await clearSearchCache(query);
      return null;
    }

    final jsonString = prefs.getString(key);
    if (jsonString == null) return null;

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => Restaurant.fromJson(json)).toList();
  }

  static Future<void> clearSearchCache(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_searchPrefix${query.toLowerCase()}';
    final timestampKey = '${key}_timestamp';

    await prefs.remove(key);
    await prefs.remove(timestampKey);
  }

  static Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    for (final key in keys) {
      if (key.startsWith(_restaurantDetailPrefix) ||
          key.startsWith(_searchPrefix) ||
          key == _restaurantListKey ||
          key == _restaurantListTimestampKey) {
        await prefs.remove(key);
      }
    }
  }
}
