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
    
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Popular Categories Section
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: Text(
                  'POPULAR CATEGORIES',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _CategoryChip(icon: Icons.smartphone_rounded, label: 'Phones', onTap: () => _executeSearch('Phones')),
                    _CategoryChip(icon: Icons.laptop_rounded, label: 'Laptops', onTap: () => _executeSearch('Laptops')),
                    _CategoryChip(icon: Icons.headphones_rounded, label: 'Audio', onTap: () => _executeSearch('Audio')),
                    _CategoryChip(icon: Icons.watch_rounded, label: 'Watches', onTap: () => _executeSearch('Watches')),
                    _CategoryChip(icon: Icons.tv_rounded, label: 'TVs', onTap: () => _executeSearch('TVs')),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),

        // Recent Searches Section
        if (recentSearches.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RECENT SEARCHES',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.read(recentSearchesProvider.notifier).clearHistory(),
                    child: const Text('Clear', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.red)),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final query = recentSearches[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.history_rounded, size: 18, color: Colors.grey[400]),
                    title: Text(query, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                    trailing: IconButton(
                      icon: const Icon(Icons.arrow_outward_rounded, size: 16, color: Colors.grey),
                      onPressed: () {
                         _searchController.text = query;
                      },
                    ),
                    onTap: () {
                      _searchController.text = query;
                      _executeSearch(query);
                    },
                  ),
                );
              },
              childCount: recentSearches.length,
            ),
          ),
        ] else
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(AppColors.primary).withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.manage_search_rounded, size: 60, color: const Color(AppColors.primary).withOpacity(0.2)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Search for your next deal',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
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

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CategoryChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: ActionChip(
        avatar: Icon(icon, size: 16, color: const Color(AppColors.primary)),
        label: Text(label),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        backgroundColor: Colors.transparent,
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        onPressed: onTap,
      ),
    );
  }
}
