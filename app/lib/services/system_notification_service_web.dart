import 'dart:html' as html;

enum SystemNotificationPermission {
  unsupported,
  prompt,
  granted,
  denied,
}

class SystemNotificationService {
  Future<void> initialize() async {}

  Future<SystemNotificationPermission> permissionStatus() async {
    if (!html.Notification.supported) {
      return SystemNotificationPermission.unsupported;
    }

    switch (html.Notification.permission) {
      case 'granted':
        return SystemNotificationPermission.granted;
      case 'denied':
        return SystemNotificationPermission.denied;
      default:
        return SystemNotificationPermission.prompt;
    }
  }

  Future<SystemNotificationPermission> requestPermission() async {
    if (!html.Notification.supported) {
      return SystemNotificationPermission.unsupported;
    }

    final permission = await html.Notification.requestPermission();
    switch (permission) {
      case 'granted':
        return SystemNotificationPermission.granted;
      case 'denied':
        return SystemNotificationPermission.denied;
      default:
        return SystemNotificationPermission.prompt;
    }
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (await permissionStatus() != SystemNotificationPermission.granted) {
      return;
    }

    html.Notification(
      title,
      body: body,
      tag: payload ?? id.toString(),
      icon: '/icons/Icon-192.png',
    );
  }
}
