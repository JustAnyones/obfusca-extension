import 'dart:async';
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
  Timer? _emailFetchTimer;

  SlimEmailData? _recentEmail = null;
  // The most recent email
  SlimEmailData? get recentEmail => _recentEmail;

  UserProvider._internal();

  factory UserProvider() {
    return _instance;
  }

  static UserProvider getInstance() {
    return _instance;
  }

  void clearRecentEmail() {
    _recentEmail = null;
    notifyListeners();
  }

  String? _userToken;
  String? get userToken => _userToken;
  DateTime? _userTokenExpire;
  DateTime? get userTokenExpire => _userTokenExpire;

  List<String> _emailAddresses = [];
  List<String> get emailAddresses => _emailAddresses;

  // {emailAddress: {uid: SlimEmailData}}
  Map<String, Map<int, SlimEmailData>> _emailAddressEmails = {};

  // {emailAddress: [uid]}
  Map<String, List<int>> _emailAddressSortedUids = {};

  bool get isLoggedIn =>
      _userToken != null &&
      _userTokenExpire != null &&
      _userTokenExpire!.isAfter(DateTime.now());

  /// Initializes the UserProvider and loads the user token and email addresses
  /// from SharedPreferences.
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    _userToken = await getString(_keyUserToken, null);
    _userTokenExpire = await _getDateTime(_keyUserTokenExpire, null);
    _emailAddresses = await _getEmailAddresses() ?? [];
    _emailAddressEmails = await _getMessagesForAllEmailAddresses();

    startTimer();
  }

  /// Sets the user token and expiration date in the SharedPreferences.
  /// This is called when the user logs in.
  Future<void> setUserToken(String token, DateTime expire) async {
    await _prefs!.setString(_keyUserToken, token);
    await _prefs!.setString(_keyUserTokenExpire, expire.toString());
    _userToken = token;
    _userTokenExpire = expire;
    startTimer();
    notifyListeners();
  }

  /// Fetches the emails for the current user and stores them in the SharedPreferences.
  Future<void> fetchEmails() async {
    if (!isLoggedIn) {
      return;
    }
    print("Fetching emails for user: $_userToken");

    // For each email address
    for (var emailAddress in _emailAddresses) {
      // Fetch the emails from the server
      var (emails, err) = await ObfuscaAPI.getUserEmails(
        _userToken!,
        emailAddress,
      );
      print("Fetched emails for $emailAddress: $emails");
      if (err != null) {
        print("Error fetching emails: $err");
        continue;
      }
      for (var email in emails) {
        // If email arrived in the last 5 minutes
        // and was not already shown
        // and there's no recent email
        if (email.date.isAfter(
              DateTime.now().subtract(const Duration(minutes: 5)),
            ) &&
            _recentEmail == null) {
          var storedEmail = _emailAddressEmails[emailAddress]?[email.uid];
          var show = false;

          // If we don't have a stored email, that means we haven't shown it yet
          // and we can show it now
          if (storedEmail == null) {
            show = true;
            // If we do have it stored, we only show it if it was not shown yet
          } else if (!storedEmail.recentlyShown) {
            show = true;
          }

          if (show) {
            _recentEmail = email;
            email.recentlyShown = true;
          }
        }

        await setMessageForEmailAddress(emailAddress, email);
      }
    }
  }

  /// Starts a timer to fetch emails every 15 seconds.
  /// This is used to keep the email list up to date.
  /// The timer is started only if it is not already running.
  /// The timer is stopped when the user logs out.
  void startTimer() {
    if (_emailFetchTimer != null) {
      return;
    }
    _emailFetchTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      fetchEmails();
    });
    fetchEmails();
  }

  /// Stops the timer that fetches emails.
  /// This is used to stop the timer when the user logs out.
  /// The timer is stopped only if it is running.
  void _stopTimer() {
    if (_emailFetchTimer != null) {
      _emailFetchTimer!.cancel();
      _emailFetchTimer = null;
    }
  }

  Future<void> clearUserState() async {
    _stopTimer();
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
    _emailAddressSortedUids = {};
    notifyListeners();
  }

  // Sets the list of email addresses in the SharedPreferences.
  Future<void> setEmailAddresses(List<String> emails) async {
    await _prefs!.setStringList(_keyEmailAddresses, emails);
    _emailAddresses = emails;
    notifyListeners();
  }

  /// Internal function, used to fetch the messages for all email addresses
  /// from local storage.
  Future<Map<String, Map<int, SlimEmailData>>>
  _getMessagesForAllEmailAddresses() async {
    Map<String, Map<int, SlimEmailData>> emailMap = {};
    for (var emailAddress in _emailAddresses) {
      // Store the slim messages for every email address
      var emails = await _getMessagesForEmailAddress(emailAddress);
      emailMap[emailAddress] = emails;
      // Sort the messages by date
      await updateSortOrder(emailAddress);
    }
    return emailMap;
  }

  /// Updates the sort order of the messages for the given email address.
  Future<void> updateSortOrder(String address) async {
    var emails = await _getMessagesForEmailAddress(address);
    // Sort the messages by date
    var values = emails.values.toList();
    values.sort((a, b) {
      return a.date.compareTo(b.date);
    });
    // Reverse the list to get the most recent messages first
    values = values.reversed.toList();
    // Store the sorted list of UIDs
    _emailAddressSortedUids[address] = values.map((e) => e.uid).toList();
  }

  /// Internal function, used to fetch the messages for a specific email address
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
      var message = SlimEmailData.fromJson(data);
      emailMap[message.uid] = message;
    }
    return emailMap;
  }

  /// Returns the sorted list of email UIDs.
  List<int> getMessageUidsForAddress(String emailAddress) {
    if (_emailAddressSortedUids[emailAddress] == null) {
      return [];
    }
    return _emailAddressSortedUids[emailAddress]!;
  }

  /// Returns the message for the given email address and UID.
  SlimEmailData? getMessageForEmailAddress(String emailAddress, int uid) {
    if (_emailAddressEmails[emailAddress] == null) {
      return null;
    }
    return _emailAddressEmails[emailAddress]![uid];
  }

  /// Sets the read status of the message for the given email address and UID.
  Future<void> setMessageReadStatusForEmailAddress(
    String emailAddress,
    int uid,
    bool read,
  ) async {
    if (_emailAddressEmails[emailAddress] == null) {
      return;
    }
    var message = _emailAddressEmails[emailAddress]![uid];
    if (message == null) {
      return;
    }
    message.read = read;
    await setMessageForEmailAddress(emailAddress, message);
    notifyListeners();
  }

  /// Sets the message for the given email address in the SharedPreferences.
  ///
  /// The message is stored with the key format:
  /// "user.email.address.messages.<emailAddress>.<uid>".
  Future<void> setMessageForEmailAddress(
    String emailAddress,
    SlimEmailData message,
  ) async {
    // If message is already in the list, inherit some state from the list
    if (_emailAddressEmails[emailAddress]?[message.uid] != null) {
      var oldMessage = _emailAddressEmails[emailAddress]![message.uid]!;
      if (oldMessage.recentlyShown) {
        message.recentlyShown = true;
      }
    }

    // Store message in SharedPreferences
    await _prefs!.setString(
      "$_keyEmailAddressEmails.$emailAddress.${message.uid}",
      jsonEncode(message.toJson()),
    );
    // Update the local map
    _emailAddressEmails[emailAddress] ??= {};
    _emailAddressEmails[emailAddress]![message.uid] = message;
    // And update the sorted list of UIDs
    await updateSortOrder(emailAddress);
    notifyListeners();
  }

  /// Returns the list of email addresses from SharedPreferences.
  Future<List<String>?> _getEmailAddresses() async {
    return _prefs!.getStringList(_keyEmailAddresses);
  }

  /// Returns the String value for the given key from SharedPreferences.
  Future<String?> getString(String key, String? defaultValue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? defaultValue;
  }

  /// Returns the DateTime value for the given key from SharedPreferences.
  Future<DateTime?> _getDateTime(String key, DateTime? defaultValue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var value = prefs.getString(key);
    if (value == null) {
      return defaultValue;
    }
    return DateTime.parse(value);
  }
}
