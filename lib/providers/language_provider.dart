import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('fr', '');

  Locale get currentLocale => _currentLocale;

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'fr';
    _currentLocale = Locale(languageCode, '');
    notifyListeners();
  }

  Future<void> changeLanguage(String languageCode) async {
    if (_currentLocale.languageCode != languageCode) {
      _currentLocale = Locale(languageCode, '');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', languageCode);

      notifyListeners();
    }
  }

  bool get isFrench => _currentLocale.languageCode == 'fr';
  bool get isEnglish => _currentLocale.languageCode == 'en';
}