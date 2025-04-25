import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyUserToken = 'user.token';
const String _keyUserTokenExpire = 'user.tokenExpire';

const String _keyEmailAddresses = 'user.email.addresses';

class UserProvider extends ChangeNotifier {
  static final UserProvider _instance = UserProvider._internal();
  static SharedPreferences? _prefs;

  UserProvider._internal();

  factory UserProvider() {
    return _instance;
  }

  static UserProvider getInstance() {
    return _instance;
  }

  String? _userToken;
  String? get userToken => _userToken;
  DateTime? _userTokenExpire;
  DateTime? get userTokenExpire => _userTokenExpire;

  List<String> _emailAddresses = [];
  List<String> get emailAddresses => _emailAddresses;

  bool get isLoggedIn =>
      _userToken != null &&
      _userTokenExpire != null &&
      _userTokenExpire!.isAfter(DateTime.now());

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    _userToken = await getString(_keyUserToken, null);
    _userTokenExpire = await getDateTime(_keyUserTokenExpire, null);
    _emailAddresses = await _getEmailAddresses() ?? [];
  }

  Future<void> setUserToken(String token, DateTime expire) async {
    await _prefs!.setString(_keyUserToken, token);
    await _prefs!.setString(_keyUserTokenExpire, expire.toString());
    _userToken = token;
    _userTokenExpire = expire;
    notifyListeners();
  }

  Future<void> clearUserToken() async {
    await _prefs!.remove(_keyUserToken);
    await _prefs!.remove(_keyUserTokenExpire);
    _userToken = null;
    _userTokenExpire = null;
    notifyListeners();
  }

  // Sets the list of email addresses in the SharedPreferences.
  Future<void> setEmailAddresses(List<String> emails) async {
    await _prefs!.setStringList(_keyEmailAddresses, emails);
    _emailAddresses = emails;
    notifyListeners();
  }

  // Returns the list of email addresses from the SharedPreferences.
  Future<List<String>?> _getEmailAddresses() async {
    return _prefs!.getStringList(_keyEmailAddresses);
  }

  Future<String?> getString(String key, String? defaultValue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? defaultValue;
  }

  Future<DateTime?> getDateTime(String key, DateTime? defaultValue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var value = prefs.getString(key);
    if (value == null) {
      return defaultValue;
    }
    return DateTime.parse(value);
  }
}
