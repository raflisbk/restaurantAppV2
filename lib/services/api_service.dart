import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import '../models/restaurant.dart';
import '../models/review.dart';

class ApiService {
  static const String _baseUrl = 'https://restaurant-api.dicoding.dev';
  static const Duration _timeout = Duration(seconds: 30);

  Future<ApiResponse<List<Restaurant>>> getRestaurants() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/list'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final restaurantResponse = RestaurantListResponse.fromJson(data);

        if (restaurantResponse.error) {
          return ApiError(restaurantResponse.message);
        }

        return ApiSuccess(
          restaurantResponse.restaurants,
          message: restaurantResponse.message,
        );
      } else {
        return ApiError(
          'Terjadi kesalahan pada server. Silakan coba lagi nanti.',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiError(
        'Tidak ada koneksi internet. Pastikan perangkat Anda terhubung ke internet.',
      );
    } on TimeoutException {
      return ApiError(
        'Koneksi timeout. Silakan periksa koneksi internet Anda dan coba lagi.',
      );
    } on HttpException {
      return ApiError(
        'Terjadi kesalahan saat mengakses server. Silakan coba lagi nanti.',
      );
    } on FormatException {
      return ApiError(
        'Data yang diterima tidak valid. Silakan coba lagi nanti.',
      );
    } on http.ClientException {
      return ApiError(
        'Tidak dapat terhubung ke server. Pastikan perangkat Anda terhubung ke internet.',
      );
    } catch (e) {
      return ApiError(
        'Terjadi kesalahan yang tidak terduga. Silakan coba lagi nanti.',
      );
    }
  }

  static Future<ApiResponse<List<Restaurant>>> getRestaurantsStatic() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/list'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final restaurantResponse = RestaurantListResponse.fromJson(data);

        if (restaurantResponse.error) {
          return ApiError(restaurantResponse.message);
        }

        return ApiSuccess(
          restaurantResponse.restaurants,
          message: restaurantResponse.message,
        );
      } else {
        return ApiError(
          'Terjadi kesalahan pada server. Silakan coba lagi nanti.',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiError(
        'Tidak ada koneksi internet. Pastikan perangkat Anda terhubung ke internet.',
      );
    } on TimeoutException {
      return ApiError(
        'Koneksi timeout. Silakan periksa koneksi internet Anda dan coba lagi.',
      );
    } on HttpException {
      return ApiError(
        'Terjadi kesalahan saat mengakses server. Silakan coba lagi nanti.',
      );
    } on FormatException {
      return ApiError(
        'Data yang diterima tidak valid. Silakan coba lagi nanti.',
      );
    } on http.ClientException {
      return ApiError(
        'Tidak dapat terhubung ke server. Pastikan perangkat Anda terhubung ke internet.',
      );
    } catch (e) {
      return ApiError(
        'Terjadi kesalahan yang tidak terduga. Silakan coba lagi nanti.',
      );
    }
  }

  static Future<ApiResponse<Restaurant>> getRestaurantDetail(String id) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/detail/$id'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final restaurantResponse = RestaurantDetailResponse.fromJson(data);

        if (restaurantResponse.error) {
          return ApiError(restaurantResponse.message);
        }

        return ApiSuccess(
          restaurantResponse.restaurant,
          message: restaurantResponse.message,
        );
      } else {
        return ApiError(
          'Terjadi kesalahan pada server. Silakan coba lagi nanti.',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiError(
        'Tidak ada koneksi internet. Pastikan perangkat Anda terhubung ke internet.',
      );
    } on TimeoutException {
      return ApiError(
        'Koneksi timeout. Silakan periksa koneksi internet Anda dan coba lagi.',
      );
    } on HttpException {
      return ApiError(
        'Terjadi kesalahan saat mengakses server. Silakan coba lagi nanti.',
      );
    } on FormatException {
      return ApiError(
        'Data yang diterima tidak valid. Silakan coba lagi nanti.',
      );
    } on http.ClientException {
      return ApiError(
        'Tidak dapat terhubung ke server. Pastikan perangkat Anda terhubung ke internet.',
      );
    } catch (e) {
      return ApiError(
        'Terjadi kesalahan yang tidak terduga. Silakan coba lagi nanti.',
      );
    }
  }

  static Future<ApiResponse<List<Restaurant>>> searchRestaurants(
    String query,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/search?q=$query'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final searchResponse = SearchResponse.fromJson(data);

        if (searchResponse.error) {
          return ApiError('Pencarian tidak ditemukan');
        }

        return ApiSuccess(searchResponse.restaurants);
      } else {
        return ApiError(
          'Terjadi kesalahan pada server. Silakan coba lagi nanti.',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiError(
        'Tidak ada koneksi internet. Pastikan perangkat Anda terhubung ke internet.',
      );
    } on TimeoutException {
      return ApiError(
        'Koneksi timeout. Silakan periksa koneksi internet Anda dan coba lagi.',
      );
    } on HttpException {
      return ApiError(
        'Terjadi kesalahan saat mengakses server. Silakan coba lagi nanti.',
      );
    } on FormatException {
      return ApiError(
        'Data yang diterima tidak valid. Silakan coba lagi nanti.',
      );
    } on http.ClientException {
      return ApiError(
        'Tidak dapat terhubung ke server. Pastikan perangkat Anda terhubung ke internet.',
      );
    } catch (e) {
      return ApiError(
        'Terjadi kesalahan yang tidak terduga. Silakan coba lagi nanti.',
      );
    }
  }

  static Future<ApiResponse<List<Review>>> addReview(
    ReviewRequest reviewRequest,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/review'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(reviewRequest.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final reviewResponse = ReviewResponse.fromJson(data);

        if (reviewResponse.error) {
          return ApiError(reviewResponse.message);
        }

        return ApiSuccess(
          reviewResponse.customerReviews,
          message: reviewResponse.message,
        );
      } else {
        return ApiError(
          'Gagal menambahkan review. Silakan coba lagi.',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiError(
        'Tidak ada koneksi internet. Pastikan perangkat Anda terhubung ke internet.',
      );
    } on TimeoutException {
      return ApiError(
        'Koneksi timeout. Silakan periksa koneksi internet Anda dan coba lagi.',
      );
    } on HttpException {
      return ApiError(
        'Terjadi kesalahan saat mengakses server. Silakan coba lagi nanti.',
      );
    } on FormatException {
      return ApiError(
        'Data yang diterima tidak valid. Silakan coba lagi nanti.',
      );
    } on http.ClientException {
      return ApiError(
        'Tidak dapat terhubung ke server. Pastikan perangkat Anda terhubung ke internet.',
      );
    } catch (e) {
      return ApiError(
        'Terjadi kesalahan yang tidak terduga. Silakan coba lagi nanti.',
      );
    }
  }
}
