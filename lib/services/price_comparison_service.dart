import 'dart:math';
import '../models/product.dart';
import 'amazon_service.dart';
import 'flipkart_service.dart';

class SavingsCalculation {
  final String cheapestPlatform;
  final double cheapestPrice;
  final double priceDifference;
  final double percentageSavings;

  const SavingsCalculation({
    required this.cheapestPlatform,
    required this.cheapestPrice,
    required this.priceDifference,
    required this.percentageSavings,
  });
}

class PriceComparisonService {
  Future<Product> comparePrice(String productId) async {
    final amazonFuture = amazonService.getCurrentPrice(productId);
    final flipkartFuture = flipkartService.getCurrentPrice(productId);

    final [amazonPrice, flipkartPrice] = await Future.wait([
      amazonFuture,
      flipkartFuture,
    ]);

    // Get product details from amazon
    final product = await amazonService.getProduct(productId);

    if (product == null) {
      throw Exception('Product not found');
    }

    return Product(
      id: product.id,
      name: product.name,
      category: product.category,
      description: product.description,
      imageUrl: product.imageUrl,
      amazonPrice: amazonPrice,
      flipkartPrice: flipkartPrice,
      rating: product.rating,
      reviews: product.reviews,
      updatedAt: DateTime.now(),
    );
  }

  Future<List<Product>> comparePriceForProducts(List<String> productIds) async {
    final futures = productIds.map((id) => comparePrice(id));
    return Future.wait(futures);
  }

  SavingsCalculation calculateSavings(Product product) {
    final cheapestPrice = min(product.amazonPrice, product.flipkartPrice);
    final highestPrice = max(product.amazonPrice, product.flipkartPrice);
    final difference = (highestPrice - cheapestPrice).abs();
    final savingsPercentage = highestPrice <= 0
        ? 0.0
        : (difference / highestPrice) * 100;

    return SavingsCalculation(
      cheapestPlatform: product.bestPlatform,
      cheapestPrice: cheapestPrice,
      priceDifference: difference,
      percentageSavings: savingsPercentage,
    );
  }
}

final priceComparisonService = PriceComparisonService();
