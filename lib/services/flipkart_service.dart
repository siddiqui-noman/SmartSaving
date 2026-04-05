import 'dart:math';

import '../models/product.dart';
import 'local_product_database_service.dart';

class FlipkartService {
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
    return localProductDatabaseService.getProductById(productId)
            ?.currentFlipkartPrice ??
        0.0;
  }

  List<double> getPriceHistory(String productId) {
    return localProductDatabaseService.getFlipkartPriceHistory(productId);
  }

  Future<void> _simulateApiDelay() async {
    final delayMs = 1000 + _random.nextInt(1001);
    await Future.delayed(Duration(milliseconds: delayMs));
  }
}

final flipkartService = FlipkartService();
