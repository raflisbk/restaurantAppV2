import 'review.dart';

class Restaurant {
  final String id;
  final String name;
  final String description;
  final String pictureId;
  final String city;
  final double rating;
  final String? address;
  final List<String>? categories;
  final Menus? menus;
  final List<Review>? customerReviews;

  Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.pictureId,
    required this.city,
    required this.rating,
    this.address,
    this.categories,
    this.menus,
    this.customerReviews,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      pictureId: json['pictureId'] ?? '',
      city: json['city'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      address: json['address'],
      categories: json['categories'] != null
          ? List<String>.from(json['categories'].map((cat) => cat['name']))
          : null,
      menus: json['menus'] != null ? Menus.fromJson(json['menus']) : null,
      customerReviews: json['customerReviews'] != null
          ? List<Review>.from(
              json['customerReviews'].map((review) => Review.fromJson(review)),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'pictureId': pictureId,
      'city': city,
      'rating': rating,
      'address': address,
      'categories': categories,
      'menus': menus?.toJson(),
      'customerReviews': customerReviews
          ?.map((review) => review.toJson())
          .toList(),
    };
  }

  String get imageUrl =>
      'https://restaurant-api.dicoding.dev/images/medium/$pictureId';
}

class Menus {
  final List<MenuItem> foods;
  final List<MenuItem> drinks;

  Menus({required this.foods, required this.drinks});

  factory Menus.fromJson(Map<String, dynamic> json) {
    return Menus(
      foods: json['foods'] != null
          ? List<MenuItem>.from(
              json['foods'].map((item) => MenuItem.fromJson(item)),
            )
          : [],
      drinks: json['drinks'] != null
          ? List<MenuItem>.from(
              json['drinks'].map((item) => MenuItem.fromJson(item)),
            )
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foods': foods.map((item) => item.toJson()).toList(),
      'drinks': drinks.map((item) => item.toJson()).toList(),
    };
  }
}

class MenuItem {
  final String name;

  MenuItem({required this.name});

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(name: json['name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'name': name};
  }
}
