import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class AuthService {
  static const String _tokenKey = 'auth_token';
  static final AuthService _instance = AuthService._internal();
  
  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  Future<void> saveToken(String token) async {
    if (kIsWeb) {
      html.window.localStorage[_tokenKey] = token;
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    }
  }

  Future<String?> getToken() async {
    if (kIsWeb) {
      return html.window.localStorage[_tokenKey];
    } else {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    }
  }

  Future<void> clearToken() async {
    if (kIsWeb) {
      html.window.localStorage.remove(_tokenKey);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    }
  }
}
