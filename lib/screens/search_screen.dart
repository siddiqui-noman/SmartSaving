import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';
import '../providers/tracked_products_provider.dart';
import '../providers/recent_searches_provider.dart';
import '../utils/constants.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/product_card.dart';
import '../widgets/search_bar_widget.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    // Pull the active state memory directly from the global cache (in case they tapped a category pill!)
    final initialQuery = ref.read(productsProvider.notifier).lastQuery;
    _searchController = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _executeSearch(String val) {
    if (val.trim().isNotEmpty) {
      ref.read(recentSearchesProvider.notifier).addSearch(val);
    }
    ref.read(productsProvider.notifier).searchProducts(val);
    setState(() {});
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

    final isSearching = _searchController.text.trim().isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: ProductSearchBar(
            controller: _searchController,
            onChanged: (value) {
              ref.read(productsProvider.notifier).searchProducts(value);
              setState(() {});
            },
            onSubmitted: _executeSearch,
            onClear: () {
              _searchController.clear();
              ref.read(productsProvider.notifier).searchProducts('');
              setState(() {});
            },
          ),
        ),
        Expanded(
          child: isSearching
              ? productsAsync.when(
                  data: (products) => _buildProductsList(products, trackedIds),
                  loading: () => const ProductListSkeleton(),
                  error: (error, stack) => _buildErrorState(context, error.toString()),
                )
              : _buildRecentSearches(),
        ),
      ],
    );
  }

  Widget _buildRecentSearches() {
    final recentSearches = ref.watch(recentSearchesProvider);
    
    if (recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.youtube_searched_for, size: 64, color: Colors.grey[300]),
            const SizedBox(height: AppDimensions.paddingM),
            Text('No recent searches', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[400])),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM, vertical: AppDimensions.paddingS),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Searches', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  ref.read(recentSearchesProvider.notifier).clearHistory();
                },
                child: const Text('Clear All', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: recentSearches.length,
            itemBuilder: (context, index) {
              final query = recentSearches[index];
              return ListTile(
                leading: const Icon(Icons.history, color: Colors.grey),
                title: Text(query),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    ref.read(recentSearchesProvider.notifier).removeSearch(query);
                  },
                ),
                onTap: () {
                  _searchController.text = query;
                  _executeSearch(query);
                },
              );
            },
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
              Icons.search_off,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              'No matches found!',
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
            // When user commits to clicking a product, log it into history!
            _executeSearch(_searchController.text);
            Navigator.of(context).pushNamed('/product-detail', arguments: product);
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

  Widget _buildErrorState(BuildContext context, String message) {
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
          const SizedBox(height: 8),
          Text(message, style: Theme.of(context).textTheme.bodySmall)
        ],
      ),
    );
  }
}
