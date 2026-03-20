import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class ChatService {
  ChatService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _chatTimeout = Duration(seconds: 10);

  Future<String> sendMessage({
    required String message,
    required int productId,
  }) async {
    if (message.trim().isEmpty) {
      throw const ChatServiceException('Please enter a message.');
    }

    try {
      final response = await _client
          .post(
            Uri.parse(ApiConfig.chatApiUrl),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': message.trim(),
              'product_id': productId,
            }),
          )
          .timeout(_chatTimeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final reply = body['reply']?.toString().trim();
        if (reply == null || reply.isEmpty) {
          throw const ChatServiceException(
            'Assistant returned an empty response.',
          );
        }
        return reply;
      }

      final serverMessage = _tryParseServerMessage(response.body);
      throw ChatServiceException(
        serverMessage ??
            'Unable to fetch assistant response '
                '(HTTP ${response.statusCode}).',
      );
    } on TimeoutException {
      throw ChatServiceException(_timeoutMessage());
    } on SocketException {
      throw const ChatServiceException(
        'Network error. Check your internet connection.',
      );
    } on FormatException {
      throw const ChatServiceException(
        'Invalid response from server. Please try again.',
      );
    }
  }

  String _timeoutMessage() {
    if (ApiConfig.backendBaseUrl.contains('10.0.2.2')) {
      return 'Assistant server is not reachable. If you are using a real device, run with --dart-define=BACKEND_BASE_URL=http://<your-machine-ip>:8000';
    }
    return 'Request timed out. Please try again.';
  }

  String? _tryParseServerMessage(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        return data['detail']?.toString() ?? data['message']?.toString();
      }
    } catch (_) {
      // Ignore parse failures and fallback to generic error.
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
