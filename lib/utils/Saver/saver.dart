import "dart:convert";
import "package:shared_preferences/shared_preferences.dart";

class Saver{
  static SharedPreferences? _prefs;

  static Future<void> initialize() async{
    _prefs = await SharedPreferences.getInstance();
    print("Instance");
  }

  static Future<void> saveInfo(String name, String surname) async{
    var newSave = {'name' : name, 'surname' : surname};
    final String json = jsonEncode(newSave);
    print('Before');
    String? entries =  _prefs!.getString('entries') ?? "";
    print('After');
    if(entries == ""){
      entries = json;
    }
    else{
      entries = entries! + ';' + json;
    }
    _prefs!.setString('entries', entries);
    print('Saved!');
  }

  static Future<void> readInfo() async{
    String? entries = _prefs!.getString('entries');
    print(entries);
  }
}