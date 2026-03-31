import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/price_prediction_provider.dart';
import '../providers/tracked_products_provider.dart';
import '../widgets/app_bar.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../utils/constants.dart';

class PriceHistoryScreen extends ConsumerWidget {
  final String productId;

  const PriceHistoryScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackedAsync = ref.watch(trackedProductsProvider);

    return Scaffold(
      appBar: SmartSavingAppBar(
        title: AppStrings.priceHistory,
        onBackPressed: () => Navigator.pop(context),
      ),
      body: trackedAsync.when(
        data: (tracked) {
          final trackedProduct = tracked.firstWhere(
            (t) => t.product.id == productId,
            orElse: () => throw Exception('Product not found'),
          );

          final history = trackedProduct.priceHistory;
          final product = trackedProduct.product;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product info
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),

                  // Price chart
                  Card(
                    elevation: AppDimensions.cardElevation,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.borderRadiusL,
                      ),
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
                                        getTitlesWidget: (value, meta) {
                                          return Text(
                                            CurrencyFormatter.formatCompact(
                                              value,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          if (value.toInt() >= 0 &&
                                              value.toInt() < history.length) {
                                            return Text(
                                              DateFormatter.formatDate(
                                                history[value.toInt()]
                                                    .timestamp,
                                              ),
                                              style: const TextStyle(
                                                fontSize: 8,
                                              ),
                                            );
                                          }
                                          return const Text('');
                                        },
                                      ),
                                    ),
                                  ),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: List.generate(
                                        history.length,
                                        (index) => FlSpot(
                                          index.toDouble(),
                                          history[index].bestPrice,
                                        ),
                                      ),
                                      isCurved: true,
                                      color: const Color(AppColors.primary),
                                      barWidth: 2,
                                      dotData: FlDotData(show: true),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Center(
                              child: Padding(
                                padding: const EdgeInsets.all(
                                  AppDimensions.paddingL,
                                ),
                                child: Text(
                                  'Insufficient data for chart',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ),
                    ),
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
                      final prevSnapshot = index > 0
                          ? history[index - 1]
                          : null;

                      final priceChange = prevSnapshot != null
                          ? snapshot.bestPrice - prevSnapshot.bestPrice
                          : 0.0;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: AppDimensions.paddingS,
                        ),
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
                          title: Text(
                            DateFormatter.formatDateTime(snapshot.timestamp),
                          ),
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
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (prevSnapshot != null && priceChange != 0.0)
                                Text(
                                  '${priceChange > 0 ? '+' : ''}${CurrencyFormatter.format(priceChange)}',
                                  style: TextStyle(
                                    color: priceChange > 0
                                        ? Colors.red
                                        : Colors.green,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppDimensions.paddingL),

                  // Price prediction card
                  Consumer(
                    builder: (context, ref, _) {
                      final predictionAsync = ref.watch(
                        pricePredictionProvider(trackedProduct),
                      );

                      return predictionAsync.when(
                        data: (prediction) {
                          return Card(
                            elevation: AppDimensions.cardElevation,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.borderRadiusL,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                AppDimensions.paddingM,
                              ),
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
                                  const SizedBox(
                                    height: AppDimensions.paddingM,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Current Price',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            CurrencyFormatter.format(
                                              product.bestPrice,
                                            ),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Predicted (7 days)',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            CurrencyFormatter.format(
                                              prediction['predictedPrice']
                                                  as double,
                                            ),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      prediction['trend'] ==
                                                          'DOWN'
                                                      ? Colors.green
                                                      : prediction['trend'] ==
                                                            'UP'
                                                      ? Colors.red
                                                      : Colors.grey,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: AppDimensions.paddingM,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(
                                      AppDimensions.paddingM,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(
                                        AppDimensions.borderRadiusM,
                                      ),
                                    ),
                                    child: Text(
                                      prediction['message'] as String,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
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
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(error.toString())),
      ),
    );
  }
}
