import 'dart:convert';

import 'package:http/http.dart' as http;

const String apiUrl = "https://obfusca.site";

typedef LoginData = ({String token, DateTime dateExpire});

typedef Part = ({String mediaType, String content, bool encoded});
typedef Attachment = ({String filename, int size, int index});

class PartialAttachment {
  final String filename;
  final int size;
  final int index;

  PartialAttachment({
    required this.filename,
    required this.size,
    required this.index,
  });

  Map<String, dynamic> toJson() {
    return {'filename': filename, 'size': size, 'index': index};
  }
}

class FullAttachment extends PartialAttachment {
  final String content;

  FullAttachment({
    required String filename,
    required int size,
    required int index,
    required this.content,
  }) : super(filename: filename, size: size, index: index);

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'size': size,
      'index': index,
      'content': content,
    };
  }
}

class Addresant {
  final String name;
  final String address;

  Addresant({required this.name, required this.address});

  Map<String, dynamic> toJson() {
    return {'name': name, 'address': address};
  }

  @override
  String toString() {
    if (name.isEmpty) {
      return address;
    }
    return "$name\n($address)";
  }
}

class SlimEmailData {
  final int uid;
  final Addresant from;
  final Addresant to;
  final String subject;
  final DateTime date;
  bool read;
  bool recentlyShown = false;

  SlimEmailData({
    required this.uid,
    required this.from,
    required this.to,
    required this.subject,
    required this.date,
    required this.read,
    required this.recentlyShown,
  });

  /// Converts the SlimEmailData object to a JSON representation.
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'from': from.toJson(),
      'to': to.toJson(),
      'subject': subject,
      'date': date.toIso8601String(),
      'read': read,
      'recentlyShown': recentlyShown,
    };
  }

  /// Converts JSON representation to SlimEmailData object.
  factory SlimEmailData.fromJson(Map<String, dynamic> json) {
    return SlimEmailData(
      uid: json['uid'] as int,
      from: Addresant(
        name: json['from']['name'] as String,
        address: json['from']['address'] as String,
      ),
      to: Addresant(
        name: json['to']['name'] as String,
        address: json['to']['address'] as String,
      ),
      subject: json['subject'] as String,
      date: DateTime.parse(json['date'] as String),
      read: json['read'] as bool,
      recentlyShown: json['recentlyShown'] as bool,
    );
  }
}

class EmailData extends SlimEmailData {
  final List<Part> parts;
  final List<Attachment> attachments;

  EmailData({
    required int uid,
    required Addresant from,
    required Addresant to,
    required String subject,
    required this.parts,
    required this.attachments,
    required DateTime date,
    required bool read,
  }) : super(
         uid: uid,
         from: from,
         to: to,
         subject: subject,
         date: date,
         read: read,
         recentlyShown: false,
       );
}

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

  /// Creates a new email address for the user.
  static Future<String?> createAddress(String token) async {
    try {
      var response = await http.post(
        Uri.parse("$apiUrl/email"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      var data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return null;
      }
      return data["message"] as String;
    } catch (e) {
      return e.toString();
    }
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
          emails.add(
            SlimEmailData(
              uid: email["Uid"] as int,
              from: Addresant(
                name: email["From"]["Name"] as String,
                address: email["From"]["Address"] as String,
              ),
              to: Addresant(
                name: email["To"]["Name"] as String,
                address: email["To"]["Address"] as String,
              ),
              subject: email["Subject"] as String,
              date: DateTime.parse(email["Date"] as String),
              read: email["Read"] as bool,
              recentlyShown: false,
            ),
          );
        }
        return (emails, null);
      }
      return (emails, data["message"] as String);
    } catch (e) {
      return (emails, e.toString());
    }
  }

  static Future<(EmailData?, String?)> getUserEmail(
    String token,
    String address,
    int uid,
  ) async {
    try {
      var response = await http.get(
        Uri.parse("$apiUrl/email/$address/$uid?read=1"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      var data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        var email = data["Email"];

        return (
          EmailData(
            uid: email["Uid"] as int,
            from: Addresant(
              name: email["From"]["Name"] as String,
              address: email["From"]["Address"] as String,
            ),
            to: Addresant(
              name: email["To"]["Name"] as String,
              address: email["To"]["Address"] as String,
            ),
            subject: email["Subject"] as String,
            parts:
                (email["Parts"] as List<dynamic>).map((part) {
                  return (
                    mediaType: part["MediaType"] as String,
                    content: part["Content"] as String,
                    encoded: part["Encoded"] as bool,
                  );
                }).toList(),
            attachments:
                (email["Attachments"] as List<dynamic>).map((part) {
                  return (
                    filename: part["Filename"] as String,
                    size: part["Size"] as int,
                    index: part["Index"] as int,
                  );
                }).toList(),
            date: DateTime.parse(email["Date"] as String),
            read: email["Read"] as bool,
          ),
          null,
        );
      }
      return (null, data["message"] as String);
    } catch (e) {
      return (null, e.toString());
    }
  }

  static Future<(FullAttachment?, String?)> getUserEmailAttachment(
    String token,
    String address,
    int uid,
    int index,
  ) async {
    try {
      var response = await http.get(
        Uri.parse("$apiUrl/email/$address/$uid/attachment/$index"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      var data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        var attachment = data["Attachment"];
        return (
          FullAttachment(
            filename: attachment["Filename"] as String,
            content: attachment["Content"] as String,
            size: attachment["Size"] as int,
            index: attachment["Index"] as int,
          ),
          null,
        );
      }
      return (null, data["message"] as String);
    } catch (e) {
      return (null, e.toString());
    }
  }

  static Future<String?> changeEmailReadStatus(
    String token,
    String address,
    int uid,
    bool read,
  ) async {
    int readAsInt = read ? 1 : 0;
    try {
      var response = await http.post(
        Uri.parse("$apiUrl/email/$address/$uid?read=$readAsInt"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      var data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return null;
      }
      return data["message"] as String;
    } catch (e) {
      return e.toString();
    }
  }
}
