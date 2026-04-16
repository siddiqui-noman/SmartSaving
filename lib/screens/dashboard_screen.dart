import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../providers/tracked_products_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/product_card.dart';
import '../widgets/loading_skeleton.dart';

class DashboardScreen extends ConsumerWidget {
  final Function(String) onCategoryTap;
  final ScrollController? scrollController;

  const DashboardScreen({super.key, required this.onCategoryTap, this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final trendingDeals = ref.watch(trendingDealsProvider); // Statically cached random UI scope
    final userAsync = ref.watch(currentUserProvider);
    final userName = userAsync.value?.name?.split(' ').first ?? 'User';
    final trackedIds = ref.watch(
      trackedProductsProvider.select(
        (async) => async.maybeWhen(
          data: (ts) => ts.map((e) => e.product.id).toSet(),
          orElse: () => <String>{},
        ),
      ),
    );

    return productsAsync.when(
      data: (products) => _buildDashboard(products, trendingDeals, trackedIds, userName, context, ref),
      loading: () => const ProductListSkeleton(),
      error: (error, stack) => Center(child: Text('Failed to load dashboard: $error')),
    );
  }

  Widget _buildDashboard(
      List<Product> products, List<Product> trendingDeals, Set<String> trackedIds, String userName, BuildContext context, WidgetRef ref) {
    
    final categories = ['Phones', 'Laptops', 'Audio', 'Gaming', 'TVs', 'Cameras', 'Accessories'];

    return RefreshIndicator(
      onRefresh: () async {
        // Explicitly invalidate our isolated Trending cache to trigger a structural reroll
        ref.invalidate(trendingDealsProvider);
        // Also refresh global product memory 
        ref.invalidate(productsProvider);
        await Future.delayed(const Duration(milliseconds: 1200));
      },
      child: CustomScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(), // Ensure it can be pulled even if not overflowing vertically
        slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingM,
              vertical: AppDimensions.paddingS,
            ),
            child: Row(
              children: [
                Expanded(
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Hello, $userName 👋',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    label: Text(cat, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onPressed: () {
                      ref.read(productsProvider.notifier).searchProducts(cat);
                      onCategoryTap(cat);
                    },
                  ),
                );
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(AppColors.primary), Color(AppColors.primaryDark)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppDimensions.borderRadiusL),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Market Overview',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You are tracking ${trackedIds.length} items',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingM,
              AppDimensions.paddingM,
              AppDimensions.paddingM,
              AppDimensions.paddingS,
            ),
            child: Text(
              'Trending Deals',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 540,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingS),
              itemCount: trendingDeals.length,
              itemBuilder: (context, index) {
                final product = trendingDeals[index];
                final isTracked = trackedIds.contains(product.id);
                return ProductCard(
                  width: 280,
                  product: product,
                  isTracked: isTracked,
                  onTap: () {
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
                );
              },
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 60)),
      ],
    ),
    );
  }
}
