import 'product.dart';

class SimulatedProduct {
  final String id;
  final String name;
  final String category;
  final String description;
  final String imageUrl;
  final double rating;
  final int reviews;
  final List<double> amazonPriceHistory;
  final List<double> flipkartPriceHistory;
  final DateTime lastUpdated;

  const SimulatedProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.reviews,
    required this.amazonPriceHistory,
    required this.flipkartPriceHistory,
    required this.lastUpdated,
  });

  double get currentAmazonPrice =>
      amazonPriceHistory.isEmpty ? 0.0 : amazonPriceHistory.last;

  double get currentFlipkartPrice =>
      flipkartPriceHistory.isEmpty ? 0.0 : flipkartPriceHistory.last;

  Product toProduct() {
    return Product(
      id: id,
      name: name,
      category: category,
      description: description,
      imageUrl: imageUrl,
      amazonPrice: currentAmazonPrice,
      flipkartPrice: currentFlipkartPrice,
      rating: rating,
      reviews: reviews,
      updatedAt: lastUpdated,
    );
  }

  SimulatedProduct copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    String? imageUrl,
    double? rating,
    int? reviews,
    List<double>? amazonPriceHistory,
    List<double>? flipkartPriceHistory,
    DateTime? lastUpdated,
  }) {
    return SimulatedProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      amazonPriceHistory: amazonPriceHistory ?? this.amazonPriceHistory,
      flipkartPriceHistory: flipkartPriceHistory ?? this.flipkartPriceHistory,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
