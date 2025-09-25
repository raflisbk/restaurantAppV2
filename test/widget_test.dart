import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_app/widgets/restaurant_card.dart';
import 'package:restaurant_app/models/restaurant.dart';
import 'package:restaurant_app/screens/favorites_screen.dart';
import 'package:restaurant_app/providers/favorites_provider.dart';
import 'package:restaurant_app/main.dart';
import 'package:restaurant_app/utils/database_init.dart';

void main() {
  setUpAll(() {
    // Initialize database for testing
    DatabaseInit.initialize();
  });

  group('Widget Tests', () {
    testWidgets('Restaurant app smoke test', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const RestaurantApp());

      // Give time for the app to load
      await tester.pump();

      // Verify that the app loads with bottom navigation
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Verify bottom navigation items
      expect(find.text('Restaurant'), findsWidgets);
      expect(find.text('Pencarian'), findsOneWidget);
      expect(find.text('Favorit'), findsOneWidget);
      expect(find.text('Pengaturan'), findsOneWidget);
    });

    testWidgets('RestaurantCard displays restaurant information correctly', (
      WidgetTester tester,
    ) async {
      // Arrange
      final restaurant = Restaurant(
        id: '1',
        name: 'Test Restaurant',
        description: 'A great place to eat with amazing food and atmosphere',
        pictureId: 'test_pic',
        city: 'Test City',
        rating: 4.5,
      );

      bool tapped = false;

      // Act
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => FavoritesProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 300,
                width: 250,
                child: RestaurantCard(
                  restaurant: restaurant,
                  onTap: () => tapped = true,
                ),
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Test Restaurant'), findsOneWidget);
      expect(find.text('Test City'), findsOneWidget);
      expect(find.text('4.5'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);

      // Test tap functionality
      await tester.tap(find.byType(RestaurantCard));
      expect(tapped, isTrue);
    });

    testWidgets('FavoritesScreen shows empty state when no favorites', (
      WidgetTester tester,
    ) async {
      // Arrange
      final mockProvider = FavoritesProvider();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<FavoritesProvider>.value(
            value: mockProvider,
            child: const FavoritesScreen(),
          ),
        ),
      );

      // Wait for the async operations to complete
      await tester.pump();

      // Assert - Empty state should be shown
      expect(find.text('Belum ada restoran favorit'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(
        find.text('Tambahkan restoran ke favorit untuk melihatnya di sini'),
        findsOneWidget,
      );
    });

    testWidgets('Restaurant card handles long names correctly', (
      WidgetTester tester,
    ) async {
      // Arrange
      final restaurant = Restaurant(
        id: '1',
        name:
            'This is a very long restaurant name that should be handled properly by the UI',
        description: 'This is a very long description',
        pictureId: 'test_pic',
        city: 'Test City',
        rating: 4.8,
      );

      // Act
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => FavoritesProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 300,
                width: 250,
                child: RestaurantCard(restaurant: restaurant, onTap: () {}),
              ),
            ),
          ),
        ),
      );

      // Assert - Check that text is displayed without overflow
      expect(find.text(restaurant.name), findsOneWidget);
      expect(find.text(restaurant.city), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);

      // Verify no overflow
      expect(tester.takeException(), isNull);
    });
  });
}
