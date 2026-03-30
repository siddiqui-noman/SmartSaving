import 'dart:math';

import '../models/tracked_product.dart';

class PricePredictionService {
  Future<Map<String, dynamic>> predictPrice(TrackedProduct trackedProduct) async {
    await Future.delayed(const Duration(milliseconds: 350));

    final history = trackedProduct.priceHistory;
    if (history.isEmpty) {
      return {
        'predictedPrice': trackedProduct.product.bestPrice,
        'confidence': 0.2,
        'trend': 'STABLE',
        'message': 'Price stable',
        'daysPredicted': 7,
      };
    }

    final prices = history.map((snapshot) => snapshot.bestPrice).toList();
    final predictedPrice = _weightedMovingAverage(prices);
    final trend = _detectTrend(prices);

    return {
      'predictedPrice': predictedPrice,
      'confidence': _calculateConfidence(prices.length),
      'trend': trend,
      'message': _trendMessage(trend),
      'daysPredicted': 7,
    };
  }

  Future<Map<String, dynamic>> getBestTimeRecommendation(
    TrackedProduct trackedProduct,
  ) async {
    final prediction = await predictPrice(trackedProduct);
    final currentPrice = trackedProduct.product.bestPrice;
    final predictedPrice = prediction['predictedPrice'] as double;
    final trend = prediction['trend'] as String;

    String recommendation;
    String reason;

    switch (trend) {
      case 'DOWN':
        recommendation = 'Buy Now';
        reason = 'Best time to buy';
        break;
      case 'UP':
        recommendation = 'Wait';
        reason = 'Wait before buying';
        break;
      default:
        recommendation = 'Hold';
        reason = 'Price stable';
    }

    return {
      'recommendation': recommendation,
      'reason': reason,
      'currentPrice': currentPrice,
      'predictedPrice': predictedPrice,
      'savingsIfWait': max(0.0, currentPrice - predictedPrice),
      'trend': trend,
    };
  }

  double _weightedMovingAverage(List<double> prices) {
    if (prices.length >= 3) {
      final latest = prices[prices.length - 1];
      final previous = prices[prices.length - 2];
      final older = prices[prices.length - 3];
      final prediction = (0.5 * latest) + (0.3 * previous) + (0.2 * older);
      return prediction.roundToDouble();
    }

    if (prices.length == 2) {
      return ((0.6 * prices[1]) + (0.4 * prices[0])).roundToDouble();
    }

    return prices.last.roundToDouble();
  }

  String _detectTrend(List<double> prices) {
    if (prices.length < 2) return 'STABLE';

    final recentPrices =
        prices.length > 5 ? prices.sublist(prices.length - 5) : prices;

    int upMoves = 0;
    int downMoves = 0;
    double netChange = 0.0;

    for (int i = 1; i < recentPrices.length; i++) {
      final previous = recentPrices[i - 1];
      final current = recentPrices[i];
      if (previous == 0) continue;

      final change = (current - previous) / previous;
      netChange += change;

      if (change > 0.004) {
        upMoves++;
      } else if (change < -0.004) {
        downMoves++;
      }
    }

    if (downMoves > upMoves && netChange < -0.006) return 'DOWN';
    if (upMoves > downMoves && netChange > 0.006) return 'UP';
    return 'STABLE';
  }

  String _trendMessage(String trend) {
    switch (trend) {
      case 'DOWN':
        return 'Best time to buy';
      case 'UP':
        return 'Wait before buying';
      default:
        return 'Price stable';
    }
  }

  double _calculateConfidence(int points) {
    if (points < 3) return 0.4;
    if (points < 7) return 0.65;
    if (points < 15) return 0.8;
    return 0.9;
  }
}

final pricePredictionService = PricePredictionService();
