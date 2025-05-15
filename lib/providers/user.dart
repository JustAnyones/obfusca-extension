import 'dart:convert';

import 'package:browser_extension/utils/obfusca.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyUserToken = 'user.token';
const String _keyUserTokenExpire = 'user.tokenExpire';

const String _keyEmailAddresses = 'user.email.addresses';
const String _keyEmailAddressEmails = 'user.email.address.messages';

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

  // {emailAddress: {uid: SlimEmailData}}
  Map<String, Map<int, SlimEmailData>> _emailAddressEmails = {};

  bool get isLoggedIn =>
      _userToken != null &&
      _userTokenExpire != null &&
      _userTokenExpire!.isAfter(DateTime.now());

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    _userToken = await getString(_keyUserToken, null);
    _userTokenExpire = await getDateTime(_keyUserTokenExpire, null);
    _emailAddresses = await _getEmailAddresses() ?? [];
    _emailAddressEmails = await _getMessagesForAllEmailAdresses();
  }

  Future<void> setUserToken(String token, DateTime expire) async {
    await _prefs!.setString(_keyUserToken, token);
    await _prefs!.setString(_keyUserTokenExpire, expire.toString());
    _userToken = token;
    _userTokenExpire = expire;
    notifyListeners();
  }

  Future<void> clearUserState() async {
    await _prefs!.remove(_keyUserToken);
    await _prefs!.remove(_keyUserTokenExpire);
    await _prefs!.remove(_keyEmailAddresses);
    for (var emailAddress in _emailAddresses) {
      var emails = await _getMessagesForEmailAddress(emailAddress);
      for (var email in emails.keys) {
        await _prefs!.remove(
          "$_keyEmailAddressEmails.$emailAddress.${emails[email]!.uid}",
        );
      }
    }
    _userToken = null;
    _userTokenExpire = null;
    _emailAddresses = [];
    _emailAddressEmails = {};
    notifyListeners();
  }

  // Sets the list of email addresses in the SharedPreferences.
  Future<void> setEmailAddresses(List<String> emails) async {
    await _prefs!.setStringList(_keyEmailAddresses, emails);
    _emailAddresses = emails;
    notifyListeners();
  }

  Future<Map<String, Map<int, SlimEmailData>>>
  _getMessagesForAllEmailAdresses() async {
    Map<String, Map<int, SlimEmailData>> emailMap = {};
    for (var emailAddress in _emailAddresses) {
      var emails = await _getMessagesForEmailAddress(emailAddress);
      emailMap[emailAddress] = emails;
    }
    return emailMap;
  }

  Future<Map<int, SlimEmailData>> _getMessagesForEmailAddress(
    String emailAddress,
  ) async {
    var emails =
        _prefs!.getKeys().where((key) {
          return key.startsWith("$_keyEmailAddressEmails.$emailAddress.");
        }).toList();

    Map<int, SlimEmailData> emailMap = {};
    for (var email in emails) {
      var emailData = _prefs!.getString(email);
      if (emailData == null) {
        continue;
      }

      var data = jsonDecode(emailData);
      if (data["parts"] != null) {
        var message = EmailData.fromJson(data);
        emailMap[message.uid] = message;
      } else {
        var message = SlimEmailData.fromJson(data);
        emailMap[message.uid] = message;
      }
    }
    return emailMap;
  }

  List<SlimEmailData> getMessagesForEmailAddress(String emailAddress) {
    if (_emailAddressEmails[emailAddress] == null) {
      return [];
    }
    return _emailAddressEmails[emailAddress]!.values.toList();
  }

  SlimEmailData? getMessageForEmailAddress(String emailAddress, int uid) {
    if (_emailAddressEmails[emailAddress] == null) {
      return null;
    }
    return _emailAddressEmails[emailAddress]![uid];
  }

  /// Sets the message for the given email address in the SharedPreferences.
  /// The message is stored with the key format:
  /// "user.email.address.messages.<emailAddress>.<uid>".
  Future<void> setMessageForEmailAddress(
    String emailAddress,
    SlimEmailData message,
  ) async {
    var storedMessage = getMessageForEmailAddress(emailAddress, message.uid);
    // If there's a full message stored, only update the read state
    if (storedMessage != null && storedMessage is EmailData) {
      storedMessage.read = message.read;
      message = storedMessage;
    }

    await _prefs!.setString(
      "$_keyEmailAddressEmails.$emailAddress.${message.uid}",
      jsonEncode(message.toJson()),
    );
    _emailAddressEmails[emailAddress] ??= {};
    _emailAddressEmails[emailAddress]![message.uid] = message;
    notifyListeners();
  }

  /// Returns the list of email addresses from the SharedPreferences.
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
