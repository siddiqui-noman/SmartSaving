import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/product.dart';
import 'api_config.dart';
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
      print('Get price error: $e');
      return 0.0;
    }
  }

  List<double> getPriceHistory(String productId) {
    return localProductDatabaseService.getAmazonPriceHistory(productId);
  }

  // Future-facing parser for real Amazon API integration.
  List<Product> _parseAmazonResponse(dynamic data) {
    final results = <Product>[];
    try {
      List? items = data['results'] as List?;
      items ??= data['data'] as List?;
      items ??= data['products'] as List?;
      if (items == null && data is List) {
        items = data;
      }

      items ??= [];
      for (final item in items) {
        final product = _parseProductFromApi(item);
        if (product != null) {
          results.add(product);
        }
      }
    } catch (e, st) {
      print('Parse error: $e');
      print('Stack: $st');
    }

    return results.isNotEmpty ? results : _getMockProducts();
  }

  Product? _parseProductFromApi(dynamic item) {
    try {
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
        category: item['category']?.toString() ?? 'General',
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
      print('Parse product error: $e');
      return null;
    }
  }

  List<Product> _getMockProducts() {
    final products = localProductDatabaseService.searchProducts('Popular');
    return products.map((product) => product.toProduct()).toList();
  }

  Product _createProduct(Map<String, dynamic> data) {
    final basePrice = data['basePrice'] as int;
    final discount = data['discount'] as double;
    final actualPrice = (basePrice * (1 - discount)).toDouble();
    final imageUrl = data['image'] as String?;

    return Product(
      id: data['id'] as String,
      name: data['name'] as String,
      category: data['category'] as String? ?? 'General',
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
        Uri.parse(ApiConfig.chatApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': userMessage,
          'product_name': product.name,
          'current_price': product.amazonPrice,
          'category': 'Electronics',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'] as String;
      } else {
        print('Assistant error: ${response.statusCode} - ${response.body}');
        return 'The assistant is having trouble right now. Please try again.';
      }
    } catch (e) {
      print('Connection error: $e');
      return 'Could not connect to the smart assistant.';
    }
  }

  Future<void> _simulateApiDelay() async {
    final delayMs = 1000 + _random.nextInt(1001);
    await Future.delayed(Duration(milliseconds: delayMs));
  }
}

final amazonService = AmazonService();
