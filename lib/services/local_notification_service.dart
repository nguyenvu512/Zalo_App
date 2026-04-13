import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance =
  LocalNotificationService._internal();

  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    print("=== LocalNotificationService init start ===");

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(initSettings);
    print("=== plugin initialized ===");

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    print("=== androidPlugin: $androidPlugin ===");

    final granted = await androidPlugin?.requestNotificationsPermission();
    print("=== Notification permission: $granted ===");
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    print("SHOW NOTIFICATION: $title | $body");

    const androidDetails = AndroidNotificationDetails(
      'zalo_channel',
      'Zalo Notifications',
      channelDescription: 'Thông báo tin nhắn và hệ thống',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      ticker: 'ticker',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
    );
  }
}