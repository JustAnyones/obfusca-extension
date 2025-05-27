import "dart:convert";
import "dart:math";
import "package:flutter/foundation.dart" hide Key;
import 'package:file_picker/file_picker.dart';
import "package:shared_preferences/shared_preferences.dart";
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';

class Saver {
  static SharedPreferences? _prefs;
  static String _keyExtension = "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> saveInfo(
    List<String> items,
    List<String> namespaces,
    String favicon,
    String domain,
  ) async {
    var intRandom = Random().nextInt(1000000000);
    Map<String, String> newSave = {};
    newSave['domain'] = domain;
    for (int i = 0; i < items.length; i++) {
      newSave[namespaces[i]] = items[i];
    }
    newSave['favicon'] = favicon;
    newSave['uid'] = intRandom.toString();
    final String json = jsonEncode(newSave);
    print(newSave);
    print(json);
    var entries = _prefs!.getStringList('entries') ?? [];
    entries.add(json);
    await _prefs!.setStringList('entries', entries);
  }

  static Future<void> clear() async {
    _prefs!.remove('entries');
  }

  static List<String>? readInfo() {
    List<String>? entries = _prefs!.getStringList('entries');
    return entries;
  }

  static Future<void> writeEntries() async {
    List<String> entries = _prefs!.getStringList('entries')!;
    String save = '[';
    for (int i = 0; i < entries.length; i++) {
      save += entries[i];
      if (i != entries.length - 1) save += ',';
    }
    save += ']';
    var temp = jsonDecode(save);
    //print(temp);
    print(temp[0]['name']);
    Uint8List bytes = new Uint8List.fromList(save.codeUnits);
    FilePicker? platform;
    platform = FilePicker.platform;
    await platform.saveFile(
      dialogTitle: 'SaveFile',
      fileName: 'entries.json',
      bytes: bytes,
    );
  }

  static Future<void> exportEncrypted(String input_key) async {
    List<String> entries = _prefs!.getStringList('entries')!;
    String save = '[';
    for (int i = 0; i < entries.length; i++) {
      save += entries[i];
      if (i != entries.length - 1) save += ',';
    }
    save += ']';
    String mainKey = "";
    mainKey += input_key;
    if (mainKey.length < 32) {
      mainKey = mainKey + _keyExtension;
    }
    final key = Key.fromUtf8(mainKey.substring(0, 32));
    final iv = IV.fromBase64(
      key.base64.substring(0, 8) + _keyExtension.substring(8, 16),
    );
    final encrypter = Encrypter(AES(key));
    final cypherText = encrypter.encrypt(save, iv: iv);
    String export = 'obfu' + cypherText.base64;
    var hash = sha256.convert(utf8.encode(save));
    export = export + hash.toString();
    Uint8List bytes = utf8.encode(export);
    FilePicker? platform;
    platform = FilePicker.platform;
    await platform.saveFile(
      dialogTitle: 'SaveFile',
      fileName: 'entries.obfu',
      bytes: bytes,
    );
  }

  static Future<PlatformFile> encryptedImportCheck() async {
    FilePicker? platform;
    platform = FilePicker.platform;
    FilePickerResult? result = await platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'obfu'],
    );
    if (result != null) {
      PlatformFile file = result.files.first;
      return file;
    }
    return result!.files.first;
  }

  static Future<String> importEntries(
    String dataInput,
    bool encrypted,
    String? input_key,
  ) async {
    String dataString;
    if (encrypted == true) {
      String dataCypher = dataInput.substring(4);
      String dataHash = dataCypher.substring(dataCypher.length - 64);
      dataCypher = dataCypher.substring(0, dataCypher.length - 64);
      String mainKey = "";
      mainKey += input_key!;
      if (mainKey.length < 32) {
        mainKey = mainKey + _keyExtension;
      }
      final key = Key.fromUtf8(mainKey.substring(0, 32));
      final iv = IV.fromBase64(
        key.base64.substring(0, 8) + _keyExtension.substring(8, 16),
      );

      final encrypter = Encrypter(AES(key));
      Encrypted encrypt = Encrypted.from64(dataCypher);
      dataString = encrypter.decrypt(encrypt, iv: iv);
      var hash = sha256.convert(utf8.encode(dataString));
      if (dataHash != hash.toString()) {
        return "BadFile";
      }
    } else {
      dataString = dataInput;
    }
    var data = jsonDecode(dataString);
    if (data[0]['name'] == null &&
        data[0]['surname'] == null &&
        data[0]['favicon'] == null &&
        data[0]['domain'] == null &&
        data[0]['address'] == null &&
        data[0]['city'] == null &&
        data[0]['country'] == null &&
        data[0]['date'] == null &&
        data[0]['postal'] == null &&
        data[0]['username'] == null &&
        data[0]['uid'] == null) {
      return "BadFile";
    }
    List<String> entries = [];
    if (_prefs!.getStringList('entries') != null) {
      entries = _prefs!.getStringList('entries')!;
    }
    String save = '[';
    for (int i = 0; i < entries.length; i++) {
      save += entries[i];
      if (i != entries.length - 1) save += ',';
    }
    save += ']';
    var temp = jsonDecode(save);
    for (int i = 0; i < data.length; i++) {
      bool match = false;
      var entry = {
        'name': data[i]['name'],
        'surname': data[i]['surname'],
        'favicon': data[i]['favicon'],
        'domain': data[i]['domain'],
        'address': data[i]['address'],
        'city': data[i]['city'],
        'country': data[i]['country'],
        'date': data[i]['date'],
        'postal': data[i]['postal'],
        'username': data[i]['username'],
        'uid': data[i]['uid'],
      };
      for (int j = 0; j < temp.length; j++) {
        if (temp[j]['uid'] == entry['uid']) {
          match = true;
          break;
        }
      }
      if (match == true) {
        continue;
      }
      final String json = jsonEncode(entry);
      entries.add(json);
    }
    await _prefs!.setStringList('entries', entries);
    return "Saved";
  }
}
