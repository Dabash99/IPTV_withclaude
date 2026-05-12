import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _episodeChannelId = 'new_episodes';
  static const _episodeChannelName = 'New Episodes';
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: androidInit));
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _episodeChannelId,
          _episodeChannelName,
          importance: Importance.high,
        ));
    _initialized = true;
  }

  static Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showNewEpisode({
    required int notificationId,
    required String seriesName,
    required int newCount,
    required bool isArabic,
  }) async {
    final title = isArabic
        ? (newCount == 1 ? 'حلقة جديدة' : '$newCount حلقات جديدة')
        : (newCount == 1 ? 'New Episode' : '$newCount New Episodes');

    await _plugin.show(
      notificationId,
      title,
      seriesName,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _episodeChannelId,
          _episodeChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
