import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  late String _currentLanguage;
  final SharedPreferences _prefs;

  LanguageProvider(this._prefs) {
    _currentLanguage = _prefs.getString(_languageKey) ?? 'en';
  }

  String get currentLanguage => _currentLanguage;

  Locale get locale => Locale(_currentLanguage);

  Future<void> setLanguage(String languageCode) async {
    if (_currentLanguage != languageCode) {
      _currentLanguage = languageCode;
      await _prefs.setString(_languageKey, languageCode);
      notifyListeners();
    }
  }
}
