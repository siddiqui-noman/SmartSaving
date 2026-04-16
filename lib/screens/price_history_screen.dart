import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/tracked_product.dart';
import '../providers/price_prediction_provider.dart';
import '../providers/tracked_products_provider.dart';
import '../services/local_product_database_service.dart';
import '../widgets/app_bar.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../utils/constants.dart';

class PriceHistoryScreen extends ConsumerWidget {
  final String productId;

  const PriceHistoryScreen({super.key, required this.productId});

  /// Builds a list of PriceSnapshots from raw simulated data for untracked products.
  List<PriceSnapshot> _buildSnapshotsFromLocal(String pid) {
    final amazonHistory = localProductDatabaseService.getAmazonPriceHistory(pid);
    final flipkartHistory = localProductDatabaseService.getFlipkartPriceHistory(pid);
    final count = amazonHistory.length < flipkartHistory.length
        ? amazonHistory.length
        : flipkartHistory.length;
    if (count == 0) return [];

    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: count - 1));
    return List.generate(count, (i) {
      return PriceSnapshot(
        amazonPrice: amazonHistory[i],
        flipkartPrice: flipkartHistory[i],
        timestamp: startDate.add(Duration(days: i)),
      );
    });
  }

  /// Returns a clean Y-axis interval so only ~5 labels appear regardless of price range.
  double _calcYInterval(List<PriceSnapshot> history) {
    if (history.isEmpty) return 1000;
    final prices = history
        .expand((s) => [s.amazonPrice, s.flipkartPrice])
        .toList();
    final minP = prices.reduce((a, b) => a < b ? a : b);
    final maxP = prices.reduce((a, b) => a > b ? a : b);
    final range = maxP - minP;
    if (range <= 0) return 1000;
    // Aim for ~5 grid lines
    final raw = range / 4;
    // Round up to nearest nice number
    final magnitude = _pow10(raw.floor().toString().length - 1);
    return (raw / magnitude).ceil() * magnitude;
  }

  double _pow10(int exp) {
    double result = 1;
    for (int i = 0; i < exp; i++) result *= 10;
    return result;
  }

  static const _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _monthAbbr(int month) => _months[month];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackedAsync = ref.watch(trackedProductsProvider);

    // Try to find this product in the tracked list first
    final trackedProduct = trackedAsync.maybeWhen(
      data: (tracked) {
        try {
          return tracked.firstWhere((t) => t.product.id == productId);
        } catch (_) {
          return null;
        }
      },
      orElse: () => null,
    );

    // Fall back to local simulated data for untracked products
    final isTracked = trackedProduct != null;
    final history = isTracked
        ? trackedProduct!.priceHistory
        : _buildSnapshotsFromLocal(productId);

    final productName = isTracked
        ? trackedProduct!.product.name
        : localProductDatabaseService.getProductById(productId)?.name ?? 'Product';

    return Scaffold(
      appBar: SmartSavingAppBar(
        title: AppStrings.priceHistory,
        onBackPressed: () => Navigator.pop(context),
      ),
      body: history.isEmpty
          ? const Center(child: Text('No price data available.'))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (!isTracked)
                      Container(
                        margin: const EdgeInsets.only(top: AppDimensions.paddingS),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.paddingM,
                            vertical: AppDimensions.paddingS),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Track this product to get personalized alerts and live updates.',
                                style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppDimensions.paddingM),

                    // Price chart
                    Card(
                      elevation: AppDimensions.cardElevation,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusL),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppDimensions.paddingM),
                        child: history.length > 1
                            ? SizedBox(
                                height: 300,
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(show: true),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 56,
                                          interval: _calcYInterval(history),
                                          getTitlesWidget: (value, meta) {
                                            return Padding(
                                              padding: const EdgeInsets.only(right: 4),
                                              child: Text(
                                                CurrencyFormatter.formatCompact(value),
                                                style: const TextStyle(fontSize: 10),
                                                textAlign: TextAlign.right,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 32,
                                          interval: 1,
                                          getTitlesWidget: (value, meta) {
                                            final idx = value.toInt();
                                            // Only print every 3rd label to avoid crowding
                                            if (idx < 0 || idx >= history.length || idx % 3 != 0) {
                                              return const SizedBox.shrink();
                                            }
                                            final ts = history[idx].timestamp;
                                            final label =
                                                '${_monthAbbr(ts.month)} ${ts.day}';
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 6),
                                              child: Text(
                                                label,
                                                style: const TextStyle(fontSize: 9),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                    ),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: List.generate(
                                          history.length,
                                          (index) => FlSpot(
                                            index.toDouble(),
                                            history[index].amazonPrice,
                                          ),
                                        ),
                                        isCurved: true,
                                        color: const Color(AppColors.primary),
                                        barWidth: 2,
                                        dotData: FlDotData(show: false),
                                      ),
                                      LineChartBarData(
                                        spots: List.generate(
                                          history.length,
                                          (index) => FlSpot(
                                            index.toDouble(),
                                            history[index].flipkartPrice,
                                          ),
                                        ),
                                        isCurved: true,
                                        color: Colors.orange,
                                        barWidth: 2,
                                        dotData: FlDotData(show: false),
                                        dashArray: [5, 5],
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(AppDimensions.paddingL),
                                  child: Text('Insufficient data for chart'),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingS),
                    // Legend
                    Row(
                      children: [
                        Container(width: 16, height: 3, color: const Color(AppColors.primary)),
                        const SizedBox(width: 6),
                        const Text('Amazon', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 16),
                        Container(width: 16, height: 3, color: Colors.orange),
                        const SizedBox(width: 6),
                        const Text('Flipkart', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.paddingL),

                    // Price history list
                    Text(
                      'Price History',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppDimensions.paddingM),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final snapshot = history[index];
                        final prevSnapshot = index > 0 ? history[index - 1] : null;
                        final priceChange = prevSnapshot != null
                            ? snapshot.bestPrice - prevSnapshot.bestPrice
                            : 0.0;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: AppDimensions.paddingS),
                          child: ListTile(
                            leading: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  priceChange > 0
                                      ? Icons.trending_up
                                      : priceChange < 0
                                          ? Icons.trending_down
                                          : Icons.trending_flat,
                                  color: priceChange > 0
                                      ? Colors.red
                                      : priceChange < 0
                                          ? Colors.green
                                          : Colors.grey,
                                ),
                              ],
                            ),
                            title: Text(DateFormatter.formatDateTime(snapshot.timestamp)),
                            subtitle: Text(
                              'Amazon: ${CurrencyFormatter.format(snapshot.amazonPrice)} | Flipkart: ${CurrencyFormatter.format(snapshot.flipkartPrice)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyFormatter.format(snapshot.bestPrice),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                if (prevSnapshot != null && priceChange != 0.0)
                                  Text(
                                    '${priceChange > 0 ? '+' : ''}${CurrencyFormatter.format(priceChange)}',
                                    style: TextStyle(
                                      color: priceChange > 0 ? Colors.red : Colors.green,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Price prediction — only for tracked products
                    if (isTracked) ...[
                      const SizedBox(height: AppDimensions.paddingL),
                      Consumer(
                        builder: (context, ref, _) {
                          final predictionAsync = ref.watch(
                            pricePredictionProvider(trackedProduct!),
                          );

                          return predictionAsync.when(
                            data: (prediction) {
                              return Card(
                                elevation: AppDimensions.cardElevation,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.borderRadiusL),
                                ),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.all(AppDimensions.paddingM),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppStrings.pricePrediction,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: AppDimensions.paddingM),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Current Price',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall),
                                              const SizedBox(height: 4),
                                              Text(
                                                CurrencyFormatter.format(
                                                    trackedProduct!.product.bestPrice),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                        fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text('Predicted (7 days)',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall),
                                              const SizedBox(height: 4),
                                              Text(
                                                CurrencyFormatter.format(
                                                    prediction['predictedPrice']
                                                        as double),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                      color: prediction['trend'] == 'DOWN'
                                                          ? Colors.green
                                                          : prediction['trend'] == 'UP'
                                                              ? Colors.red
                                                              : Colors.grey,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppDimensions.paddingM),
                                      Container(
                                        padding: const EdgeInsets.all(
                                            AppDimensions.paddingM),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(
                                              AppDimensions.borderRadiusM),
                                        ),
                                        child: Text(
                                          prediction['message'] as String,
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            loading: () =>
                                const Center(child: CircularProgressIndicator()),
                            error: (error, stack) => const SizedBox.shrink(),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
