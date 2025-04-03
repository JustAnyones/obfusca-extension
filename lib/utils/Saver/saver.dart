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
  ) async {
    var newSave = {'name': name, 'surname': surname, 'favicon': favIcon};
    final String json = jsonEncode(newSave);
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
}
