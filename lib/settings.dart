import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Language { English, Lithuanian }

enum Region { America, Lithuania }

List<String> languages = ['English', 'Lithuanian'];
List<String> regions = ['America', 'Lithuania'];

class SettingsState {
  static const String KEY_LANG = 'lang';
  static const String KEY_REGION = 'region';

  static Future<void> setString(String key, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
  }

  static Future<String?> getString(String key, String defaultValue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? defaultValue;
  }

  static Future<String?> getRegion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(KEY_REGION) ?? regions[0];
  }
}

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _selectedLanguage;
  String? _selectedRegion;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    var lang = await SettingsState.getString(
      SettingsState.KEY_LANG,
      languages[0],
    );
    var region = await SettingsState.getString(
      SettingsState.KEY_REGION,
      regions[0],
    );
    setState(() {
      _selectedLanguage = lang;
      _selectedRegion = region;
    });
  }

  Future<void> _saveSettings() async {
    await SettingsState.setString(
      SettingsState.KEY_LANG,
      _selectedLanguage ?? languages[0],
    );
    await SettingsState.setString(
      SettingsState.KEY_REGION,
      _selectedRegion ?? regions[0],
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Settings saved!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language
            Text('Interface Language'),
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedLanguage,
              hint: Text('Choose Interface Language'),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedLanguage = newValue;
                });
              },
              items:
                  languages.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
            ),
            SizedBox(height: 20),

            // Region
            Text('Region'),
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedRegion,
              hint: Text('Choose Region'),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedRegion = newValue;
                });
              },
              items:
                  regions.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                _saveSettings();
              },
              child: Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
