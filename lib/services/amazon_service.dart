import 'dart:math';

import '../models/product.dart';
import 'local_product_database_service.dart';

class AmazonService {
  final Random _random = Random();

  Future<List<Product>> searchProducts(String query) async {
    await _simulateApiDelay();
    final products = localProductDatabaseService.searchProducts(query);
    return products.map((product) => product.toProduct()).toList();
  }

  Future<Product?> getProduct(String productId) async {
    await _simulateApiDelay();
    return localProductDatabaseService.getProductById(productId)?.toProduct();
  }

  Future<double> getCurrentPrice(String productId) async {
    await _simulateApiDelay();
    return localProductDatabaseService.getProductById(productId)?.currentAmazonPrice ??
        0.0;
  }

  List<double> getPriceHistory(String productId) {
    return localProductDatabaseService.getAmazonPriceHistory(productId);
  }

  Future<String> askAssistant(Product product, String userMessage) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final input = userMessage.trim().toLowerCase();

    if (input.isEmpty) {
      return 'Ask me about price trend, best platform, or expected savings for this product.';
    }

    final bestPlatform = product.bestPlatform;
    final savings = product.savingsAmount.round();
    final trendHint = product.amazonPrice <= product.flipkartPrice
        ? 'Amazon currently has the better value.'
        : 'Flipkart currently has the better value.';

    return 'For ${product.name}, the best price right now is on $bestPlatform. '
        'You can save around Rs $savings compared to the higher platform price. '
        '$trendHint';
  }

  Future<void> _simulateApiDelay() async {
    final delayMs = 1000 + _random.nextInt(1001);
    await Future.delayed(Duration(milliseconds: delayMs));
  }
}

final amazonService = AmazonService();
