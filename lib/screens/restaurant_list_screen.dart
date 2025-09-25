import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/api_response.dart';
import '../providers/restaurant_provider.dart';
import '../widgets/restaurant_card.dart';
import 'restaurant_detail_screen.dart';
import 'search_screen.dart';

class RestaurantListScreen extends StatefulWidget {
  final bool isInMainScreen;

  const RestaurantListScreen({super.key, this.isInMainScreen = false});

  @override
  State<RestaurantListScreen> createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends State<RestaurantListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RestaurantProvider>().fetchRestaurants();
    });
  }

  void _sortRestaurants(String sortType) {
    final provider = context.read<RestaurantProvider>();
    provider.sortRestaurants(sortType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.isInMainScreen
          ? AppBar(
              title: Text(
                'Restaurant',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.sort,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onSelected: (value) => _sortRestaurants(value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'name_asc',
                      child: Row(
                        children: [
                          Icon(Icons.sort_by_alpha),
                          SizedBox(width: 8),
                          Text('Nama A-Z'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'name_desc',
                      child: Row(
                        children: [
                          Icon(Icons.sort_by_alpha),
                          SizedBox(width: 8),
                          Text('Nama Z-A'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'rating_desc',
                      child: Row(
                        children: [
                          Icon(Icons.star),
                          SizedBox(width: 8),
                          Text('Rating Tertinggi'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'rating_asc',
                      child: Row(
                        children: [
                          Icon(Icons.star_outline),
                          SizedBox(width: 8),
                          Text('Rating Terendah'),
                        ],
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchScreen(),
                      ),
                    );
                  },
                ),
              ],
            )
          : AppBar(
              title: Text(
                'Restaurants',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              actions: [
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.sort,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onSelected: (value) => _sortRestaurants(value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'name_asc',
                      child: Row(
                        children: [
                          Icon(Icons.sort_by_alpha),
                          SizedBox(width: 8),
                          Text('Nama A-Z'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'name_desc',
                      child: Row(
                        children: [
                          Icon(Icons.sort_by_alpha),
                          SizedBox(width: 8),
                          Text('Nama Z-A'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'rating_desc',
                      child: Row(
                        children: [
                          Icon(Icons.star),
                          SizedBox(width: 8),
                          Text('Rating Tertinggi'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'rating_asc',
                      child: Row(
                        children: [
                          Icon(Icons.star_outline),
                          SizedBox(width: 8),
                          Text('Rating Terendah'),
                        ],
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
      body: Consumer<RestaurantProvider>(
        builder: (context, provider, child) {
          return switch (provider.restaurantsState) {
            ApiLoading() => Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            ApiError() => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.wifi_off,
                      size: 60,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[300],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Terjadi kesalahan',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      provider.errorMessage,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => provider.fetchRestaurants(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
            ApiSuccess() =>
              provider.restaurants.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[800]
                                  : Colors.grey[50],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.restaurant,
                              size: 60,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[300],
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Tidak ada restoran',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => provider.fetchRestaurants(),
                      color: Colors.grey[600],
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        itemCount: provider.restaurants.length,
                        itemBuilder: (context, index) {
                          final restaurant = provider.restaurants[index];
                          return RestaurantCard(
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
                          );
                        },
                      ),
                    ),
          };
        },
      ),
    );
  }
}
