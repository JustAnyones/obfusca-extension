import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:browser_extension/web/interop.dart';
import 'package:browser_extension/utils/Saver/saver.dart';

class Drive {
  static bool? isAuthorized;
  static SharedPreferences? _prefs;
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> Login() async {
    String token = await getToken();
    if (token != '') {
      isAuthorized = true;
      await _prefs!.setBool('Authorized', true);
      await _prefs!.setString('access_token', token);
    }
  }

  static Future<void> sendFile() async {
    isAuthorized = _prefs!.getBool('Authorized');
    if (isAuthorized == false || isAuthorized == null) {
      return;
    }
    String? token = _prefs!.getString('access_token');

    var meta = {"name": "entries.json"};
    String metaString = jsonEncode(meta);
    int count = utf8.encode(metaString).length;
    final metadata = await http.post(
      Uri.parse('https://www.googleapis.com/drive/v3/files'),
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $token',
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.contentLengthHeader: '$count',
      },
      body: metaString,
    );

    if (metadata.statusCode != 200) {
      await _prefs!.remove('access_token');
      await _prefs!.remove('Authorized');
      isAuthorized = false;
      return;
    }

    List<String> entries = Saver.readInfo()!;
    String save = '[';
    for (int i = 0; i < entries.length; i++) {
      save += entries[i];
      if (i != entries.length - 1) save += ',';
    }
    save += ']';
    int bytesCount = utf8.encode(save).length;
    var json = jsonDecode(metadata.body);
    final response = await http.patch(
      Uri.parse(
        'https://www.googleapis.com/upload/drive/v3/files/${json['id']}',
      ),
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $token',
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.contentLengthHeader: '$bytesCount',
      },
      body: save,
    );
  }

  static Future<void> importFromDrive() async {
    isAuthorized = _prefs!.getBool('Authorized');
    if (isAuthorized == false || isAuthorized == null) {
      return;
    }
    String? token = _prefs!.getString('access_token');
    final list = await http.get(
      Uri.parse('https://www.googleapis.com/drive/v3/files'),
      headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
    );
    if (list.statusCode != 200) {
      await _prefs!.remove('access_token');
      await _prefs!.remove('Authorized');
      isAuthorized = false;
      return;
    }
    var json = jsonDecode(list.body);
  }
}
