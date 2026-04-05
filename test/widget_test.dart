import 'package:flutter_test/flutter_test.dart';

import 'package:smartsaving/models/product.dart';

void main() {
  test('Product computes best price fields correctly', () {
    final product = Product(
      id: 'prod_001',
      name: 'Test Product',
      category: 'Electronics',
      description: 'Test description',
      imageUrl: 'https://example.com/image.png',
      amazonPrice: 54999,
      flipkartPrice: 52999,
      rating: 4.5,
      reviews: 1200,
      updatedAt: DateTime(2026, 4, 4),
    );

    expect(product.bestPrice, 52999);
    expect(product.bestPlatform, 'Flipkart');
    expect(product.priceDifference, 2000);
    expect(product.savingsAmount, 2000);
  });
}
