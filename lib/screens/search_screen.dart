import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/api_response.dart';
import '../providers/search_provider.dart';
import '../widgets/restaurant_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import 'restaurant_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 500);

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cari Restoran')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Consumer<SearchProvider>(
              builder: (context, provider, child) {
                return TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari restoran...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: provider.lastQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              context.read<SearchProvider>().clearSearch();
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    _debouncer.run(() {
                      if (value.trim().isNotEmpty) {
                        context.read<SearchProvider>().searchRestaurants(
                          value.trim(),
                        );
                      } else {
                        context.read<SearchProvider>().clearSearch();
                      }
                    });
                  },
                );
              },
            ),
          ),
          Expanded(
            child: Consumer<SearchProvider>(
              builder: (context, provider, child) {
                return switch (provider.searchState) {
                  ApiLoading() => const LoadingWidget(
                    message: 'Mencari restoran...',
                  ),
                  ApiError() => ErrorDisplayWidget(
                    message: provider.errorMessage,
                    onRetry: () =>
                        provider.searchRestaurants(provider.lastQuery),
                    icon: Icons.search_off,
                  ),
                  ApiSuccess() =>
                    provider.searchResults.isEmpty
                        ? _buildEmptyState(provider.lastQuery)
                        : _buildSearchResults(provider.searchResults),
                };
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String query) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Mulai cari restoran favoritmu',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    } else {
      return ErrorDisplayWidget(
        message: 'Tidak ada restoran dengan kata kunci "$query"',
        icon: Icons.search_off,
      );
    }
  }

  Widget _buildSearchResults(List restaurants) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive grid dimensions
        const double minItemWidth = 280.0;
        const double maxItemWidth = 400.0;
        const double spacing = 16.0;

        // Calculate available width for items (excluding padding and spacing)
        final availableWidth =
            constraints.maxWidth - (2 * 24); // 24px padding on each side

        // Calculate optimal number of columns
        int crossAxisCount = 1;
        if (availableWidth >= minItemWidth) {
          crossAxisCount =
              ((availableWidth + spacing) / (minItemWidth + spacing)).floor();
          crossAxisCount = crossAxisCount.clamp(1, 4); // Max 4 columns
        }

        // Calculate actual item width
        final itemWidth =
            (availableWidth - (spacing * (crossAxisCount - 1))) /
            crossAxisCount;

        // Calculate aspect ratio to prevent overflow
        // Adjust based on content height needs
        double childAspectRatio = 0.75;
        if (itemWidth < 300) {
          childAspectRatio = 0.8; // Slightly taller for narrow items
        } else if (itemWidth > 350) {
          childAspectRatio = 0.7; // Slightly shorter for wider items
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                ),
                itemCount: restaurants.length,
                itemBuilder: (context, index) {
                  final restaurant = restaurants[index];
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxItemWidth,
                      minWidth: minItemWidth.clamp(0, itemWidth),
                    ),
                    child: RestaurantCard(
                      restaurant: restaurant,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RestaurantDetailScreen(
                              restaurantId: restaurant.id,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              // Add some bottom padding for better UX
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
