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
                Container(width: 1, height: 60, color: Colors.grey[300]),
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
    return Column(
      children: [
        if (isBest)
          Chip(
            label: const Text(
              'BEST',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Color(AppColors.success),
          ),
        const SizedBox(height: AppDimensions.paddingS),
        Text(
          platform,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Color(isBest ? AppColors.success : AppColors.textPrimary),
            fontWeight: isBest ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingS),
        Text(
          CurrencyFormatter.format(price),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Color(isBest ? AppColors.success : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
