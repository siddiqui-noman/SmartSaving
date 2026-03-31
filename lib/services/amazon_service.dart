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
    try {
      final product = await getProduct(productId);
      return product?.amazonPrice ?? 0.0;
    } catch (e) {
      print('❌ Get price error: $e');
      return 0.0;
    }
  }

  /// Parse Amazon API response
  List<Product> _parseAmazonResponse(dynamic data) {
    final results = <Product>[];
    try {
      print('🔍 Looking for results key in response...');

      // Try different possible response structures
      List? items = data['results'] as List?;
      if (items == null) {
        print('⚠️  No "results" key found');
        // Try other possible response formats
        items = data['data'] as List?;
      }
      if (items == null) {
        items = data['products'] as List?;
      }
      if (items == null && data is List) {
        items = data;
      }

      items ??= [];
      print('📦 Found ${items.length} items to parse');
      print(
        'First item (if exists): ${items.isNotEmpty ? items.first : "EMPTY"}',
      );

      for (var item in items) {
        final product = _parseProductFromApi(item);
        if (product != null) {
          results.add(product);
        }
      }
      print('✅ Parsed ${results.length} products from Amazon');
    } catch (e, st) {
      print('❌ Parse error: $e');
      print('Stack: $st');
    }
    return results.isNotEmpty ? results : _getMockProducts();
  }

  /// Parse single product from API response
  Product? _parseProductFromApi(dynamic item) {
    try {
      // Debug: show available keys
      if (item is Map) {
        print('📌 Item keys: ${(item as Map).keys.toList()}');
      }

      // Get image URL - try multiple possible field names
      String imageUrl = '';
      if (item['image'] != null) {
        imageUrl = item['image'].toString();
      } else if (item['thumbnail'] != null) {
        imageUrl = item['thumbnail'].toString();
      } else if (item['imageUrl'] != null) {
        imageUrl = item['imageUrl'].toString();
      } else if (item['productImage'] != null) {
        imageUrl = item['productImage'].toString();
      }

      // If no image from API, use placeholder
      if (imageUrl.isEmpty) {
        final productName =
            item['title']?.toString() ?? item['name']?.toString() ?? 'Product';
        imageUrl =
            'https://via.placeholder.com/300x300?text=${Uri.encodeComponent(productName)}';
      }

      return Product(
        id: item['asin']?.toString() ?? item['id']?.toString() ?? 'unknown',
        name:
            item['title']?.toString() ?? item['name']?.toString() ?? 'Unknown',
        description:
            item['description']?.toString() ??
            item['productDescription']?.toString() ??
            'No description',
        imageUrl: imageUrl,
        amazonPrice:
            (item['price'] as num?)?.toDouble() ??
            (item['currentPrice'] as num?)?.toDouble() ??
            (item['offerPrice'] as num?)?.toDouble() ??
            (item['discountedPrice'] as num?)?.toDouble() ??
            0.0,
        flipkartPrice: (item['price'] as num?)?.toDouble() ?? 0.0,
        rating:
            (item['rating'] as num?)?.toDouble() ??
            (item['stars'] as num?)?.toDouble() ??
            (item['productRating'] as num?)?.toDouble() ??
            0.0,
        reviews:
            item['reviews'] as int? ??
            item['numOfRatings'] as int? ??
            item['reviewCount'] as int? ??
            0,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print(
        '❌ Parse product error: $e, item keys: ${item is Map ? (item as Map).keys.toList() : "not a map"}',
      );
      return null;
    }
  }

  /// Get mock products as fallback
  List<Product> _getMockProducts() {
    return mockProducts.map((data) => _createProduct(data)).toList();
  }

  Product _createProduct(Map<String, dynamic> data) {
    final basePrice = data['basePrice'] as int;
    final discount = data['discount'] as double;
    final actualPrice = (basePrice * (1 - discount)).toDouble();
    final imageUrl = data['image'] as String?;

    return Product(
      id: data['id'] as String,
      name: data['name'] as String,
      description:
          'Premium ${data['category']} product with excellent features',
      imageUrl:
          imageUrl ??
          'https://via.placeholder.com/300x300?text=${Uri.encodeComponent(data["name"])}',
      amazonPrice: actualPrice + Random().nextDouble() * 5000,
      flipkartPrice: actualPrice + Random().nextDouble() * 3000,
      rating: 3.5 + Random().nextDouble() * 1.5,
      reviews: Random().nextInt(5000) + 100,
      updatedAt: DateTime.now(),
    );
  }

  Future<String> askAssistant(Product product, String userMessage) async {
    try {
      final response = await http.post(
        // Replace with your actual backend URL (use 10.0.2.2 for Android Emulator)
        Uri.parse("http://127.0.0.1:8000/chat"), 
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "message": userMessage,
          "product_name": product.name,
          "current_price": product.amazonPrice,
          "category": "Electronics" // You can also add product.category if your model has it
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'] as String;
      } else {
        print('❌ Assistant Error: ${response.statusCode} - ${response.body}');
        return "The assistant is having trouble right now. Please try again.";
      }
    } catch (e) {
      print('❌ Connection Error: $e');
      return "Could not connect to the smart assistant.";
    }
  }
}

final amazonService = AmazonService();
