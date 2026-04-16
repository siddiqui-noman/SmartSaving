import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import '../models/tracked_product.dart';

class StorageService {
  static const _userKey = 'smart_saving_user';
  static const _tokenKey = 'smart_saving_token';
  static const _trackedProductsKey = 'smart_saving_tracked_products';
  static const _priceHistoryKey = 'smart_saving_price_history';
  static const _targetPricesKey = 'smart_saving_target_prices';
  static const _recentSearchesKey = 'smart_saving_recent_searches';

  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String _scoped(String baseKey) {
    final user = getUser();
    if (user != null) {
      return '${user.id}_$baseKey';
    }
    return baseKey;
  }

  // User management
  Future<void> saveUser(User user, String token) async {
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
    await _prefs.setString(_tokenKey, token);
  }

  User? getUser() {
    final json = _prefs.getString(_userKey);
    if (json == null) return null;
    try {
      return User.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  String? getToken() {
    return _prefs.getString(_tokenKey);
  }

  Future<void> clearUser() async {
    await _prefs.remove(_userKey);
    await _prefs.remove(_tokenKey);
  }

  // Recent Searches
  Future<void> saveRecentSearches(List<String> searches) async {
    await _prefs.setStringList(_scoped(_recentSearchesKey), searches);
  }

  List<String> getRecentSearches() {
    return _prefs.getStringList(_scoped(_recentSearchesKey)) ?? [];
  }

  // Tracked products
  Future<void> saveTrackedProducts(List<String> productIds) async {
    await _prefs.setStringList(_scoped(_trackedProductsKey), productIds);
  }

  List<String> getTrackedProducts() {
    return _prefs.getStringList(_scoped(_trackedProductsKey)) ?? [];
  }

  Future<void> addTrackedProduct(String productId) async {
    final products = getTrackedProducts();
    if (!products.contains(productId)) {
      products.add(productId);
      await saveTrackedProducts(products);
    }
  }

  Future<void> removeTrackedProduct(String productId) async {
    final products = getTrackedProducts();
    products.remove(productId);
    await saveTrackedProducts(products);
  }

  bool isProductTracked(String productId) {
    return getTrackedProducts().contains(productId);
  }

  Future<void> savePriceHistory(
    String productId,
    List<PriceSnapshot> history,
  ) async {
    final historyMap = _readJsonMap(_scoped(_priceHistoryKey));
    historyMap[productId] = history.map((snapshot) => snapshot.toJson()).toList();
    await _prefs.setString(_scoped(_priceHistoryKey), jsonEncode(historyMap));
  }

  List<PriceSnapshot> getPriceHistory(String productId) {
    final historyMap = _readJsonMap(_scoped(_priceHistoryKey));
    final rawHistory = historyMap[productId];
    if (rawHistory is! List) return [];

    return rawHistory.whereType<Map>().map((entry) {
      return PriceSnapshot.fromJson(Map<String, dynamic>.from(entry));
    }).toList();
  }

  Future<void> removePriceHistory(String productId) async {
    final historyMap = _readJsonMap(_scoped(_priceHistoryKey));
    historyMap.remove(productId);
    await _prefs.setString(_scoped(_priceHistoryKey), jsonEncode(historyMap));
  }

  Future<void> saveTargetPrice(String productId, double targetPrice) async {
    final targetMap = _readJsonMap(_scoped(_targetPricesKey));
    targetMap[productId] = targetPrice;
    await _prefs.setString(_scoped(_targetPricesKey), jsonEncode(targetMap));
  }

  double? getTargetPrice(String productId) {
    final targetMap = _readJsonMap(_scoped(_targetPricesKey));
    final value = targetMap[productId];
    return (value as num?)?.toDouble();
  }

  Map<String, double> getAllTargetPrices() {
    final targetMap = _readJsonMap(_scoped(_targetPricesKey));
    return targetMap.map((key, value) {
      return MapEntry(key, (value as num?)?.toDouble() ?? 0.0);
    });
  }

  Future<void> removeTargetPrice(String productId) async {
    final targetMap = _readJsonMap(_scoped(_targetPricesKey));
    targetMap.remove(productId);
    await _prefs.setString(_scoped(_targetPricesKey), jsonEncode(targetMap));
  }

  // Generic key-value storage
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  Future<void> setDouble(String key, double value) async {
    await _prefs.setDouble(key, value);
  }

  double? getDouble(String key) {
    return _prefs.getDouble(key);
  }

  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  Future<void> clear() async {
    await _prefs.clear();
  }

  Map<String, dynamic> _readJsonMap(String key) {
    final rawValue = _prefs.getString(key);
    if (rawValue == null || rawValue.isEmpty) return {};

    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
      return {};
    } catch (_) {
      return {};
    }
  }
}

final storageService = StorageService();
