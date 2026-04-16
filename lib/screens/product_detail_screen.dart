import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../providers/tracked_products_provider.dart';
import 'chat_screen.dart';
import '../widgets/app_bar.dart';
import '../widgets/price_comparison_card.dart';
import '../widgets/loading_skeleton.dart';
import '../utils/currency_formatter.dart';
import '../utils/constants.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  final Product? fallbackProduct;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.fallbackProduct,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _showTargetPriceForm = false;
  final _targetPriceController = TextEditingController();

  @override
  void dispose() {
    _targetPriceController.dispose();
    super.dispose();
  }

  int? _toBackendProductId(String rawProductId) {
    final digits = RegExp(r'\d+')
        .allMatches(rawProductId)
        .map((match) => match.group(0) ?? '')
        .join();

    final parsed = int.tryParse(digits);
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(priceComparisonProvider(widget.productId));
    final isTracked = ref.watch(isProductTrackedProvider(widget.productId));
    final chatProductName = productAsync.maybeWhen(
      data: (product) => product.name,
      orElse: () => widget.fallbackProduct?.name ?? 'this product',
    );

    return Scaffold(
      // The SliverAppBar inside the body handles the top app bar for premium collapsing effect
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Use a local variable to decide which product to send
          final currentProduct = productAsync.value ?? widget.fallbackProduct;

          if (currentProduct != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ChatScreen(product: currentProduct),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Product data is still loading...')),
            );
          }
        },
        backgroundColor: const Color(AppColors.primary),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.smart_toy_outlined),
        label: const Text('Ask Assistant'),
      ),
      body: productAsync.when(
        data: (product) {
          return _buildProductDetail(context, ref, product, isTracked);
        },
        loading: () {
          // Show fallback product immediately if available, instead of loading skeleton
          if (widget.fallbackProduct != null) {
            return _buildProductDetail(
              context,
              ref,
              widget.fallbackProduct!,
              isTracked,
              showOfflineIndicator: true,
            );
          }
          // Only show skeleton if no fallback available
          return Column(
            children: [
              SmartSavingAppBar(
                title: AppStrings.priceComparison,
                onBackPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingL),
                    child: Column(
                      children: [
                        LoadingSkeleton(height: 300, width: double.infinity),
                        const SizedBox(height: AppDimensions.paddingL),
                        LoadingSkeleton(height: 24, width: double.infinity),
                        const SizedBox(height: AppDimensions.paddingS),
                        LoadingSkeleton(height: 16, width: 200),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        error: (error, stack) {
          // Use fallback product if available, otherwise show error
          if (widget.fallbackProduct != null) {
            return _buildProductDetail(
              context,
              ref,
              widget.fallbackProduct!,
              isTracked,
              showOfflineIndicator: true,
            );
          }
          return Column(
            children: [
               SmartSavingAppBar(
                title: AppStrings.priceComparison,
                onBackPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: AppDimensions.paddingM),
                      Text(AppStrings.error),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductDetail(
    BuildContext context,
    WidgetRef ref,
    Product product,
    bool isTracked, {
    bool showOfflineIndicator = false,
    bool showLoadingOverlay = false,
  }) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 340.0,
              pinned: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back,
                      color: Theme.of(context).colorScheme.onSurface),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return Dialog(
                          backgroundColor: Colors.black87,
                          insetPadding: EdgeInsets.zero,
                          child: Stack(
                            fit: StackFit.loose,
                            children: [
                              InteractiveViewer(
                                panEnabled: true,
                                minScale: 1.0,
                                maxScale: 4.0,
                                child: Center(
                                  child: Hero(
                                    tag: 'product_image_fullscreen_${product.id}',
                                    child: Image.network(
                                      product.imageUrl,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 40,
                                right: 20,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: Hero(
                    tag: 'product_image_${product.id}',
                    child: Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              size: 60,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Offline indicator
                  if (showOfflineIndicator)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimensions.paddingM),
                      color: Colors.amber[100],
                      child: Row(
                        children: [
                          Icon(Icons.cloud_off, color: Colors.amber[800], size: 20),
                          const SizedBox(width: AppDimensions.paddingS),
                          Expanded(
                            child: Text(
                              'Showing cached data - Some prices may not be up-to-date',
                              style: TextStyle(
                                color: Colors.amber[900],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product info safely scaled
                        Text(
                          product.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                  const SizedBox(height: AppDimensions.paddingS),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: AppDimensions.paddingS),
                      Text(
                        '${product.rating.toStringAsFixed(1)} (${product.reviews} reviews)',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  // Price comparison
                  Text(
                    AppStrings.priceComparison,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  PriceComparisonCard(product: product),
                  const SizedBox(height: AppDimensions.paddingL),
                  // Description
                  Text(
                    'About',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                  Text(
                    product.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  // View price history button
                  SizedBox(
                    width: double.infinity,
                    height: AppDimensions.buttonHeight,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          '/price-history',
                          arguments: product.id,
                        );
                      },
                      child: const Text(AppStrings.priceHistory),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  // Track/Set alert button
                  if (!_showTargetPriceForm)
                    SizedBox(
                      width: double.infinity,
                      height: AppDimensions.buttonHeight,
                      child: ElevatedButton(
                        onPressed: () {
                          if (isTracked) {
                            setState(() => _showTargetPriceForm = true);
                          } else {
                            ref
                                .read(trackedProductsProvider.notifier)
                                .addTrackedProduct(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Product tracked!'),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(AppColors.primary),
                        ),
                        child: Text(
                          isTracked ? AppStrings.addAlert : AppStrings.track,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        TextField(
                          controller: _targetPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: AppStrings.targetPrice,
                            prefixText: 'Rs. ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.paddingM),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(
                                    () => _showTargetPriceForm = false,
                                  );
                                  _targetPriceController.clear();
                                },
                                child: const Text(AppStrings.cancel),
                              ),
                            ),
                            const SizedBox(width: AppDimensions.paddingM),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_targetPriceController.text.isNotEmpty) {
                                    final targetPrice = double.tryParse(
                                          _targetPriceController.text,
                                        ) ??
                                        0;
                                    ref
                                        .read(
                                          trackedProductsProvider.notifier,
                                        )
                                        .setTargetPrice(
                                          product.id,
                                          targetPrice,
                                        );
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Alert set for Rs.${CurrencyFormatter.format(targetPrice)}',
                                        ),
                                      ),
                                    );
                                    setState(
                                      () => _showTargetPriceForm = false,
                                    );
                                    _targetPriceController.clear();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(AppColors.primary),
                                ),
                                child: const Text(
                                  AppStrings.save,
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
                ],
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)), // padding for bottom floating action button clearance
          ],
        ),
        if (showLoadingOverlay)
          IgnorePointer(
            ignoring: true,
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}


