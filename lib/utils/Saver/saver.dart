import "dart:convert";
import "package:shared_preferences/shared_preferences.dart";

class Saver {
  static SharedPreferences? _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    print("Instance");
  }

  static Future<void> saveInfo(String name, String surname) async {
    var newSave = {'name': name, 'surname': surname};
    final String json = jsonEncode(newSave);
    print('Before');
    var entries = _prefs!.getStringList('entries') ?? [];
    entries.add(json);
    print('After');
    await _prefs!.setStringList('entries', entries);
    print('Saved!');
  }

  static Future<void> readInfo() async {
    var entries = _prefs!.getStringList('entries');
    print(entries);
  }
}
