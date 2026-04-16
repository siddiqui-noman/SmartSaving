import '../models/simulated_product.dart';
import 'price_history_generator_service.dart';
import 'simulated_data.dart'; // [IMPORTED MASSIVE REAL DATA]

class LocalProductDatabaseService {
  LocalProductDatabaseService({PriceHistoryGeneratorService? generator})
    : _generator = generator ?? priceHistoryGeneratorService {
    _seedDatabase();
  }

  final PriceHistoryGeneratorService _generator;
  final Map<String, SimulatedProduct> _products = {};

  List<SimulatedProduct> searchProducts(String query) {
    _rollAllProductsToToday();

    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'popular' || normalized == 'all') {
      return _sortedProducts();
    }

    return _sortedProducts().where((product) {
      final searchable =
          '${product.name} ${product.category} ${product.description}'
              .toLowerCase();
      return searchable.contains(normalized);
    }).toList();
  }

  SimulatedProduct? getProductById(String productId) {
    _rollProductToToday(productId);
    return _products[productId];
  }

  List<double> getAmazonPriceHistory(String productId) {
    return List<double>.from(
      getProductById(productId)?.amazonPriceHistory ?? const [],
    );
  }

  List<double> getFlipkartPriceHistory(String productId) {
    return List<double>.from(
      getProductById(productId)?.flipkartPriceHistory ?? const [],
    );
  }

  List<SimulatedProduct> _sortedProducts() {
    final products = _products.values.toList();
    products.sort((a, b) => b.reviews.compareTo(a.reviews));
    return products;
  }

  void _rollAllProductsToToday() {
    for (final id in _products.keys.toList()) {
      _rollProductToToday(id);
    }
  }

  void _rollProductToToday(String productId) {
    final product = _products[productId];
    if (product == null) return;

    final today = _dateOnly(DateTime.now());
    final productDate = _dateOnly(product.lastUpdated);
    final daysToGenerate = today.difference(productDate).inDays;
    if (daysToGenerate <= 0) return;

    _products[productId] = _rollForwardProduct(product, daysToGenerate);
  }

  SimulatedProduct _rollForwardProduct(
    SimulatedProduct product,
    int daysToGenerate,
  ) {
    final amazonHistory = _generator.generateForwardHistory(
      existingHistory: product.amazonPriceHistory,
      days: daysToGenerate,
      seedPrefix:
          '${product.id}_amazon_${product.amazonPriceHistory.length}_${product.lastUpdated.millisecondsSinceEpoch}',
      downwardBias: -0.0018,
    );

    final flipkartHistory = _generator.generateForwardHistory(
      existingHistory: product.flipkartPriceHistory,
      days: daysToGenerate,
      seedPrefix:
          '${product.id}_flipkart_${product.flipkartPriceHistory.length}_${product.lastUpdated.millisecondsSinceEpoch}',
      downwardBias: -0.0022,
    );

    return product.copyWith(
      amazonPriceHistory: amazonHistory,
      flipkartPriceHistory: flipkartHistory,
      lastUpdated: _dateOnly(product.lastUpdated).add(
        Duration(days: daysToGenerate),
      ),
    );
  }

  void _seedDatabase() {
    // Ingest the decoupled, massive generated structured payload instantly
    for (final product in generatedProducts) {
      _products[product.id] = product;
    }
  }

  DateTime _dateOnly(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }
}

final localProductDatabaseService = LocalProductDatabaseService();
