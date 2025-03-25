import "dart:convert";
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
}
