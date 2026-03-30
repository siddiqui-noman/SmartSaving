import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  bool _isInitialized = false;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal() {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: android, iOS: iOS);

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {},
    );

    _isInitialized = true;
  }

  bool shouldTriggerPriceDropAlert({
    required double currentPrice,
    required List<double> historicalBestPrices,
    int lookbackDays = 7,
  }) {
    if (historicalBestPrices.isEmpty || currentPrice <= 0) return false;

    final lookback = historicalBestPrices.length < lookbackDays
        ? historicalBestPrices
        : historicalBestPrices.sublist(
            historicalBestPrices.length - lookbackDays,
          );

    final averagePrice = lookback.reduce((a, b) => a + b) / lookback.length;
    return currentPrice < averagePrice;
  }

  double averagePriceOfLastDays(
    List<double> historicalBestPrices, {
    int lookbackDays = 7,
  }) {
    if (historicalBestPrices.isEmpty) return 0.0;

    final lookback = historicalBestPrices.length < lookbackDays
        ? historicalBestPrices
        : historicalBestPrices.sublist(
            historicalBestPrices.length - lookbackDays,
          );
    return lookback.reduce((a, b) => a + b) / lookback.length;
  }

  Future<void> showPriceDropNotification({
    required String productName,
    required String oldPrice,
    required String newPrice,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'price_drop_channel',
      'Price Drop Notifications',
      channelDescription: 'Notifications for product price drops',
      importance: Importance.defaultImportance,
      priority: Priority.high,
    );

    const iOSDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iOSDetails);

    await _flutterLocalNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Price Dropped',
      body: '$productName: $oldPrice -> $newPrice',
      notificationDetails: details,
      payload: 'price_drop',
    );
  }

  Future<void> showAlertTriggered({
    required String productName,
    required String targetPrice,
    required String currentPrice,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'price_alert_channel',
      'Price Alerts',
      channelDescription: 'Notifications for price alerts',
      importance: Importance.defaultImportance,
      priority: Priority.high,
    );

    const iOSDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iOSDetails);

    await _flutterLocalNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Alert Triggered',
      body: '$productName is now Rs$currentPrice (Target: Rs$targetPrice)',
      notificationDetails: details,
      payload: 'price_alert',
    );
  }

  Future<void> showGenericNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'generic_channel',
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.defaultImportance,
    );

    const iOSDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iOSDetails);

    await _flutterLocalNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
      payload: 'generic',
    );
  }
}

final notificationService = NotificationService();
