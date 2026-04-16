import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';
import '../utils/constants.dart';
import '../models/product.dart';

class PriceComparisonCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onMoreDetails;

  const PriceComparisonCard({
    super.key,
    required this.product,
    this.onMoreDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bestPrice = product.bestPrice;
    final bestPlatform = product.bestPlatform;
    final amazonPrice = product.amazonPrice;
    final flipkartPrice = product.flipkartPrice;
    final savings = product.savingsAmount;
    final savingsPercentage = product.savingsPercentage;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingS,
      ),
      elevation: AppDimensions.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prices comparison row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _PlatformPrice(
                  platform: 'Amazon',
                  price: amazonPrice,
                  isBest: bestPlatform == 'Amazon',
                ),
                Container(width: 1, height: 60, color: theme.dividerColor),
                _PlatformPrice(
                  platform: 'Flipkart',
                  price: flipkartPrice,
                  isBest: bestPlatform == 'Flipkart',
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingM),
            // Best deal banner
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: Color(AppColors.success),
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusM,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Best Price',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white),
                      ),
                      Text(
                        CurrencyFormatter.format(bestPrice),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Save up to',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                      Text(
                        CurrencyFormatter.format(savings),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      Text(
                        '(${savingsPercentage.toStringAsFixed(2)}%)',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onMoreDetails != null) ...[
              const SizedBox(height: AppDimensions.paddingM),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onMoreDetails,
                  child: const Text('View Details'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlatformPrice extends StatelessWidget {
  final String platform;
  final double price;
  final bool isBest;

  const _PlatformPrice({
    required this.platform,
    required this.price,
    required this.isBest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primaryColor = const Color(AppColors.primary);
    final successColor = const Color(AppColors.success);

    return Column(
      children: [
        // FIXED ALIGNMENT: Always have a box, but show label only if best
        SizedBox(
          height: 34,
          child: isBest
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: successColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: successColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    'BEST DEAL',
                    style: TextStyle(
                      color: successColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
        // Platform Name
        Text(
          platform,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isBest ? successColor : onSurface.withOpacity(0.6),
            fontWeight: isBest ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        // Price Text
        Text(
          CurrencyFormatter.format(price),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 18, // Slightly larger for premium feel
            color: isBest ? successColor : onSurface,
          ),
        ),
      ],
    );
  }
}
