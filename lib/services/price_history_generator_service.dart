import 'dart:math';

class PriceHistoryGeneratorService {
  static const double _maxDailySwing = 0.02; // +/-2%

  double generateNextPrice({
    required double previousPrice,
    required String seedKey,
    double downwardBias = -0.002,
  }) {
    final random = Random(seedKey.hashCode);
    final dailySwing = (random.nextDouble() * 2 * _maxDailySwing) - _maxDailySwing;

    double specialEvent = 0.0;
    final eventRoll = random.nextDouble();

    // Sale event: occasional larger drop.
    if (eventRoll < 0.1) {
      specialEvent = -(0.04 + random.nextDouble() * 0.08); // 4% to 12% drop
    } else if (eventRoll > 0.93) {
      // Demand spike: occasional larger increase.
      specialEvent = 0.02 + random.nextDouble() * 0.05; // 2% to 7% increase
    }

    final nextPrice = previousPrice * (1 + dailySwing + downwardBias + specialEvent);
    return _roundPrice(max(100.0, nextPrice));
  }

  List<double> generateForwardHistory({
    required List<double> existingHistory,
    required int days,
    required String seedPrefix,
    double downwardBias = -0.002,
    int maxPoints = 90,
  }) {
    if (existingHistory.isEmpty || days <= 0) {
      return List<double>.from(existingHistory);
    }

    final updated = List<double>.from(existingHistory);
    for (int day = 0; day < days; day++) {
      final previous = updated.last;
      final nextPrice = generateNextPrice(
        previousPrice: previous,
        seedKey: '${seedPrefix}_$day',
        downwardBias: downwardBias,
      );
      updated.add(nextPrice);
    }

    if (updated.length > maxPoints) {
      return updated.sublist(updated.length - maxPoints);
    }
    return updated;
  }

  double _roundPrice(double value) {
    return value.roundToDouble();
  }
}

final priceHistoryGeneratorService = PriceHistoryGeneratorService();
