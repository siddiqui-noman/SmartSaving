import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tracked_products_provider.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../widgets/app_bar.dart';
import '../models/tracked_product.dart';

class PriceAlertsScreen extends ConsumerWidget {
  const PriceAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackedAsync = ref.watch(trackedProductsProvider);

    return Scaffold(
      appBar: SmartSavingAppBar(
        title: 'Price Alerts',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: trackedAsync.when(
        data: (tracked) {
          // Only show items that have a target price set
          final alerts = tracked.where((t) => t.targetPrice != null).toList();

          if (alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 72, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No price alerts set',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track a product and set a target price\nto get notified when it drops.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final item = alerts[index];
              return _AlertCard(item: item);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _AlertCard extends ConsumerWidget {
  final TrackedProduct item;
  const _AlertCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = item.product;
    final targetPrice = item.targetPrice!;
    final currentBest = product.bestPrice;
    final isTriggered = currentBest <= targetPrice;
    final diff = currentBest - targetPrice;
    final pct = ((diff / targetPrice) * 100).abs();

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Product image thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    product.imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.image_not_supported, size: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.category,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isTriggered
                        ? Colors.green.withOpacity(0.12)
                        : Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isTriggered ? '🎯 Triggered' : '⏳ Watching',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isTriggered ? Colors.green[700] : Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _PriceStat(
                  label: 'Current Best',
                  value: CurrencyFormatter.format(currentBest),
                  sub: product.bestPlatform,
                  color: isTriggered ? Colors.green : null,
                ),
                _PriceStat(
                  label: 'Your Target',
                  value: CurrencyFormatter.format(targetPrice),
                  sub: isTriggered
                      ? '▼ ${pct.toStringAsFixed(1)}% below'
                      : '▲ ${CurrencyFormatter.format(diff.abs())} away',
                  color: isTriggered ? Colors.green : Colors.orange[700],
                  subColor: isTriggered ? Colors.green : Colors.orange[700],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit Alert'),
                    onPressed: () => _showEditAlert(context, ref, item),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 16,
                        color: Colors.red),
                    label: const Text('Remove',
                        style: TextStyle(color: Colors.red)),
                    onPressed: () async {
                      await ref
                          .read(trackedProductsProvider.notifier)
                          .removeTargetPrice(product.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Alert removed for ${product.name}')),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: const BorderSide(color: Colors.red),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAlert(
      BuildContext context, WidgetRef ref, TrackedProduct item) {
    final controller =
        TextEditingController(text: item.targetPrice!.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Price Alert'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Target Price (₹)',
            prefixText: '₹ ',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                await ref
                    .read(trackedProductsProvider.notifier)
                    .setTargetPrice(item.product.id, val);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _PriceStat extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color? color;
  final Color? subColor;

  const _PriceStat({
    required this.label,
    required this.value,
    required this.sub,
    this.color,
    this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withOpacity(0.6),
                )),
        const SizedBox(height: 2),
        Text(value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                )),
        Text(sub,
            style: TextStyle(
                fontSize: 11,
                color: subColor ??
                    Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withOpacity(0.5))),
      ],
    );
  }
}
