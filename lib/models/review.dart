class Review {
  final String name;
  final String review;
  final String date;

  Review({required this.name, required this.review, required this.date});

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      name: json['name'] ?? '',
      review: json['review'] ?? '',
      date: json['date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'review': review, 'date': date};
  }
}

class ReviewRequest {
  final String id;
  final String name;
  final String review;

  ReviewRequest({required this.id, required this.name, required this.review});

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'review': review};
  }
}
