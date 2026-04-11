import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';
import '../providers/tracked_products_provider.dart';
import '../utils/constants.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/product_card.dart';
import '../widgets/search_bar_widget.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final trackedIds = ref.watch(
      trackedProductsProvider.select(
        (trackedAsync) => trackedAsync.maybeWhen(
          data: (trackedProducts) => trackedProducts
              .map((trackedProduct) => trackedProduct.product.id)
              .toSet(),
          orElse: () => <String>{},
        ),
      ),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: ProductSearchBar(
            controller: _searchController,
            onChanged: (value) {
              ref.read(productsProvider.notifier).searchProducts(value);
            },
            onClear: () {
              _searchController.clear();
              ref.read(productsProvider.notifier).searchProducts('');
            },
          ),
        ),
        Expanded(
          child: productsAsync.when(
            data: (products) => _buildProductsList(products, trackedIds),
            loading: () => const ProductListSkeleton(),
            error: (error, stack) => _buildErrorState(context),
          ),
        ),
      ],
    );
  }

  Widget _buildProductsList(List<Product> products, Set<String> trackedIds) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              AppStrings.noProducts,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final isTracked = trackedIds.contains(product.id);

        return ProductCard(
          product: product,
          onTap: () {
            Navigator.of(
              context,
            ).pushNamed('/product-detail', arguments: product);
          },
          onTrackTap: () async {
            if (isTracked) {
              await ref
                  .read(trackedProductsProvider.notifier)
                  .removeTrackedProduct(product.id);
            } else {
              await ref
                  .read(trackedProductsProvider.notifier)
                  .addTrackedProduct(product);
            }
          },
          isTracked: isTracked,
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            AppStrings.error,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          ElevatedButton(
            onPressed: () {
              ref.read(productsProvider.notifier).retry();
            },
            child: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }
}
