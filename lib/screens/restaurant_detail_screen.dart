import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:readmore/readmore.dart';
import '../models/api_response.dart';
import '../models/review.dart';
import '../providers/restaurant_detail_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final String restaurantId;

  const RestaurantDetailScreen({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final _nameController = TextEditingController();
  final _reviewController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RestaurantDetailProvider>().fetchRestaurantDetail(
        widget.restaurantId,
      );
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<RestaurantDetailProvider>(
        builder: (context, provider, child) {
          return switch (provider.restaurantDetailState) {
            ApiLoading() => const Scaffold(
              body: LoadingWidget(message: 'Memuat detail restoran...'),
            ),
            ApiError() => Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: ErrorDisplayWidget(
                message: provider.errorMessage,
                onRetry: () =>
                    provider.fetchRestaurantDetail(widget.restaurantId),
              ),
            ),
            ApiSuccess() => _buildDetailContent(provider),
          };
        },
      ),
    );
  }

  Widget _buildDetailContent(RestaurantDetailProvider provider) {
    final restaurant = provider.restaurant!;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          actions: [
            Consumer<FavoritesProvider>(
              builder: (context, favoritesProvider, child) {
                return FutureBuilder<bool>(
                  future: favoritesProvider.isFavorite(widget.restaurantId),
                  builder: (context, snapshot) {
                    final isFavorite = snapshot.data ?? false;

                    return Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.white,
                        ),
                        onPressed: () async {
                          if (provider.restaurant != null) {
                            final restaurant = provider.restaurant!;
                            final messenger = ScaffoldMessenger.of(context);
                            final isDark =
                                Theme.of(context).brightness == Brightness.dark;
                            final wasJustFavorite = isFavorite;

                            await favoritesProvider.toggleFavorite(restaurant);

                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    !wasJustFavorite
                                        ? '${restaurant.name} ditambahkan ke favorit'
                                        : '${restaurant.name} dihapus dari favorit',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.grey[900],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: isDark
                                      ? Colors.grey[850]
                                      : Colors.grey[100],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Hero(
              tag: 'restaurant-image-${restaurant.id}',
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(restaurant.imageUrl),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {},
                  ),
                ),
                child: restaurant.imageUrl.isEmpty
                    ? Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.restaurant,
                          size: 64,
                          color: Colors.grey[600],
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRestaurantInfo(restaurant),
                const SizedBox(height: 32),
                _buildMenuSection(restaurant),
                const SizedBox(height: 32),
                _buildReviewSection(provider),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantInfo(restaurant) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              restaurant.name,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            // Rating and Location Row
            Row(
              children: [
                // Rating
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: Colors.amber[600],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        restaurant.rating.toString(),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Location
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${restaurant.city}${restaurant.address != null ? ', ${restaurant.address}' : ''}',
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Text(
              'Deskripsi',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ReadMoreText(
              restaurant.description,
              trimMode: TrimMode.Length,
              trimLength: 200,
              colorClickableText: Theme.of(context).colorScheme.primary,
              trimCollapsedText: 'Selengkapnya',
              trimExpandedText: ' Sembunyikan',
              moreStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
              lessStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(restaurant) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Menu',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            if (restaurant.menus != null) ...[
              _buildMenuCategory(
                'Makanan',
                restaurant.menus!.foods,
                Icons.restaurant,
                Colors.orange,
              ),
              const SizedBox(height: 24),
              _buildMenuCategory(
                'Minuman',
                restaurant.menus!.drinks,
                Icons.local_cafe,
                Colors.blue,
              ),
            ] else
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        size: 48,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[600]
                            : Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Menu tidak tersedia',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCategory(
    String title,
    List items,
    IconData icon,
    Color accentColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: accentColor),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${items.length} item${items.length > 1 ? 's' : ''}',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Menu Items Grid
        LayoutBuilder(
          builder: (context, constraints) {
            // Calculate cross axis count based on available width
            int crossAxisCount = 2;
            double itemWidth = 150;

            if (constraints.maxWidth > 320) {
              crossAxisCount = (constraints.maxWidth / itemWidth).floor().clamp(
                2,
                5,
              );
            }

            // Calculate proper aspect ratio to prevent overflow
            double aspectRatio = 0.85; // Height slightly less than width
            if (crossAxisCount > 3) {
              aspectRatio = 0.9;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: aspectRatio,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildMenuItem(item.name, accentColor);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem(String name, Color accentColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Generate a simple placeholder image based on menu item name
    final String placeholderImage = _getMenuItemImage(name);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder section
            Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accentColor.withValues(alpha: 0.1),
                    accentColor.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  placeholderImage,
                  style: TextStyle(fontSize: 24, color: accentColor),
                ),
              ),
            ),

            // Menu item name
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMenuItemImage(String menuName) {
    final name = menuName.toLowerCase();

    // Food emojis
    if (name.contains('nasi') || name.contains('rice')) return '🍚';
    if (name.contains('ayam') || name.contains('chicken')) return '🍗';
    if (name.contains('sapi') || name.contains('beef')) return '🥩';
    if (name.contains('ikan') || name.contains('fish')) return '🐟';
    if (name.contains('soto') || name.contains('soup')) return '🍲';
    if (name.contains('mie') || name.contains('noodle')) return '🍜';
    if (name.contains('sate') || name.contains('satay')) return '🍢';
    if (name.contains('gado') || name.contains('salad')) return '🥗';
    if (name.contains('bakso') || name.contains('meatball')) return '🍲';
    if (name.contains('pizza')) return '🍕';
    if (name.contains('burger')) return '🍔';
    if (name.contains('sandwich')) return '🥪';
    if (name.contains('pasta')) return '🍝';
    if (name.contains('roti') || name.contains('bread')) return '🍞';
    if (name.contains('cake') || name.contains('kue')) return '🍰';
    if (name.contains('ice') || name.contains('es')) return '🍨';

    // Drink emojis
    if (name.contains('kopi') || name.contains('coffee')) return '☕';
    if (name.contains('teh') || name.contains('tea')) return '🍵';
    if (name.contains('jus') || name.contains('juice')) return '🧃';
    if (name.contains('air') || name.contains('water')) return '💧';
    if (name.contains('soda') || name.contains('cola')) return '🥤';
    if (name.contains('susu') || name.contains('milk')) return '🥛';
    if (name.contains('smoothie')) return '🥤';
    if (name.contains('milkshake')) return '🥤';

    // Default based on first letter or random food/drink
    final firstChar = name.isNotEmpty ? name[0] : 'a';
    const foodEmojis = ['🍽️', '🥘', '🍱', '🥙', '🌮', '🥟', '🍤'];
    const drinkEmojis = ['🍹', '🍺', '🥂', '🍷', '🧊'];

    if (name.contains('minuman') ||
        name.contains('drink') ||
        name.contains('beverage')) {
      return drinkEmojis[firstChar.codeUnitAt(0) % drinkEmojis.length];
    }

    return foodEmojis[firstChar.codeUnitAt(0) % foodEmojis.length];
  }

  Color _generateAvatarColor(String name, bool isDark) {
    // Generate consistent color based on name hash
    final nameHash = name.toLowerCase().hashCode;

    // Predefined color palette with good contrast
    final lightColors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red
      const Color(0xFFEC4899), // Pink
      const Color(0xFF84CC16), // Lime
      const Color(0xFF6366F1), // Blue
      const Color(0xFF8B5CF6), // Purple
    ];

    final darkColors = [
      const Color(0xFF818CF8), // Light Indigo
      const Color(0xFFA78BFA), // Light Violet
      const Color(0xFF22D3EE), // Light Cyan
      const Color(0xFF34D399), // Light Emerald
      const Color(0xFFFBBF24), // Light Amber
      const Color(0xFFF87171), // Light Red
      const Color(0xFFF472B6), // Light Pink
      const Color(0xFFA3E635), // Light Lime
      const Color(0xFF60A5FA), // Light Blue
      const Color(0xFFC084FC), // Light Purple
    ];

    final colors = isDark ? darkColors : lightColors;
    return colors[nameHash.abs() % colors.length];
  }

  Color _getContrastingTextColor(Color backgroundColor) {
    // Calculate luminance to determine if we need light or dark text
    final luminance = backgroundColor.computeLuminance();

    // Use dark text for light backgrounds, light text for dark backgrounds
    if (luminance > 0.5) {
      return const Color(0xFF1F2937); // Dark gray
    } else {
      return Colors.white;
    }
  }

  Widget _buildReviewSection(RestaurantDetailProvider provider) {
    final restaurant = provider.restaurant!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Review',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddReviewDialog(provider),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Review'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (restaurant.customerReviews != null &&
                restaurant.customerReviews!.isNotEmpty)
              _buildCustomerReviews(restaurant.customerReviews!)
            else
              Text(
                'Belum ada review',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerReviews(List<Review> reviews) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reviews.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final review = reviews[index];
        final isDark = Theme.of(context).brightness == Brightness.dark;

        // Generate consistent color for each reviewer
        final avatarColor = _generateAvatarColor(review.name, isDark);
        final textColor = _getContrastingTextColor(avatarColor);

        return ListTile(
          leading: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [avatarColor, avatarColor.withValues(alpha: 0.8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: avatarColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: Colors.transparent,
              radius: 20,
              child: Text(
                review.name.isNotEmpty ? review.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          title: Text(
            review.name,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                review.review,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                review.date,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddReviewDialog(RestaurantDetailProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Review'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  hintText: 'Masukkan nama Anda',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reviewController,
                decoration: const InputDecoration(
                  labelText: 'Review',
                  hintText: 'Tulis review Anda',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Review tidak boleh kosong';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _nameController.clear();
              _reviewController.clear();
            },
            child: const Text('Batal'),
          ),
          Consumer<RestaurantDetailProvider>(
            builder: (context, detailProvider, child) {
              return ElevatedButton(
                onPressed: detailProvider.isAddingReview
                    ? null
                    : () => _submitReview(detailProvider),
                child: detailProvider.isAddingReview
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Kirim'),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _submitReview(RestaurantDetailProvider provider) async {
    if (_formKey.currentState!.validate()) {
      final success = await provider.addReview(
        widget.restaurantId,
        _nameController.text.trim(),
        _reviewController.text.trim(),
      );

      if (success && mounted) {
        Navigator.of(context).pop();
        _nameController.clear();
        _reviewController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Review berhasil ditambahkan',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.addReviewErrorMessage,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}
