class Product {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double amazonPrice;
  final double flipkartPrice;
  final double rating;
  final int reviews;
  final DateTime updatedAt;
  final String category;

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

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
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
