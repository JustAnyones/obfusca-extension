import 'dart:convert';

import 'package:http/http.dart' as http;

const String apiUrl = "https://obfusca.site";

typedef LoginData = ({String token, DateTime dateExpire});

typedef Addresant = ({String name, String address});
typedef SlimEmailData =
    ({
      int uid,
      Addresant from,
      Addresant to,
      String subject,
      DateTime date,
      bool read,
    });

class ObfuscaAPI {
  /// Logs in a user with the given username and password.
  ///
  /// Returns a tuple containing the token and an error message.
  /// If the login is successful, the token will be non-null and the error message will be null.
  /// If the login fails, the token will be null and the error message will contain the reason for the failure.
  static Future<(LoginData?, String?)> login(
    String username,
    String password,
  ) async {
    try {
      var response = await http.post(
        Uri.parse("$apiUrl/user/login"),
        body: jsonEncode({"username": username, "password": password}),
        headers: {"Content-Type": "application/json"},
      );

      var data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        var parsedDate = DateTime.parse(data["ExpireAt"] as String);
        return ((token: data["token"] as String, dateExpire: parsedDate), null);
      }
      return (null, data["message"] as String);
    } catch (e) {
      return (null, e.toString());
    }
  }

  /// Registers a new user with the given username and password.
  ///
  /// Returns an error message if the registration fails.
  /// If the registration is successful, returns null.
  static Future<String?> register(String username, String password) async {
    try {
      var response = await http.post(
        Uri.parse("$apiUrl/user/register"),
        body: jsonEncode({"username": username, "password": password}),
        headers: {"Content-Type": "application/json"},
      );

      var data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return (null);
      }
      return (data["message"] as String);
    } catch (e) {
      return (e.toString());
    }
  }

  static Future<String?> logout(String token) async {
    // TODO: not supported on the backend yet
    return null;
  }

  static Future<(List<String>, String?)> getUserAddresses(String token) async {
    List<String> emails = [];
    try {
      var response = await http.get(
        Uri.parse("$apiUrl/user/addresses"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      var data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        for (var email in data["Addresses"]) {
          emails.add(email as String);
        }
        return (emails, null);
      }
      return (emails, data["message"] as String);
    } catch (e) {
      return (emails, e.toString());
    }
  }

  static Future<(List<SlimEmailData>, String?)> getUserEmails(
    String token,
    String address,
  ) async {
    List<SlimEmailData> emails = [];
    try {
      var response = await http.get(
        Uri.parse("$apiUrl/email/$address/list"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      var data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        for (var email in data["Emails"]) {
          emails.add((
            uid: email["Uid"] as int,
            from: (
              name: email["From"]["Name"] as String,
              address: email["From"]["Address"] as String,
            ),
            to: (
              name: email["To"]["Name"] as String,
              address: email["To"]["Address"] as String,
            ),
            subject: email["Subject"] as String,
            date: DateTime.parse(email["Date"] as String),
            read: email["Read"] as bool,
          ));
        }
        return (emails, null);
      }
      return (emails, data["message"] as String);
    } catch (e) {
      return (emails, e.toString());
    }
  }
}
