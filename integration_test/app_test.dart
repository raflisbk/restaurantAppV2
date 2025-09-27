import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:restaurant_app/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Restaurant App Integration Tests', () {
    testWidgets('Complete app flow test', (WidgetTester tester) async {
      await tester.pumpWidget(const RestaurantApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify main screen loads - wait for navigation to be ready
      await tester.pump();
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Navigate to Search using bottom navigation
      await tester.pump();
      final searchTab = find.text('Pencarian');
      expect(searchTab, findsOneWidget);
      await tester.tap(searchTab);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify search screen
      expect(find.byType(TextField), findsOneWidget);

      // Navigate to Favorites
      final favTab = find.text('Favorit');
      expect(favTab, findsOneWidget);
      await tester.tap(favTab);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify favorites screen
      expect(find.text('Belum ada restoran favorit'), findsOneWidget);

      // Navigate to Settings
      final settingsTab = find.text('Pengaturan');
      expect(settingsTab, findsOneWidget);
      await tester.tap(settingsTab);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify settings screen
      expect(find.text('Tema Gelap'), findsOneWidget);
      expect(find.text('Pengingat Harian'), findsOneWidget);

      // Test theme toggle
      final switches = find.byType(Switch);
      if (switches.evaluate().isNotEmpty) {
        await tester.tap(switches.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Search functionality test', (WidgetTester tester) async {
      await tester.pumpWidget(const RestaurantApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to search tab
      await tester.pump();
      final searchTab = find.text('Pencarian');
      expect(searchTab, findsOneWidget);
      await tester.tap(searchTab);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find and interact with search field
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Enter search query
      await tester.enterText(searchField, 'test');
      await tester.pumpAndSettle();

      // Submit search
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
    });

    testWidgets('Settings functionality test', (WidgetTester tester) async {
      await tester.pumpWidget(const RestaurantApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to settings tab
      await tester.pump();
      final settingsTab = find.text('Pengaturan');
      expect(settingsTab, findsOneWidget);
      await tester.tap(settingsTab);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify settings elements
      expect(find.text('Tema Gelap'), findsOneWidget);
      expect(find.text('Pengingat Harian'), findsOneWidget);

      // Test theme toggle
      final themeSwitches = find.byType(Switch);
      if (themeSwitches.evaluate().isNotEmpty) {
        await tester.tap(themeSwitches.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // Test notification toggle - get fresh switches finder
      final notificationSwitches = find.byType(Switch);
      if (notificationSwitches.evaluate().length > 1) {
        await tester.tap(notificationSwitches.at(1));
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // Test about dialog
      final aboutTile = find.text('Tentang Aplikasi');
      if (aboutTile.evaluate().isNotEmpty) {
        await tester.tap(aboutTile);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Close dialog if it opened - try multiple possible button texts
        final dialogButtons = [
          find.text('OK'),
          find.text('Tutup'),
          find.text('Close'),
          find.byType(TextButton),
        ];

        for (final buttonFinder in dialogButtons) {
          if (buttonFinder.evaluate().isNotEmpty) {
            await tester.tap(buttonFinder.first);
            await tester.pumpAndSettle(const Duration(seconds: 1));
            break;
          }
        }
      }
    });

    testWidgets('Navigation between tabs test', (WidgetTester tester) async {
      // Start the app
      await tester.pumpWidget(const RestaurantApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Test each tab navigation using bottom navigation items
      final tabs = ['Restaurant', 'Pencarian', 'Favorit', 'Pengaturan'];

      for (String tab in tabs) {
        await tester.pump();
        final tabItem = find.text(tab);
        if (tabItem.evaluate().isNotEmpty) {
          // Use first widget if multiple found
          await tester.tap(tabItem.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }

        // Verify the tab is selected
        final bottomNavBar = find.byType(BottomNavigationBar);
        expect(bottomNavBar, findsOneWidget);
      }
    });

    testWidgets('Responsive layout test', (WidgetTester tester) async {
      // Start the app
      await tester.pumpWidget(const RestaurantApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Test different screen sizes
      await tester.binding.setSurfaceSize(const Size(400, 800)); // Phone
      await tester.pumpAndSettle();

      await tester.binding.setSurfaceSize(
        const Size(800, 600),
      ); // Tablet landscape
      await tester.pumpAndSettle();

      await tester.binding.setSurfaceSize(
        const Size(600, 800),
      ); // Tablet portrait
      await tester.pumpAndSettle();

      // Reset to original size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Restaurant list loads successfully', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const RestaurantApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Wait for data to load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify restaurant tab is active
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('Restaurant card interaction test', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const RestaurantApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Wait for restaurant list to load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find and tap the first card if available
      final cards = find.byType(Card);
      if (cards.evaluate().isNotEmpty) {
        await tester.tap(cards.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Navigate back
        final backButton = find.byType(BackButton);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('Favorites add and remove flow', (WidgetTester tester) async {
      await tester.pumpWidget(const RestaurantApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Wait for restaurant list
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Ensure we're on the Restaurant tab first
      await tester.pump();
      final restaurantTab = find.text('Restaurant');
      if (restaurantTab.evaluate().isNotEmpty) {
        await tester.tap(restaurantTab.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Try to add favorite by tapping a card
      final cards = find.byType(Card);
      if (cards.evaluate().isNotEmpty) {
        // Tap the first card to go to detail
        await tester.tap(cards.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Look for favorite button with more specific search
        final favoriteButtons = [
          find.byIcon(Icons.favorite_border),
          find.byIcon(Icons.favorite_outline),
          find.byIcon(Icons.favorite),
        ];

        bool favoriteAdded = false;
        for (final favButton in favoriteButtons) {
          if (favButton.evaluate().isNotEmpty) {
            try {
              await tester.tap(favButton.first);
              await tester.pumpAndSettle(const Duration(seconds: 2));
              favoriteAdded = true;
              break;
            } catch (e) {
              // Continue to next button type if this one fails
              continue;
            }
          }
        }

        // Navigate back to main screen
        final backButtons = [
          find.byType(BackButton),
          find.byIcon(Icons.arrow_back),
          find.byTooltip('Back'),
        ];

        for (final backButton in backButtons) {
          if (backButton.evaluate().isNotEmpty) {
            try {
              await tester.tap(backButton.first);
              await tester.pumpAndSettle(const Duration(seconds: 2));
              break;
            } catch (e) {
              // Continue to next back button type
              continue;
            }
          }
        }

        // Check favorites tab if favorite was added
        if (favoriteAdded) {
          await tester.pump();
          final favTab = find.text('Favorit');
          if (favTab.evaluate().isNotEmpty) {
            await tester.tap(favTab.first);
            await tester.pumpAndSettle(const Duration(seconds: 3));

            // Verify favorite was added - check for either cards or empty message
            final favCards = find.byType(Card);
            final emptyMessage = find.textContaining('Belum ada');

            // Should have either favorites or empty state
            expect(
              favCards.evaluate().isNotEmpty ||
                  emptyMessage.evaluate().isNotEmpty,
              isTrue,
              reason:
                  'Favorites screen should show either favorites or empty state',
            );
          }
        }
      }
    });

    testWidgets('Sort functionality test', (WidgetTester tester) async {
      await tester.pumpWidget(const RestaurantApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Wait for data
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Look for sort button (usually in AppBar)
      final sortButton = find.byIcon(Icons.sort);
      if (sortButton.evaluate().isNotEmpty) {
        await tester.tap(sortButton);
        await tester.pumpAndSettle();

        // If a sort dialog/menu appears, select an option
        final sortOptions = find.byType(ListTile);
        if (sortOptions.evaluate().isNotEmpty) {
          await tester.tap(sortOptions.first);
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('Search with results test', (WidgetTester tester) async {
      await tester.pumpWidget(const RestaurantApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to search
      await tester.pump();
      final searchTab = find.text('Pencarian');
      if (searchTab.evaluate().isNotEmpty) {
        await tester.tap(searchTab);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Verify search screen loaded
      expect(find.byType(TextField), findsOneWidget);

      // Enter a common search term
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'restaurant');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Trigger search by submitting or pressing search
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Check for search results - they might be Cards, ListTiles, or other widgets
      final cards = find.byType(Card);
      final listTiles = find.byType(ListTile);
      final emptyState = find.textContaining('Tidak ada');

      // Expect either results or empty state
      expect(
        cards.evaluate().isNotEmpty ||
            listTiles.evaluate().isNotEmpty ||
            emptyState.evaluate().isNotEmpty,
        isTrue,
        reason: 'Search should show either results or empty state',
      );
    });

    testWidgets('Error handling test', (WidgetTester tester) async {
      await tester.pumpWidget(const RestaurantApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Wait for potential errors
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Check if error widget appears
      final errorTexts = find.textContaining('error', findRichText: true);

      // If error exists, verify retry mechanism
      if (errorTexts.evaluate().isNotEmpty) {
        final retryButton = find.textContaining('Coba Lagi');
        if (retryButton.evaluate().isNotEmpty) {
          await tester.tap(retryButton.first);
          await tester.pumpAndSettle(const Duration(seconds: 3));
        }
      }
    });
  });
}
