import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum Language { English, Lithuanian }

enum Region { America, Lithuania }

List<String> languages = ['English', 'Lithuanian'];
List<String> locales = ['en', 'lt'];
List<String> regions = ['America', 'Lithuania'];

class SettingProvider extends ChangeNotifier {
  static const String _KEY_LOCALE = 'locale';
  static const String _KEY_REGION = 'region';

  static final SettingProvider _instance = SettingProvider._internal();
  static SharedPreferences? _prefs;

  // Private constructor
  SettingProvider._internal() {
    print("Singleton Instance Created");
  }

  factory SettingProvider() {
    return _instance;
  }

  // Locale
  String _locale = locales[0];
  Locale get locale => Locale(_locale);
  String get localeAsString => _locale;

  // Region
  String _region = regions[0];
  String get region => _region;

  static SettingProvider getInstance() {
    return _instance;
  }

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    _locale = await getString(_KEY_LOCALE, locales[0]);
    _region = await getString(_KEY_REGION, regions[0]);
  }

  Future<void> setLocale(String value) async {
    await _prefs!.setString(_KEY_LOCALE, value);
    _locale = value;
    notifyListeners();
  }

  Future<void> setRegion(String value) async {
    await _prefs!.setString(_KEY_REGION, value);
    _region = value;
    notifyListeners();
  }

  Future<String> getString(String key, String defaultValue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? defaultValue;
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
    setState(() {
      _selectedLanguage = SettingProvider.getInstance().localeAsString;
      _selectedRegion = SettingProvider.getInstance().region;
    });
  }

  Future<void> _saveSettings() async {
    await SettingProvider.getInstance().setLocale(
      _selectedLanguage ?? locales[0],
    );
    await SettingProvider.getInstance().setRegion(
      _selectedRegion ?? regions[0],
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.settings_saved_popup),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings_title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language
            Text(AppLocalizations.of(context)!.setting_locale_title),
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedLanguage,
              hint: Text(AppLocalizations.of(context)!.setting_locale_hint),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedLanguage = newValue;
                });
              },
              items:
                  locales.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
            ),
            SizedBox(height: 20),

            // Region
            Text(AppLocalizations.of(context)!.setting_region_title),
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedRegion,
              hint: Text(AppLocalizations.of(context)!.setting_region_hint),
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
              child: Text(AppLocalizations.of(context)!.settings_save_button),
            ),
          ],
        ),
      ),
    );
  }
}
