import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../services/amazon_service.dart';
import '../services/flipkart_service.dart';

final amazonServiceProvider = Provider((ref) => amazonService);
final flipkartServiceProvider = Provider((ref) => flipkartService);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() {
    return 'Popular';
  }

  void setQuery(String query) {
    state = query;
  }
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

final productsProvider =
    NotifierProvider<ProductsNotifier, AsyncValue<List<Product>>>(() {
  return ProductsNotifier();
});

class ProductsNotifier extends Notifier<AsyncValue<List<Product>>> {
  late String query;

  @override
  AsyncValue<List<Product>> build() {
    query = ref.watch(searchQueryProvider);
    _searchProducts();
    return const AsyncValue.loading();
  }

  Future<void> _searchProducts() async {
    if (query.trim().isEmpty) {
      final mockProducts = await amazonService.searchProducts('Popular');
      state = AsyncValue.data(mockProducts);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final amazonResults = await amazonService.searchProducts(query);
      state = AsyncValue.data(amazonResults);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> retry() => _searchProducts();
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
