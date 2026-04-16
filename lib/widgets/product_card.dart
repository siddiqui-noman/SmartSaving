import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/currency_formatter.dart';
import '../utils/constants.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onTrackTap;
  final bool isTracked;
  final double? width;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onTrackTap,
    this.isTracked = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: AppDimensions.cardElevation,
        margin: const EdgeInsets.all(AppDimensions.paddingM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusL),
      ),
      clipBehavior: Clip.antiAlias, // Ensures InkWell rippling stays inside bounds
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            AspectRatio(
              aspectRatio: 16 / 10,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.borderRadiusL),
                  topRight: Radius.circular(AppDimensions.borderRadiusL),
                ),
                child: Container(
                  color: Colors.grey[200],
                  child: Hero(
                    tag: 'product_image_${product.id}',
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }
                        return const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                            size: 40,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name (Fixed height to force uniform rendering)
                  SizedBox(
                    height: 46,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                  Text(
                    product.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                  // Rating
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: AppDimensions.paddingS),
                      Text(
                        '${product.rating.toStringAsFixed(1)} (${product.reviews})',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  // prices
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Best Price',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Color(AppColors.textSecondary),
                                  ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                CurrencyFormatter.format(product.bestPrice),
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Color(AppColors.success),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppDimensions.paddingS),
                      Chip(
                        label: Text(
                          product.bestPlatform,
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: product.bestPlatform == 'Amazon'
                            ? Colors.orange
                            : Colors.blue,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  // Track button
                  if (onTrackTap != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onTrackTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isTracked
                              ? const Color(0xFFE53935)
                              : Color(AppColors.primary),
                        ),
                        child: Text(
                          isTracked ? 'Untrack' : 'Track Product',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
