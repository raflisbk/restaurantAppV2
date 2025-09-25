import 'restaurant.dart';
import 'review.dart';

sealed class ApiResponse<T> {}

class ApiLoading<T> extends ApiResponse<T> {}

class ApiSuccess<T> extends ApiResponse<T> {
  final T data;
  final String? message;

  ApiSuccess(this.data, {this.message});
}

class ApiError<T> extends ApiResponse<T> {
  final String message;
  final int? statusCode;

  ApiError(this.message, {this.statusCode});
}

class RestaurantListResponse {
  final bool error;
  final String message;
  final int count;
  final List<Restaurant> restaurants;

  RestaurantListResponse({
    required this.error,
    required this.message,
    required this.count,
    required this.restaurants,
  });

  factory RestaurantListResponse.fromJson(Map<String, dynamic> json) {
    return RestaurantListResponse(
      error: json['error'] ?? false,
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      restaurants: json['restaurants'] != null
          ? List<Restaurant>.from(
              json['restaurants'].map((item) => Restaurant.fromJson(item)),
            )
          : [],
    );
  }
}

class RestaurantDetailResponse {
  final bool error;
  final String message;
  final Restaurant restaurant;

  RestaurantDetailResponse({
    required this.error,
    required this.message,
    required this.restaurant,
  });

  factory RestaurantDetailResponse.fromJson(Map<String, dynamic> json) {
    return RestaurantDetailResponse(
      error: json['error'] ?? false,
      message: json['message'] ?? '',
      restaurant: Restaurant.fromJson(json['restaurant']),
    );
  }
}

class SearchResponse {
  final bool error;
  final int founded;
  final List<Restaurant> restaurants;

  SearchResponse({
    required this.error,
    required this.founded,
    required this.restaurants,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      error: json['error'] ?? false,
      founded: json['founded'] ?? 0,
      restaurants: json['restaurants'] != null
          ? List<Restaurant>.from(
              json['restaurants'].map((item) => Restaurant.fromJson(item)),
            )
          : [],
    );
  }
}

class ReviewResponse {
  final bool error;
  final String message;
  final List<Review> customerReviews;

  ReviewResponse({
    required this.error,
    required this.message,
    required this.customerReviews,
  });

  factory ReviewResponse.fromJson(Map<String, dynamic> json) {
    return ReviewResponse(
      error: json['error'] ?? false,
      message: json['message'] ?? '',
      customerReviews: json['customerReviews'] != null
          ? List<Review>.from(
              json['customerReviews'].map((item) => Review.fromJson(item)),
            )
          : [],
    );
  }
}
