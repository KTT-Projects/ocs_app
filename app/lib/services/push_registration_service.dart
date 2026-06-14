import 'dart:async';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'firebase_options.dart';
import 'web_push_token_provider.dart';

class PushRegistrationService {
  PushRegistrationService({required ApiClient apiClient})
      : _apiClient = apiClient;

  static const _deviceIdKey = 'push_device_id';
  static const _lastTokenKey = 'push_last_fcm_token';

  final ApiClient _apiClient;

  SharedPreferences? _prefs;
  StreamSubscription<String>? _tokenRefreshSub;
  bool _initialized = false;
  bool _firebaseReady = false;
  bool _registering = false;
  String? _lastLocale;

  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _firebaseReady = await _initializeFirebase();

    if (_firebaseReady && !kIsWeb) {
      if (_isIos) {
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(
        (token) {
          unawaited(_registerToken(token, locale: _lastLocale));
        },
        onError: (Object error) {
          debugPrint('FCM token refresh failed: $error');
        },
      );
    }

    _initialized = true;
  }

  Future<void> registerCurrentDevice({
    String? locale,
    bool requestPermission = true,
  }) async {
    await initialize();
    _lastLocale = locale ?? _lastLocale;
    if (!_firebaseReady || _apiClient.token == null || _registering) return;

    final platform = _platform;
    if (platform == null) return;

    _registering = true;
    try {
      if (requestPermission && kIsWeb) {
        if (!await requestWebNotificationPermission()) {
          return;
        }
      } else if (requestPermission) {
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          return;
        }
      }

      if (_isIos && !await _waitForApnsToken()) {
        return;
      }

      final token = await _getFcmToken();
      if (token == null || token.isEmpty) return;

      await _registerToken(token, locale: _lastLocale);
    } catch (error) {
      debugPrint('Push device registration failed: $error');
    } finally {
      _registering = false;
    }
  }

  Future<void> unregisterCurrentDevice() async {
    await initialize();
    if (_apiClient.token == null) return;

    final token = _prefs?.getString(_lastTokenKey);
    final deviceId = await _deviceId;
    if ((token == null || token.isEmpty) && deviceId.isEmpty) return;

    try {
      await _apiClient.unregisterPushDevice(
        token: token,
        deviceId: deviceId,
      );
      await _prefs?.remove(_lastTokenKey);
    } catch (error) {
      debugPrint('Push device unregister failed: $error');
    }
  }

  Future<void> _registerToken(String token, {String? locale}) async {
    final platform = _platform;
    if (platform == null || _apiClient.token == null) return;

    final deviceId = await _deviceId;
    await _apiClient.registerPushDevice(
      platform: platform,
      token: token,
      deviceId: deviceId,
      locale: locale,
    );
    await _prefs?.setString(_lastTokenKey, token);
  }

  Future<String?> _getFcmToken() {
    if (kIsWeb) {
      if (AppFirebaseOptions.webVapidKey.isEmpty) {
        debugPrint('FCM web VAPID key is not configured.');
        return Future<String?>.value(null);
      }
      return getWebFcmToken(AppFirebaseOptions.webVapidKey);
    }
    return FirebaseMessaging.instance.getToken();
  }

  Future<bool> _waitForApnsToken() async {
    for (var attempt = 0; attempt < 8; attempt++) {
      final token = await FirebaseMessaging.instance.getAPNSToken();
      if (token != null && token.isNotEmpty) return true;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    debugPrint('APNs token was not available yet; skipping FCM registration.');
    return false;
  }

  Future<bool> _initializeFirebase() async {
    try {
      if (Firebase.apps.isNotEmpty) return true;

      final options = AppFirebaseOptions.currentPlatform;
      if (kIsWeb) {
        return options != null;
      }
      if (options != null) {
        await Firebase.initializeApp(options: options);
      } else {
        if (kIsWeb) {
          debugPrint('Firebase web options are not configured.');
          return false;
        }
        await Firebase.initializeApp();
      }
      return true;
    } catch (error) {
      debugPrint('Firebase initialization skipped: $error');
      return false;
    }
  }

  Future<String> get _deviceId async {
    final existing = _prefs?.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    Random random;
    try {
      random = Random.secure();
    } catch (_) {
      random = Random();
    }
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final generated =
        bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    await _prefs?.setString(_deviceIdKey, generated);
    return generated;
  }

  bool get _isIos {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  }

  String? get _platform {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return null;
    }
  }

  void dispose() {
    unawaited(_tokenRefreshSub?.cancel());
  }
}
