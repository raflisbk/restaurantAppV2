import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurant_app/providers/restaurant_provider.dart';
import 'package:restaurant_app/services/api_service.dart';
import 'package:restaurant_app/models/api_response.dart';
import 'package:restaurant_app/models/restaurant.dart';

import 'restaurant_provider_test.mocks.dart';

@GenerateMocks([ApiService])
void main() {
  late RestaurantProvider provider;
  late MockApiService mockApiService;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    provideDummy<ApiResponse<List<Restaurant>>>(
      ApiSuccess<List<Restaurant>>([]),
    );
  });

  setUp(() {
    mockApiService = MockApiService();
    provider = RestaurantProvider();
  });

  group('RestaurantProvider Tests', () {
    test('initial state should be correct', () {
      expect(provider.restaurantsState, isA<ApiLoading>());
      expect(provider.restaurants, isEmpty);
      expect(provider.errorMessage, isEmpty);
    });

    test(
      'should return list of restaurants when API call is successful',
      () async {
        // Arrange
        final mockRestaurants = [
          Restaurant(
            id: '1',
            name: 'Test Restaurant 1',
            description: 'Test Description 1',
            pictureId: 'pic1',
            city: 'Test City 1',
            rating: 4.5,
          ),
          Restaurant(
            id: '2',
            name: 'Test Restaurant 2',
            description: 'Test Description 2',
            pictureId: 'pic2',
            city: 'Test City 2',
            rating: 4.0,
          ),
        ];

        final mockResponse = ApiSuccess(mockRestaurants, message: 'success');

        when(
          mockApiService.getRestaurants(),
        ).thenAnswer((_) async => mockResponse);

        // Act
        provider.apiService = mockApiService;
        await provider.fetchRestaurants(forceRefresh: true);

        // Assert
        expect(provider.restaurantsState, isA<ApiSuccess>());
        expect(provider.restaurants, hasLength(2));
        expect(provider.restaurants[0].name, 'Test Restaurant 1');
        expect(provider.restaurants[1].name, 'Test Restaurant 2');
        expect(provider.errorMessage, isEmpty);
        verify(mockApiService.getRestaurants()).called(1);
      },
    );

    test('should return error when API call fails', () async {
      // Arrange
      when(
        mockApiService.getRestaurants(),
      ).thenAnswer((_) async => ApiError('Network error'));

      // Act
      provider.apiService = mockApiService;
      await provider.fetchRestaurants(forceRefresh: true);

      // Assert
      expect(provider.restaurantsState, isA<ApiError>());
      expect(provider.restaurants, isEmpty);
      expect(provider.errorMessage, 'Network error');
      verify(mockApiService.getRestaurants()).called(1);
    });

    test('should handle empty restaurant list', () async {
      // Arrange
      final mockResponse = ApiSuccess<List<Restaurant>>([], message: 'success');

      when(
        mockApiService.getRestaurants(),
      ).thenAnswer((_) async => mockResponse);

      // Act
      provider.apiService = mockApiService;
      await provider.fetchRestaurants(forceRefresh: true);

      // Assert
      expect(provider.restaurantsState, isA<ApiSuccess>());
      expect(provider.restaurants, isEmpty);
      expect(provider.errorMessage, isEmpty);
      verify(mockApiService.getRestaurants()).called(1);
    });

    test('should handle API response with error flag', () async {
      // Arrange
      final mockResponse = ApiError<List<Restaurant>>('API Error');

      when(
        mockApiService.getRestaurants(),
      ).thenAnswer((_) async => mockResponse);

      // Act
      provider.apiService = mockApiService;
      await provider.fetchRestaurants(forceRefresh: true);

      // Assert
      expect(provider.restaurantsState, isA<ApiError>());
      expect(provider.restaurants, isEmpty);
      expect(provider.errorMessage, 'API Error');
      verify(mockApiService.getRestaurants()).called(1);
    });

    test('should update state correctly during loading', () async {
      // Arrange
      final mockResponse = ApiSuccess<List<Restaurant>>([
        Restaurant(
          id: '1',
          name: 'Test Restaurant',
          description: 'Test Description',
          pictureId: 'pic1',
          city: 'Test City',
          rating: 4.5,
        ),
      ], message: 'success');

      when(mockApiService.getRestaurants()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return mockResponse;
      });

      // Act & Assert
      provider.apiService = mockApiService;
      expect(provider.restaurantsState, isA<ApiLoading>());

      final future = provider.fetchRestaurants(forceRefresh: true);
      expect(provider.restaurantsState, isA<ApiLoading>());

      await future;
      expect(provider.restaurantsState, isA<ApiSuccess>());
      expect(provider.restaurants, hasLength(1));
    });
  });
}
