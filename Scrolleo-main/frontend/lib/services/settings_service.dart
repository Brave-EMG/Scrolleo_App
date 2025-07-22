import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  String _language = 'fr';
  ThemeMode _themeMode = ThemeMode.dark;
  bool _mobileDataEnabled = false;

  String get language => _language;
  ThemeMode get themeMode => _themeMode;
  bool get mobileDataEnabled => _mobileDataEnabled;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString('language') ?? 'fr';
    _themeMode = ThemeMode.values[prefs.getInt('theme_mode') ?? 2]; // 2 = ThemeMode.dark
    _mobileDataEnabled = prefs.getBool('mobile_data_enabled') ?? false;
    notifyListeners();
    }

  Future<void> setLanguage(String language) async {
    _language = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    notifyListeners();
  }

  Future<void> setMobileDataEnabled(bool enabled) async {
    _mobileDataEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mobile_data_enabled', enabled);
    notifyListeners();
  }
} 