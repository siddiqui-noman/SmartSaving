import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../services/amazon_service.dart';
import '../services/flipkart_service.dart';
import '../services/local_product_database_service.dart';

final amazonServiceProvider = Provider((ref) => amazonService);
final flipkartServiceProvider = Provider((ref) => flipkartService);
final localProductDatabaseServiceProvider = Provider(
  (ref) => localProductDatabaseService,
);

final productsProvider =
    NotifierProvider<ProductsNotifier, AsyncValue<List<Product>>>(() {
  return ProductsNotifier();
});

class ProductsNotifier extends Notifier<AsyncValue<List<Product>>> {
  String _lastQuery = '';

  String get lastQuery => _lastQuery;

  @override
  AsyncValue<List<Product>> build() {
    return AsyncValue.data(_loadProductsForQuery(''));
  }

  void searchProducts(String query) {
    _lastQuery = query;
    try {
      state = AsyncValue.data(_loadProductsForQuery(query));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> retry() async {
    searchProducts(_lastQuery);
  }

  List<Product> _loadProductsForQuery(String query) {
    final simulatedProducts = ref
        .read(localProductDatabaseServiceProvider)
        .searchProducts(query);

    return simulatedProducts
        .map((product) => product.toProduct())
        .toList(growable: false);
  }
}

final productDetailProvider = FutureProvider.family<Product?, String>((
  ref,
  productId,
) async {
  try {
    return await amazonService.getProduct(productId);
  } catch (_) {
    return null;
  }
});

final priceComparisonProvider = FutureProvider.family<Product, String>((
  ref,
  productId,
) async {
  const detailRequestTimeout = Duration(seconds: 8);
  final amazonFuture = amazonService.getCurrentPrice(productId).timeout(
        detailRequestTimeout,
        onTimeout: () => 0.0,
      );
  final flipkartFuture = flipkartService.getCurrentPrice(productId).timeout(
        detailRequestTimeout,
        onTimeout: () => 0.0,
      );

  final results = await Future.wait([amazonFuture, flipkartFuture]);
  final amazonPrice = results[0];
  final flipkartPrice = results[1];

  final product = await amazonService.getProduct(productId).timeout(
        detailRequestTimeout,
        onTimeout: () => null,
      );
  if (product == null) {
    throw Exception('Unable to load product details');
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
});
