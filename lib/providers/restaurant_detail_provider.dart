import 'package:flutter/material.dart';
import '../models/api_response.dart';
import '../models/restaurant.dart';
import '../models/review.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

class RestaurantDetailProvider extends ChangeNotifier {
  ApiResponse<Restaurant> _restaurantDetailState = ApiLoading();
  ApiResponse<Restaurant> get restaurantDetailState => _restaurantDetailState;

  Restaurant? get restaurant {
    if (_restaurantDetailState is ApiSuccess<Restaurant>) {
      return (_restaurantDetailState as ApiSuccess<Restaurant>).data;
    }
    return null;
  }

  bool get isLoading => _restaurantDetailState is ApiLoading;
  bool get hasError => _restaurantDetailState is ApiError;
  String get errorMessage {
    if (_restaurantDetailState is ApiError<Restaurant>) {
      return (_restaurantDetailState as ApiError<Restaurant>).message;
    }
    return '';
  }

  ApiResponse<List<Review>> _addReviewState = ApiSuccess([]);
  bool get isAddingReview => _addReviewState is ApiLoading;
  bool get hasAddReviewError => _addReviewState is ApiError;
  String get addReviewErrorMessage {
    if (_addReviewState is ApiError<List<Review>>) {
      return (_addReviewState as ApiError<List<Review>>).message;
    }
    return '';
  }

  Future<void> fetchRestaurantDetail(
    String id, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await CacheService.getCachedRestaurantDetail(id);
      if (cached != null) {
        _restaurantDetailState = ApiSuccess(cached);
        notifyListeners();
        return;
      }
    }

    _restaurantDetailState = ApiLoading();
    notifyListeners();

    final response = await ApiService.getRestaurantDetail(id);
    _restaurantDetailState = response;

    if (response is ApiSuccess<Restaurant>) {
      await CacheService.cacheRestaurantDetail(id, response.data);
    }

    notifyListeners();
  }

  Future<bool> addReview(
    String restaurantId,
    String name,
    String review,
  ) async {
    _addReviewState = ApiLoading();
    notifyListeners();

    final reviewRequest = ReviewRequest(
      id: restaurantId,
      name: name,
      review: review,
    );

    final response = await ApiService.addReview(reviewRequest);
    _addReviewState = response;

    if (response is ApiSuccess) {
      await fetchRestaurantDetail(restaurantId);
      notifyListeners();
      return true;
    } else {
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    if (_restaurantDetailState is ApiError) {
      _restaurantDetailState = ApiSuccess(
        Restaurant(
          id: '',
          name: '',
          description: '',
          pictureId: '',
          city: '',
          rating: 0.0,
        ),
        message: 'Data cleared',
      );
      notifyListeners();
    }
  }

  void clearAddReviewError() {
    if (_addReviewState is ApiError) {
      _addReviewState = ApiSuccess([]);
      notifyListeners();
    }
  }
}
