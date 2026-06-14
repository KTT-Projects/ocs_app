import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class AppFirebaseOptions {
  static const webVapidKey = String.fromEnvironment(
    'FCM_WEB_VAPID_KEY',
    defaultValue:
        'BAPhrgDnMJXC7-_keBzkh31BdVIhOsHQjV2njPABc-m-zL2lwM_mVfvY1s6Iuz6i5KXzoXayxLjjX1PXECjyiIg',
  );

  static const _projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'shineportal-ktt',
  );
  static const _messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '299843107216',
  );
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _authDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: 'shineportal-ktt.firebaseapp.com',
  );
  static const _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'shineportal-ktt.appspot.com',
  );
  static const _measurementId = String.fromEnvironment(
    'FIREBASE_MEASUREMENT_ID',
    defaultValue: 'G-6YRL4BN758',
  );

  static const _webApiKey = String.fromEnvironment(
    'FIREBASE_WEB_API_KEY',
    defaultValue: 'AIzaSyC629rx4zPZOF_WsShGUW219UZyYE5kZdQ',
  );
  static const _webAppId = String.fromEnvironment(
    'FIREBASE_WEB_APP_ID',
    defaultValue: '1:299843107216:web:e06d18c6e193209491db15',
  );
  static const _webAuthDomain = String.fromEnvironment(
    'FIREBASE_WEB_AUTH_DOMAIN',
    defaultValue: 'shineportal-ktt.firebaseapp.com',
  );
  static const _webStorageBucket = String.fromEnvironment(
    'FIREBASE_WEB_STORAGE_BUCKET',
    defaultValue: 'shineportal-ktt.appspot.com',
  );
  static const _webMeasurementId = String.fromEnvironment(
    'FIREBASE_WEB_MEASUREMENT_ID',
    defaultValue: 'G-6YRL4BN758',
  );

  static const _androidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
    defaultValue: 'AIzaSyCelXTlpJfr353id-iCrxkLIAUd8svUiaQ',
  );
  static const _androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
    defaultValue: '1:299843107216:android:960befb2171ac87291db15',
  );

  static const _iosApiKey = String.fromEnvironment(
    'FIREBASE_IOS_API_KEY',
    defaultValue: 'AIzaSyAqKF76VXxta31PfrwBv8SWL5upE24aVV8',
  );
  static const _iosAppId = String.fromEnvironment(
    'FIREBASE_IOS_APP_ID',
    defaultValue: '1:299843107216:ios:d6c6de52da0b6caf91db15',
  );
  static const _iosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
    defaultValue: 'com.kttprojects.kamiLander',
  );

  static FirebaseOptions? get currentPlatform {
    if (kIsWeb) {
      return _buildOptions(
        apiKey: _prefer(_webApiKey, _apiKey),
        appId: _prefer(_webAppId, _appId),
        authDomain: _prefer(_webAuthDomain, _authDomain),
        storageBucket: _prefer(_webStorageBucket, _storageBucket),
        measurementId: _prefer(_webMeasurementId, _measurementId),
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _buildOptions(
          apiKey: _prefer(_androidApiKey, _apiKey),
          appId: _prefer(_androidAppId, _appId),
          authDomain: _authDomain,
          storageBucket: _storageBucket,
          measurementId: _measurementId,
        );
      case TargetPlatform.iOS:
        return _buildOptions(
          apiKey: _prefer(_iosApiKey, _apiKey),
          appId: _prefer(_iosAppId, _appId),
          authDomain: _authDomain,
          storageBucket: _storageBucket,
          measurementId: _measurementId,
          iosBundleId: _iosBundleId,
        );
      default:
        return null;
    }
  }

  static FirebaseOptions? _buildOptions({
    required String apiKey,
    required String appId,
    required String authDomain,
    required String storageBucket,
    required String measurementId,
    String iosBundleId = '',
  }) {
    if (apiKey.isEmpty ||
        appId.isEmpty ||
        _messagingSenderId.isEmpty ||
        _projectId.isEmpty) {
      return null;
    }

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: _messagingSenderId,
      projectId: _projectId,
      authDomain: authDomain.isEmpty ? null : authDomain,
      storageBucket: storageBucket.isEmpty ? null : storageBucket,
      measurementId: measurementId.isEmpty ? null : measurementId,
      iosBundleId: iosBundleId.isEmpty ? null : iosBundleId,
    );
  }

  static String _prefer(String primary, String fallback) {
    return primary.isNotEmpty ? primary : fallback;
  }
}
