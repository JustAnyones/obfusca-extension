import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// TODO: switch to string enums
List<String> locales = ['en', 'lt'];
List<String> regions = ['us', 'lt'];

class SettingProvider extends ChangeNotifier {
  static const String _keyLocale = 'locale';
  static const String _keyRegion = 'region';

  static final SettingProvider _instance = SettingProvider._internal();
  static SharedPreferences? _prefs;

  // Private constructor
  SettingProvider._internal() {
    // print("Singleton Instance Created");
  }

  factory SettingProvider() {
    return _instance;
  }

  // Locale
  String _locale = locales[0];
  Locale get locale => Locale(_locale);
  String get localeAsString => _locale;

  // Region
  String _region = regions[0];
  String get region => _region;

  static SettingProvider getInstance() {
    return _instance;
  }

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    _locale = await getString(_keyLocale, locales[0]);
    _region = await getString(_keyRegion, regions[0]);
  }

  Future<void> setLocale(String value) async {
    await _prefs!.setString(_keyLocale, value);
    _locale = value;
    notifyListeners();
  }

  Future<void> setRegion(String value) async {
    await _prefs!.setString(_keyRegion, value);
    _region = value;
    notifyListeners();
  }

  Future<String> getString(String key, String defaultValue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? defaultValue;
  }
}
