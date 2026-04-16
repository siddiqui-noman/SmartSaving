import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/product.dart';
import '../models/tracked_product.dart';
import 'api_config.dart';
import 'amazon_service.dart';
import 'flipkart_service.dart';
import 'dart:math';

class ChatHistoryEntry {
  const ChatHistoryEntry({
    required this.role,
    required this.message,
  });

  final String role;
  final String message;

  Map<String, dynamic> toJson() => {
        'role': role,
        'message': message,
      };
}

class ChatService {
  ChatService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _chatTimeout = Duration(seconds: 25);

  Future<String> sendMessage({
    required String message,
    Product? product,
    TrackedProduct? trackedProduct,
    List<ChatHistoryEntry> history = const [],
  }) async {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      throw const ChatServiceException('Please enter a message.');
    }

    try {
      final response = await _client
          .post(
            Uri.parse(ApiConfig.chatApiUrl),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(
              _buildPayload(
                message: trimmedMessage,
                product: product,
                trackedProduct: trackedProduct,
                history: history,
              ),
            ),
          )
          .timeout(_chatTimeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is! Map<String, dynamic>) {
          throw const ChatServiceException(
            'Invalid response from server. Please try again.',
          );
        }

        final reply = body['reply']?.toString().trim();
        if (reply == null || reply.isEmpty) {
          throw const ChatServiceException(
            'Assistant returned an empty response.',
          );
        }
        return reply;
      }

      throw ChatServiceException(_mapHttpError(response));
    } on TimeoutException {
      throw ChatServiceException(_timeoutMessage());
    } on SocketException {
      throw const ChatServiceException(
        'Network error. Check your internet connection.',
      );
    } on http.ClientException {
      throw const ChatServiceException(
        'Unable to reach assistant service. Verify backend URL and connectivity.',
      );
    } on FormatException {
      throw const ChatServiceException(
        'Invalid response from server. Please try again.',
      );
    }
  }

  Map<String, dynamic> _buildPayload({
    required String message,
    Product? product,
    TrackedProduct? trackedProduct,
    required List<ChatHistoryEntry> history,
  }) {
    // General mode — no product context
    if (product == null) {
      return {
        'message': message,
        'is_general_mode': true,
        'conversation_history':
            history.take(6).map((e) => e.toJson()).toList(),
      };
    }

    var priceHistory = trackedProduct?.priceHistory ?? const <PriceSnapshot>[];
    
    // Generate temporary insight data on the fly if the item isn't tracked yet!
    if (priceHistory.isEmpty) {
      priceHistory = _generateTemporaryHistory(product);
    }

    final bestPriceSeries =
        priceHistory.map((snapshot) => snapshot.bestPrice).toList();
    final recentPriceHistory = priceHistory.length <= 14
        ? priceHistory
        : priceHistory.sublist(priceHistory.length - 14);

    return {
      'message': message,
      'product_id': product.id,
      'product_name': product.name,
      'category': product.category,
      'current_price': product.bestPrice,
      'amazon_price': product.amazonPrice,
      'flipkart_price': product.flipkartPrice,
      'best_platform': product.bestPlatform,
      'best_price': product.bestPrice,
      'price_difference': product.priceDifference,
      'savings_percentage': product.savingsPercentage,
      'rating': product.rating,
      'reviews': product.reviews,
      'is_tracked': trackedProduct != null,
      'target_price': trackedProduct?.targetPrice,
      'updated_at': product.updatedAt.toIso8601String(),
      'conversation_history':
          history.take(6).map((entry) => entry.toJson()).toList(),
      'price_history': recentPriceHistory
          .map(
            (snapshot) => {
              'timestamp': snapshot.timestamp.toIso8601String(),
              'amazon_price': snapshot.amazonPrice,
              'flipkart_price': snapshot.flipkartPrice,
              'best_price': snapshot.bestPrice,
            },
          )
          .toList(),
      'history_summary': {
        'points': bestPriceSeries.length,
        'latest_best_price':
            bestPriceSeries.isEmpty ? null : bestPriceSeries.last,
        'average_best_price_7d': _averageLast(bestPriceSeries, 7),
        'average_best_price_30d': _averageLast(bestPriceSeries, 30),
        'lowest_best_price_30d': _minLast(bestPriceSeries, 30),
        'highest_best_price_30d': _maxLast(bestPriceSeries, 30),
        'trend_7d': _trendLast(bestPriceSeries, 7),
      },
    };
  }

  List<PriceSnapshot> _generateTemporaryHistory(Product product) {
    try {
      final amazonHistory = amazonService.getPriceHistory(product.id);
      final flipkartHistory = flipkartService.getPriceHistory(product.id);
      final count = min(amazonHistory.length, flipkartHistory.length);

      if (count == 0) return [];

      final now = DateTime.now();
      final endDate = DateTime(now.year, now.month, now.day);
      final startDate = endDate.subtract(Duration(days: count - 1));

      return List.generate(count, (index) {
        return PriceSnapshot(
          amazonPrice: amazonHistory[index],
          flipkartPrice: flipkartHistory[index],
          timestamp: startDate.add(Duration(days: index)),
        );
      });
    } catch (_) {
      return [];
    }
  }

  double? _averageLast(List<double> values, int count) {
    if (values.isEmpty) return null;
    final window = values.length <= count
        ? values
        : values.sublist(values.length - count);
    return window.reduce((a, b) => a + b) / window.length;
  }

  double? _minLast(List<double> values, int count) {
    if (values.isEmpty) return null;
    final window = values.length <= count
        ? values
        : values.sublist(values.length - count);
    return window.reduce((a, b) => a < b ? a : b);
  }

  double? _maxLast(List<double> values, int count) {
    if (values.isEmpty) return null;
    final window = values.length <= count
        ? values
        : values.sublist(values.length - count);
    return window.reduce((a, b) => a > b ? a : b);
  }

  String? _trendLast(List<double> values, int count) {
    if (values.length < 2) return null;
    final window = values.length <= count
        ? values
        : values.sublist(values.length - count);
    if (window.length < 2) return null;

    final first = window.first;
    final last = window.last;
    if (first <= 0) return null;

    final delta = (last - first) / first;
    if (delta > 0.01) return 'up';
    if (delta < -0.01) return 'down';
    return 'stable';
  }

  String _timeoutMessage() {
    return 'Assistant request timed out. If your backend is running on another machine, set --dart-define=BACKEND_BASE_URL=http://<host>:8000 and try again.';
  }

  String _mapHttpError(http.Response response) {
    final serverMessage = _tryParseServerMessage(response.body);
    if (serverMessage != null && serverMessage.isNotEmpty) {
      return serverMessage;
    }

    switch (response.statusCode) {
      case 400:
        return 'Please provide a valid chat request.';
      case 404:
        return 'Assistant endpoint not found.';
      case 502:
        return 'Assistant model is temporarily unavailable. Please retry.';
      case 500:
        return 'Assistant service is not configured correctly. Check backend logs.';
      default:
        return 'Unable to fetch assistant response (HTTP ${response.statusCode}).';
    }
  }

  String? _tryParseServerMessage(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        final detail = data['detail']?.toString().trim();
        if (detail != null && detail.isNotEmpty) {
          return detail;
        }
        final responseMessage = data['message']?.toString().trim();
        if (responseMessage != null && responseMessage.isNotEmpty) {
          return responseMessage;
        }
      }
    } catch (_) {
      // Ignore parse failures and fallback to status-code based messages.
    }
    return null;
  }
}

class ChatServiceException implements Exception {
  const ChatServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

final chatService = ChatService();
