import 'dart:math';

class Product {
  final String id;
  final String name;
  final String category;
  final String description;
  final String imageUrl;
  final double amazonPrice;
  final double flipkartPrice;
  final double rating;
  final int reviews;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.amazonPrice,
    required this.flipkartPrice,
    required this.rating,
    required this.reviews,
    required this.updatedAt,
    this.category = 'General',
  });

  double get bestPrice =>
      amazonPrice < flipkartPrice ? amazonPrice : flipkartPrice;

  String get bestPlatform =>
      amazonPrice < flipkartPrice ? 'Amazon' : 'Flipkart';

  double get priceDifference => (amazonPrice - flipkartPrice).abs();

  double get savingsAmount => priceDifference;

  double get savingsPercentage {
    final reference = max(amazonPrice, flipkartPrice);
    if (reference <= 0) return 0.0;
    return (priceDifference / reference) * 100;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? 'General',
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      amazonPrice: (json['amazonPrice'] as num).toDouble(),
      flipkartPrice: (json['flipkartPrice'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      reviews: json['reviews'] as int,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      'amazonPrice': amazonPrice,
      'flipkartPrice': flipkartPrice,
      'rating': rating,
      'reviews': reviews,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
