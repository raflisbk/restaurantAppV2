import 'package:flutter/material.dart';
import '../models/api_response.dart';
import '../models/restaurant.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

class SearchProvider extends ChangeNotifier {
  ApiResponse<List<Restaurant>> _searchState = ApiSuccess([]);
  ApiResponse<List<Restaurant>> get searchState => _searchState;

  List<Restaurant> get searchResults {
    if (_searchState is ApiSuccess<List<Restaurant>>) {
      return (_searchState as ApiSuccess<List<Restaurant>>).data;
    }
    return [];
  }

  bool get isLoading => _searchState is ApiLoading;
  bool get hasError => _searchState is ApiError;
  String get errorMessage {
    if (_searchState is ApiError<List<Restaurant>>) {
      return (_searchState as ApiError<List<Restaurant>>).message;
    }
    return '';
  }

  String _lastQuery = '';
  String get lastQuery => _lastQuery;

  Future<void> searchRestaurants(
    String query, {
    bool forceRefresh = false,
  }) async {
    if (query.trim().isEmpty) {
      _searchState = ApiSuccess([]);
      _lastQuery = '';
      notifyListeners();
      return;
    }

    _lastQuery = query;

    if (!forceRefresh) {
      final cached = await CacheService.getCachedSearchResults(query);
      if (cached != null) {
        _searchState = ApiSuccess(cached);
        notifyListeners();
        return;
      }
    }

    _searchState = ApiLoading();
    notifyListeners();

    final response = await ApiService.searchRestaurants(query);
    _searchState = response;

    if (response is ApiSuccess<List<Restaurant>>) {
      await CacheService.cacheSearchResults(query, response.data);
    }

    notifyListeners();
  }

  void clearSearch() {
    _searchState = ApiSuccess([]);
    _lastQuery = '';
    notifyListeners();
  }

  void clearError() {
    if (_searchState is ApiError) {
      _searchState = ApiSuccess([]);
      notifyListeners();
    }
  }
}
