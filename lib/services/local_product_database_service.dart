import '../models/simulated_product.dart';
import 'price_history_generator_service.dart';

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
    final lastUpdated = _dateOnly(DateTime.now()).subtract(
      const Duration(days: 1),
    );

    final items = <SimulatedProduct>[
      SimulatedProduct(
        id: 'prod_001',
        name: 'Apple iPhone 15 Pro',
        category: 'Smartphones',
        description:
            'A17 Pro smartphone with premium camera setup and ProMotion display.',
        imageUrl:
            'https://images.unsplash.com/photo-1695048132832-b41495f12eb4?q=80&w=2070&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
        rating: 4.6,
        reviews: 4821,
        amazonPriceHistory: [
          87999,
          86999,
          86499,
          85999,
          84999,
          84499,
          83999,
          82999,
          82499,
          81999,
          80999,
          79999,
          78999,
          77999,
        ],
        flipkartPriceHistory: [
          86999,
          85999,
          84999,
          83999,
          82999,
          81999,
          80999,
          79999,
          78999,
          77999,
          76999,
          75999,
          74999,
          73999,
        ],
        lastUpdated: lastUpdated,
      ),
      SimulatedProduct(
        id: 'prod_002',
        name: 'Samsung Galaxy S24',
        category: 'Smartphones',
        description:
            'Flagship Android phone with dynamic AMOLED display and strong battery life.',
        imageUrl:
            'https://images.unsplash.com/photo-1705585174953-9b2aa8afc174?q=80&w=1032&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
        rating: 4.4,
        reviews: 3932,
        amazonPriceHistory: [
          78999,
          77999,
          77499,
          76999,
          75999,
          75499,
          74999,
          73999,
          73499,
          72999,
          71999,
          70999,
          69999,
          68999,
        ],
        flipkartPriceHistory: [
          77999,
          76999,
          75999,
          74999,
          73999,
          72999,
          71999,
          70999,
          69999,
          68999,
          67999,
          66999,
          65999,
          64999,
        ],
        lastUpdated: lastUpdated,
      ),
      SimulatedProduct(
        id: 'prod_003',
        name: 'Sony WH-1000XM5 Headphones',
        category: 'Audio',
        description:
            'Wireless noise-cancelling headphones with premium sound and long battery.',
        imageUrl:
            'https://images.unsplash.com/photo-1733041055704-da53567e49da?q=80&w=2070&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
        rating: 4.5,
        reviews: 2678,
        amazonPriceHistory: [
          26999,
          26499,
          25999,
          25499,
          24999,
          24499,
          23999,
          23699,
          23399,
          22999,
          22699,
          22399,
          21999,
          21699,
        ],
        flipkartPriceHistory: [
          25999,
          25499,
          24999,
          24499,
          23999,
          23499,
          22999,
          22699,
          22399,
          21999,
          21699,
          21399,
          20999,
          20699,
        ],
        lastUpdated: lastUpdated,
      ),
      SimulatedProduct(
        id: 'prod_004',
        name: 'Dell XPS 13 Laptop',
        category: 'Computers',
        description:
            'Compact performance laptop with premium build quality and high-resolution display.',
        imageUrl:
            'https://images.unsplash.com/photo-1593642702821-c8da6771f0c6?q=80&w=2532&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
        rating: 4.3,
        reviews: 1892,
        amazonPriceHistory: [
          114999,
          113499,
          111999,
          110499,
          108999,
          107499,
          105999,
          104499,
          102999,
          101499,
          99999,
          98999,
          97999,
          96999,
        ],
        flipkartPriceHistory: [
          112999,
          111499,
          109999,
          108499,
          106999,
          105499,
          103999,
          102499,
          100999,
          99499,
          97999,
          96999,
          95999,
          94999,
        ],
        lastUpdated: lastUpdated,
      ),
      SimulatedProduct(
        id: 'prod_005',
        name: 'iPad Air 2024',
        category: 'Tablets',
        description:
            'Lightweight tablet with desktop-class chip performance for productivity.',
        imageUrl:
            'https://images.unsplash.com/photo-1561154464-82e9adf32764?w=600&h=600&fit=crop',
        rating: 4.5,
        reviews: 2140,
        amazonPriceHistory: [
          66999,
          65999,
          65499,
          64999,
          63999,
          63499,
          62999,
          61999,
          61499,
          60999,
          59999,
          58999,
          57999,
          56999,
        ],
        flipkartPriceHistory: [
          65999,
          64999,
          63999,
          62999,
          61999,
          60999,
          59999,
          58999,
          57999,
          56999,
          55999,
          54999,
          53999,
          52999,
        ],
        lastUpdated: lastUpdated,
      ),
      SimulatedProduct(
        id: 'prod_006',
        name: 'Apple Watch Series 9',
        category: 'Wearables',
        description:
            'Advanced smartwatch with health tracking and excellent app ecosystem.',
        imageUrl:
            'https://images.unsplash.com/photo-1602174528367-7ed9fc0737e4?q=80&w=1035&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
        rating: 4.4,
        reviews: 3210,
        amazonPriceHistory: [
          39999,
          39499,
          38999,
          38499,
          37999,
          37499,
          36999,
          36499,
          35999,
          35499,
          34999,
          34499,
          33999,
          33499,
        ],
        flipkartPriceHistory: [
          38999,
          38499,
          37999,
          37499,
          36999,
          36499,
          35999,
          35499,
          34999,
          34499,
          33999,
          33499,
          32999,
          32499,
        ],
        lastUpdated: lastUpdated,
      ),
      SimulatedProduct(
        id: 'prod_007',
        name: 'Canon EOS R6 Mark II',
        category: 'Cameras',
        description:
            'Full-frame mirrorless camera for creators with excellent low-light performance.',
        imageUrl:
            'https://images.unsplash.com/photo-1599664223843-9349c75196bc?q=80&w=2070&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
        rating: 4.7,
        reviews: 1104,
        amazonPriceHistory: [
          219999,
          217999,
          216499,
          214999,
          212999,
          210999,
          208999,
          206999,
          204999,
          202999,
          199999,
          197999,
          195999,
          193999,
        ],
        flipkartPriceHistory: [
          217999,
          215999,
          214499,
          212999,
          210999,
          208999,
          206999,
          204999,
          202999,
          200999,
          197999,
          195999,
          193999,
          191999,
        ],
        lastUpdated: lastUpdated,
      ),
      SimulatedProduct(
        id: 'prod_008',
        name: 'LG 55-inch 4K Smart TV',
        category: 'TVs',
        description:
            '55-inch 4K HDR smart TV with voice assistant integration and low-latency mode.',
        imageUrl:
            'https://images.unsplash.com/photo-1593784991095-a205069470b6?w=600&h=600&fit=crop',
        rating: 4.2,
        reviews: 2987,
        amazonPriceHistory: [
          62999,
          61999,
          61499,
          60999,
          59999,
          58999,
          57999,
          56999,
          55999,
          54999,
          53999,
          52999,
          51999,
          50999,
        ],
        flipkartPriceHistory: [
          61999,
          60999,
          59999,
          58999,
          57999,
          56999,
          55999,
          54999,
          53999,
          52999,
          51999,
          50999,
          49999,
          48999,
        ],
        lastUpdated: lastUpdated,
      ),
    ];

    for (final product in items) {
      _products[product.id] = product;
    }
  }

  DateTime _dateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }
}

final localProductDatabaseService = LocalProductDatabaseService();
