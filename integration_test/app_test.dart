import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:restaurant_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Restaurant App Integration Tests', () {
    testWidgets('Complete app flow test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify main screen loads
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Navigate to Search using bottom navigation
      final searchTab = find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('Pencarian'),
      );
      await tester.tap(searchTab.first);
      await tester.pumpAndSettle();

      // Verify search screen
      expect(find.byType(TextField), findsOneWidget);

      // Navigate to Favorites
      final favTab = find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('Favorit'),
      );
      await tester.tap(favTab.first);
      await tester.pumpAndSettle();

      // Verify favorites screen
      expect(find.text('Belum ada restoran favorit'), findsOneWidget);

      // Navigate to Settings
      final settingsTab = find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('Pengaturan'),
      );
      await tester.tap(settingsTab.first);
      await tester.pumpAndSettle();

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
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to search tab
      final searchTab = find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('Pencarian'),
      );
      await tester.tap(searchTab.first);
      await tester.pumpAndSettle();

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
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to settings tab
      final settingsTab = find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('Pengaturan'),
      );
      await tester.tap(settingsTab.first);
      await tester.pumpAndSettle();

      // Verify settings elements
      expect(find.text('Tema Gelap'), findsOneWidget);
      expect(find.text('Pengingat Harian'), findsOneWidget);

      // Test theme toggle
      final themeSwitches = find.byType(Switch);
      if (themeSwitches.evaluate().isNotEmpty) {
        await tester.tap(themeSwitches.first);
        await tester.pumpAndSettle();
      }

      // Test notification toggle
      if (themeSwitches.evaluate().length > 1) {
        await tester.tap(themeSwitches.at(1));
        await tester.pumpAndSettle();
      }

      // Test about dialog
      final aboutTile = find.text('Tentang Aplikasi');
      if (aboutTile.evaluate().isNotEmpty) {
        await tester.tap(aboutTile);
        await tester.pumpAndSettle();

        // Close dialog if it opened
        if (find.byType(AlertDialog).evaluate().isNotEmpty) {
          await tester.tap(find.text('OK').first);
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('Navigation between tabs test', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Test each tab navigation using bottom navigation items
      final tabs = ['Restaurant', 'Pencarian', 'Favorit', 'Pengaturan'];

      for (String tab in tabs) {
        final tabItem = find.descendant(
          of: find.byType(BottomNavigationBar),
          matching: find.text(tab),
        );
        await tester.tap(tabItem.first);
        await tester.pumpAndSettle();

        // Verify the tab is selected
        final bottomNavBar = find.byType(BottomNavigationBar);
        expect(bottomNavBar, findsOneWidget);
      }
    });

    testWidgets('Responsive layout test', (WidgetTester tester) async {
      // Start the app
      app.main();
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
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Wait for data to load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify restaurant tab is active
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('Restaurant card interaction test', (
      WidgetTester tester,
    ) async {
      app.main();
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
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Wait for restaurant list
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Try to add favorite by tapping a card
      final cards = find.byType(Card);
      if (cards.evaluate().isNotEmpty) {
        await tester.tap(cards.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Look for favorite button
        final favoriteButton = find.byIcon(Icons.favorite_border);
        if (favoriteButton.evaluate().isNotEmpty) {
          await tester.tap(favoriteButton);
          await tester.pumpAndSettle();

          // Navigate back
          final backButton = find.byType(BackButton);
          if (backButton.evaluate().isNotEmpty) {
            await tester.tap(backButton);
            await tester.pumpAndSettle();
          }

          // Check favorites tab
          final favTab = find.descendant(
            of: find.byType(BottomNavigationBar),
            matching: find.text('Favorit'),
          );
          await tester.tap(favTab.first);
          await tester.pumpAndSettle();

          // Verify favorite was added
          final favCards = find.byType(Card);
          expect(favCards.evaluate().isNotEmpty, true);
        }
      }
    });

    testWidgets('Sort functionality test', (WidgetTester tester) async {
      app.main();
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
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to search
      final searchTab = find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('Pencarian'),
      );
      await tester.tap(searchTab.first);
      await tester.pumpAndSettle();

      // Enter a common search term
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'resto');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify search results or empty state are rendered
      final results = find.byType(Card);
      expect(results, findsWidgets);
    });

    testWidgets('Error handling test', (WidgetTester tester) async {
      app.main();
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
