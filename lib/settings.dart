import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Language { English, Lithuanian }

enum Region { America, Lithuania }

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _selectedLanguage;
  String? _selectedRegion;

  static const String KEY_LANG = 'lang';
  static const String KEY_REGION = 'region';

  List<String> languages = ['English', 'Lithuanian'];
  List<String> regions = ['America', 'Lithuania'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString(KEY_LANG) ?? languages[0];
      _selectedRegion = prefs.getString(KEY_REGION) ?? regions[0];
    });
  }

  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(KEY_LANG, _selectedLanguage ?? languages[0]);
    prefs.setString(KEY_REGION, _selectedRegion ?? regions[0]);
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
