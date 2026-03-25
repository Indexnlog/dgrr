import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationsService {
  LocalNotificationsService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _defaultChannelId = 'fcm_foreground';
  static const String _defaultChannelName = '인앱 알림';
  static const String _defaultChannelDescription = '앱 사용 중 수신된 알림을 표시합니다.';

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (kIsWeb || _initialized) return;
    _initialized = true;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    await _createAndroidDefaultChannel();
  }

  static Future<void> requestPermissions() async {
    if (kIsWeb) return;

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    final macos = _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();
    await macos?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  static Future<void> showForegroundNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _defaultChannelId,
        _defaultChannelName,
        channelDescription: _defaultChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title,
      body,
      details,
    );
  }

  static Future<void> _createAndroidDefaultChannel() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    const channel = AndroidNotificationChannel(
      _defaultChannelId,
      _defaultChannelName,
      description: _defaultChannelDescription,
      importance: Importance.high,
    );
    await android.createNotificationChannel(channel);
  }
}

