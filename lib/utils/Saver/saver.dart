import "dart:convert";
import "package:flutter/foundation.dart";
import 'package:file_picker/file_picker.dart';
import "package:shared_preferences/shared_preferences.dart";

class Saver {
  static SharedPreferences? _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> saveInfo(
    String name,
    String surname,
    String favIcon,
    String domain,
    String address,
    String city,
    String country,
    String date,
    String postal,
    String username,
  ) async {
    var newSave = {
      'name': name,
      'surname': surname,
      'favicon': favIcon,
      'domain': domain,
      'address': address,
      'city': city,
      'country': country,
      'date': date,
      'postal': postal,
      'username': username,
    };
    final String json = jsonEncode(newSave);
    var entries = _prefs!.getStringList('entries') ?? [];
    entries.add(json);
    print(entries);
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
    Uint8List bytes = new Uint8List.fromList(save.codeUnits);
    FilePicker? platform;
    platform = FilePicker.platform;
    String? outputFile = await platform.saveFile(
      dialogTitle: 'SaveFile',
      fileName: 'entries.json',
      bytes: bytes,
    );
    print(outputFile);
  }

  static Future<String> importEntries() async {
    FilePicker? platform;
    platform = FilePicker.platform;
    FilePickerResult? result = await platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result != null) {
      PlatformFile file = result.files.first;
      String dataString = String.fromCharCodes(file.bytes!);
      var data = jsonDecode(dataString);
      if (data[0]['name'] == null ||
          data[0]['surname'] == null ||
          data[0]['favicon'] == null ||
          data[0]['domain'] == null ||
          data[0]['address'] == null ||
          data[0]['city'] == null ||
          data[0]['country'] == null ||
          data[0]['date'] == null ||
          data[0]['postal'] == null ||
          data[0]['username'] == null) {
        print('bad');
        return "BadFile";
      }
      List<String> entries = [];
      for (int i = 0; i < data.length; i++) {
        var entry = {
          'name': data[i]['name'],
          'surname': data[i]['surname'],
          'favicon': data[i]['favicon'],
          'domain': data[i]['surname'],
          'address': data[i]['surname'],
          'city': data[i]['city'],
          'country': data[i]['country'],
          'date': data[i]['date'],
          'postal': data[i]['postal'],
          'username': data[i]['username'],
        };
        final String json = jsonEncode(entry);
        entries.add(json);
      }
      print(entries);
      await _prefs!.setStringList('entries', entries);
      return "Saved";
    } else {
      return "NoFile";
    }
  }
}
