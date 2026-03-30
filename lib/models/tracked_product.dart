import 'product.dart';

class TrackedProduct {
  final String id;
  final String userId;
  final Product product;
  final DateTime addedAt;
  final double? targetPrice;
  final List<PriceSnapshot> priceHistory;

  TrackedProduct({
    required this.id,
    required this.userId,
    required this.product,
    required this.addedAt,
    this.targetPrice,
    required this.priceHistory,
  });

  factory TrackedProduct.fromJson(Map<String, dynamic> json) {
    return TrackedProduct(
      id: json['id'] as String,
      userId: json['userId'] as String,
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      addedAt: DateTime.parse(json['addedAt'] as String),
      targetPrice: (json['targetPrice'] as num?)?.toDouble(),
      priceHistory:
          (json['priceHistory'] as List?)
              ?.map((e) => PriceSnapshot.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'product': product.toJson(),
      'addedAt': addedAt.toIso8601String(),
      'targetPrice': targetPrice,
      'priceHistory': priceHistory.map((e) => e.toJson()).toList(),
    };
  }
}

class PriceSnapshot {
  final double amazonPrice;
  final double flipkartPrice;
  final DateTime timestamp;

  PriceSnapshot({
    required this.amazonPrice,
    required this.flipkartPrice,
    required this.timestamp,
  });

  double get bestPrice =>
      amazonPrice < flipkartPrice ? amazonPrice : flipkartPrice;

  factory PriceSnapshot.fromJson(Map<String, dynamic> json) {
    return PriceSnapshot(
      amazonPrice: (json['amazonPrice'] as num).toDouble(),
      flipkartPrice: (json['flipkartPrice'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amazonPrice': amazonPrice,
      'flipkartPrice': flipkartPrice,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
