import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:browser_extension/web/interop.dart';
import 'package:browser_extension/utils/Saver/saver.dart';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';

class Drive {
  static bool? isAuthorized;
  static SharedPreferences? _prefs;
  static String _keyExtension = "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";
  static bool _passwordSet = false;
  static String _password = "";
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool Authorized() {
    bool? auth = _prefs!.getBool('Authorized');
    if (auth == null) {
      return false;
    }
    return auth;
  }

  static Future<void> Login() async {
    String token = await getToken();
    if (token != '') {
      isAuthorized = true;
      await _prefs!.setBool('Authorized', true);
      await _prefs!.setString('access_token', token);
      print(token);
    }
  }

  static Future<void> logout() async {
    bool? auth = _prefs!.getBool('Authorized');
    print(auth);
    String? token = _prefs!.getString('access_token');
    print(token);
    final response = await http.post(
      Uri.parse('https://oauth2.googleapis.com/revoke?token=${token}'),
    );
    _prefs!.remove('access_token');
    _prefs!.remove('Authorized');
    print(response.body);
  }

  static Future<void> sendFile(String inputKey) async {
    _passwordSet = true;
    _password = inputKey;
    isAuthorized = _prefs!.getBool('Authorized');
    if (isAuthorized == false || isAuthorized == null) {
      return;
    }
    String? token = _prefs!.getString('access_token');

    var meta = {"name": "entries.obfu"};
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
    var hash = sha256.convert(utf8.encode(save));
    String mainKey = "";
    mainKey += inputKey;
    if (mainKey.length < 32) {
      mainKey = mainKey + _keyExtension;
    }
    final key = Key.fromUtf8(mainKey.substring(0, 32));
    final iv = IV.fromBase64(
      key.base64.substring(0, 8) + _keyExtension.substring(8, 16),
    );
    final encrypter = Encrypter(AES(key));
    final cypherText = encrypter.encrypt(save, iv: iv);
    String export = 'obfu' + cypherText.base64 + hash.toString();
    int bytesCount = utf8.encode(export).length;
    var json = jsonDecode(metadata.body);
    await http.patch(
      Uri.parse(
        'https://www.googleapis.com/upload/drive/v3/files/${json['id']}',
      ),
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $token',
        HttpHeaders.contentTypeHeader: 'plain/text',
        HttpHeaders.contentLengthHeader: '$bytesCount',
      },
      body: export,
    );
  }

  static Future<bool> importFromDrive(String id, String inputKey) async {
    isAuthorized = _prefs!.getBool('Authorized');
    if (isAuthorized == false || isAuthorized == null) {
      return false;
    }
    String? token = _prefs!.getString('access_token');
    final response = await http.get(
      Uri.parse('https://www.googleapis.com/drive/v3/files/$id?alt=media'),
      headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
    );
    if (response.body.length == 0) {
      return true;
    }
    String res = await Saver.importEntries(response.body, true, inputKey);
    if (res != "Saved") {
      return false;
    }
    return true;
  }

  static Future<void> updateDrive(String id, String inputKey) async {
    isAuthorized = _prefs!.getBool('Authorized');
    if (isAuthorized == false || isAuthorized == null) {
      return;
    }
    String? token = _prefs!.getString('access_token');
    List<String> entries = Saver.readInfo()!;
    String save = '[';
    for (int i = 0; i < entries.length; i++) {
      save += entries[i];
      if (i != entries.length - 1) save += ',';
    }
    save += ']';
    var hash = sha256.convert(utf8.encode(save));
    String mainKey = "";
    mainKey += inputKey;
    if (mainKey.length < 32) {
      mainKey = mainKey + _keyExtension;
    }
    final key = Key.fromUtf8(mainKey.substring(0, 32));
    final iv = IV.fromBase64(
      key.base64.substring(0, 8) + _keyExtension.substring(8, 16),
    );
    final encrypter = Encrypter(AES(key));
    final cypherText = encrypter.encrypt(save, iv: iv);
    String export = 'obfu' + cypherText.base64 + hash.toString();
    int bytesCount = utf8.encode(export).length;
    await http.patch(
      Uri.parse('https://www.googleapis.com/upload/drive/v3/files/$id'),
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $token',
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.contentLengthHeader: '$bytesCount',
      },
      body: export,
    );
  }

  static Future<String> needSend() async {
    isAuthorized = _prefs!.getBool('Authorized');
    if (isAuthorized == false || isAuthorized == null) {
      return "BadAuth";
    }
    String? token = _prefs!.getString('access_token');
    final list = await http.get(
      Uri.parse('https://www.googleapis.com/drive/v3/files'),
      headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
    );
    if (list.statusCode != 200) {
      await _prefs!.remove('access_token');

      isAuthorized = false;
      return "BadAuth";
    }
    var json = jsonDecode(list.body);
    if (json['files'].length == 0) {
      return "NoId";
    }
    return json['files'][0]['id'];
  }
}
