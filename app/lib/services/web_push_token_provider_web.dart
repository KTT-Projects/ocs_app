import 'dart:html' as html;
import 'dart:js_util' as js_util;

Future<bool> requestWebNotificationPermission() async {
  if (!html.Notification.supported) return false;
  if (html.Notification.permission == 'granted') return true;
  final permission = await html.Notification.requestPermission();
  return permission == 'granted';
}

Future<String?> getWebFcmToken(String vapidKey) async {
  final getToken =
      js_util.getProperty<Object?>(js_util.globalThis, 'kamiGetFcmToken');
  if (getToken == null) return null;
  final token = await js_util.promiseToFuture<Object?>(
    js_util
        .callMethod<Object>(js_util.globalThis, 'kamiGetFcmToken', [vapidKey]),
  );
  return token as String?;
}
