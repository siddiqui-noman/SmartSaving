import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/user.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class AuthService {
  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<void> initialize() async {
    await storageService.initialize();
    _currentUser = storageService.getUser();
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // Validation
      if (email.isEmpty || password.isEmpty) {
        return {'success': false, 'message': 'Email and password are required'};
      }

      if (!email.contains('@')) {
        return {'success': false, 'message': 'Invalid email format'};
      }

      if (password.length < 6) {
        return {
          'success': false,
          'message': 'Password must be at least 6 characters',
        };
      }

      // Real HTTP request to login
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data['user']);
        final token = data['access_token'];

        await storageService.saveUser(user, token);
        _currentUser = user;

        return {'success': true, 'user': user, 'token': token};
      } else {
        final errorData = jsonDecode(response.body);
        final detail = errorData['detail'] ?? 'Login failed';
        return {'success': false, 'message': detail};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String name,
  ) async {
    try {
      // Validation
      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        return {'success': false, 'message': 'All fields are required'};
      }

      if (!email.contains('@')) {
        return {'success': false, 'message': 'Invalid email format'};
      }

      if (password.length < 6) {
        return {
          'success': false,
          'message': 'Password must be at least 6 characters',
        };
      }

      if (name.length < 2) {
        return {
          'success': false,
          'message': 'Name must be at least 2 characters',
        };
      }

      // Real HTTP request to register
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
        }),
      );

      if (response.statusCode == 200) {
         final data = jsonDecode(response.body);
         final user = User.fromJson(data['user']);
         final token = data['access_token'];

         await storageService.saveUser(user, token);
         _currentUser = user;

         return {'success': true, 'user': user, 'token': token};
       } else {
         final errorData = jsonDecode(response.body);
         final detail = errorData['detail'] ?? 'Registration failed';
         return {'success': false, 'message': detail};
       }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<void> logout() async {
    await storageService.clearUser();
    _currentUser = null;
  }

  Future<bool> checkAuthStatus() async {
    final user = storageService.getUser();
    final token = storageService.getToken();

    if (user != null && token != null) {
      _currentUser = user;
      return true;
    }
    return false;
  }
}

final authService = AuthService();
