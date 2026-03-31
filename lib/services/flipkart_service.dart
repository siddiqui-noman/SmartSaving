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
    return localProductDatabaseService.getProductById(productId)?.currentFlipkartPrice ??
        0.0;
  }

  List<double> getPriceHistory(String productId) {
    return localProductDatabaseService.getFlipkartPriceHistory(productId);
  }

  Future<void> _simulateApiDelay() async {
    final delayMs = 1000 + _random.nextInt(1001);
    await Future.delayed(Duration(milliseconds: delayMs));
  }

  /// Send a message to the Gemini Assistant along with product context
  Future<String> askAssistant(Product product, String userMessage) async {
    try {
      final response = await http.post(
        // Use 10.0.2.2 for Android Emulator to reach your FastAPI server
        Uri.parse("http://10.0.2.2:8000/chat"), 
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "message": userMessage,
          "product_name": product.name,
          // Note: Using amazonPrice as the 'current_price' field for the backend
          "current_price": product.flipkartPrice, 
          "category": "Electronics"
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'] as String;
      } else {
        print('❌ Flipkart Assistant Error: ${response.statusCode}');
        return "The assistant is having trouble right now.";
      }
    } catch (e) {
      print('❌ Connection Error: $e');
      return "Could not connect to the smart assistant.";
    }
  }
}

final flipkartService = FlipkartService();
