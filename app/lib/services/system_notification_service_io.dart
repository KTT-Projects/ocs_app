import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum SystemNotificationPermission {
  unsupported,
  prompt,
  granted,
  denied,
}

class SystemNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
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
    _initialized = true;
  }

  Future<SystemNotificationPermission> permissionStatus() async {
    await initialize();

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final enabled = await android?.areNotificationsEnabled();
      return enabled == false
          ? SystemNotificationPermission.denied
          : SystemNotificationPermission.granted;
    }

    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final permissions = await ios?.checkPermissions();
      if (permissions == null) return SystemNotificationPermission.prompt;
      if (permissions.isEnabled == true || permissions.isAlertEnabled == true) {
        return SystemNotificationPermission.granted;
      }
      return SystemNotificationPermission.prompt;
    }

    return SystemNotificationPermission.unsupported;
  }

  Future<SystemNotificationPermission> requestPermission() async {
    await initialize();

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      if (granted == false) return SystemNotificationPermission.denied;
      return SystemNotificationPermission.granted;
    }

    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (granted == true) return SystemNotificationPermission.granted;
      return SystemNotificationPermission.denied;
    }

    return SystemNotificationPermission.unsupported;
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();

    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    var permission = await permissionStatus();
    if (permission == SystemNotificationPermission.prompt) {
      permission = await requestPermission();
    }
    if (permission != SystemNotificationPermission.granted) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'ocs_app_activity',
      'Community activity',
      channelDescription: 'Updates from feeds, events, volunteer, and study',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Community activity',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }
}
