enum SystemNotificationPermission {
  unsupported,
  prompt,
  granted,
  denied,
}

class SystemNotificationService {
  Future<void> initialize() async {}

  Future<SystemNotificationPermission> permissionStatus() async {
    return SystemNotificationPermission.unsupported;
  }

  Future<SystemNotificationPermission> requestPermission() async {
    return SystemNotificationPermission.unsupported;
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {}
}
