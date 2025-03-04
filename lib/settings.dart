import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum Language { English, Lithuanian }

enum Region { America, Lithuania }

List<String> languages = ['English', 'Lithuanian'];
List<String> locales = ['en', 'lt'];
List<String> regions = ['America', 'Lithuania'];

class SettingProvider extends ChangeNotifier {
  static const String KEY_LOCALE = 'locale';
  static const String KEY_REGION = 'region';

  static final SettingProvider _instance = SettingProvider._internal();

  // Private constructor
  SettingProvider._internal() {
    print("Singleton Instance Created");
  }

  factory SettingProvider() {
    return _instance;
  }

  Locale _locale = Locale(locales[0]);

  Locale get locale => _locale;

  static SettingProvider getInstance() {
    return _instance;
  }

  Future<void> initialize() async {
    _locale = Locale(await _getLocale());
  }

  Future<String> _getLocale() async {
    return await getString(KEY_LOCALE, locales[0]);
  }

  Future<void> setString(String key, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);

    if (key == KEY_LOCALE) {
      _locale = Locale(value);
    }
    notifyListeners();
  }

  Future<String> getString(String key, String defaultValue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? defaultValue;
  }

  Future<String> getRegion() async {
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
    var lang = await SettingProvider.getInstance().getString(
      SettingProvider.KEY_LOCALE,
      locales[0],
    );
    var region = await SettingProvider.getInstance().getString(
      SettingProvider.KEY_REGION,
      regions[0],
    );
    setState(() {
      _selectedLanguage = lang;
      _selectedRegion = region;
    });
  }

  Future<void> _saveSettings() async {
    await SettingProvider.getInstance().setString(
      SettingProvider.KEY_LOCALE,
      _selectedLanguage ?? locales[0],
    );
    await SettingProvider.getInstance().setString(
      SettingProvider.KEY_REGION,
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
