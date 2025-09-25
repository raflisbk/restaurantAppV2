import 'package:flutter/material.dart';
import '../models/api_response.dart';
import '../models/restaurant.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

class RestaurantProvider extends ChangeNotifier {
  ApiResponse<List<Restaurant>> _restaurantsState = ApiLoading();
  ApiService apiService = ApiService();

  ApiResponse<List<Restaurant>> get restaurantsState => _restaurantsState;

  List<Restaurant> get restaurants {
    if (_restaurantsState is ApiSuccess<List<Restaurant>>) {
      return (_restaurantsState as ApiSuccess<List<Restaurant>>).data;
    }
    return [];
  }

  bool get isLoading => _restaurantsState is ApiLoading;
  bool get hasError => _restaurantsState is ApiError;
  String get errorMessage {
    if (_restaurantsState is ApiError<List<Restaurant>>) {
      return (_restaurantsState as ApiError<List<Restaurant>>).message;
    }
    return '';
  }

  Future<void> fetchRestaurants({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await CacheService.getCachedRestaurantList();
      if (cached != null && cached.isNotEmpty) {
        _restaurantsState = ApiSuccess(cached);
        notifyListeners();
        return;
      }
    }

    _restaurantsState = ApiLoading();
    notifyListeners();

    final response = await apiService.getRestaurants();
    _restaurantsState = response;

    if (response is ApiSuccess<List<Restaurant>>) {
      await CacheService.cacheRestaurantList(response.data);
    }

    notifyListeners();
  }

  void clearError() {
    if (_restaurantsState is ApiError) {
      _restaurantsState = ApiSuccess([], message: 'Data cleared');
      notifyListeners();
    }
  }

  void sortRestaurants(String sortType) {
    if (_restaurantsState is ApiSuccess<List<Restaurant>>) {
      final restaurants =
          (_restaurantsState as ApiSuccess<List<Restaurant>>).data;
      switch (sortType) {
        case 'name_asc':
          restaurants.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'name_desc':
          restaurants.sort((a, b) => b.name.compareTo(a.name));
          break;
        case 'rating_desc':
          restaurants.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'rating_asc':
          restaurants.sort((a, b) => a.rating.compareTo(b.rating));
          break;
      }
      _restaurantsState = ApiSuccess(restaurants);
      notifyListeners();
    }
  }
}
