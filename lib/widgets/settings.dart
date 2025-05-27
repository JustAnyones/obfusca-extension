import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:browser_extension/providers/settings.dart';
import 'package:browser_extension/utils/Saver/saver.dart';
import 'package:browser_extension/web/interop.dart';
import 'package:http/http.dart' as http;
import 'package:browser_extension/utils/drive.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _selectedLanguage;
  String? _selectedRegion;
  bool? _encrypt = false;
  final TextEditingController _keyController = TextEditingController();
  String? _key;
  String? _access_token;
  bool? _authorized;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _authorized = false;
  }

  // Loads current settings from the settings provider.
  Future<void> _loadSettings() async {
    setState(() {
      _selectedLanguage = SettingProvider.getInstance().localeAsString;
      _selectedRegion = SettingProvider.getInstance().region;
    });
  }

  // Saves the settings to the settings provider.
  Future<void> _saveSettings() async {
    await SettingProvider.getInstance().setLocale(_selectedLanguage!);
    await SettingProvider.getInstance().setRegion(_selectedRegion!);
  }

  Future<void> _displayTextInputDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: AlertDialog(
            title: Text(AppLocalizations.of(context)!.input_password),
            content: TextField(
              controller: _keyController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.hint_password,
              ),
            ),
            actions: <Widget>[
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _key = _keyController.text;
                    Navigator.pop(context);
                  });
                },
                child: Text(
                  AppLocalizations.of(context)!.button_submit_password,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget login = ElevatedButton(
      onPressed: () async {
        await Drive.Login();
        setState(() {});
      },
      child: Text("Google login"),
    );
    Widget logout = ElevatedButton(
      onPressed: () async {
        _access_token = null;
        await Drive.logout();
        setState(() {});
      },
      child: Text("Google logout"),
    );
    Widget sync = ElevatedButton(
      onPressed: () async {
        String res = await Drive.needSend();
        if (res == "BadAuth") {
          await Drive.logout();
          setState(() {});
        } else if (res == "NoId") {
          await Drive.sendFile();
        } else {
          bool import = await Drive.importFromDrive(res);
          if (import == false) {
            return;
          }
          await Drive.updateDrive(res);
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Drive synced")));
      },
      child: Text("Google sync"),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings_title),
        automaticallyImplyLeading: false,
      ),
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
                      child: Text(
                        AppLocalizations.of(
                          context,
                        )!.setting_locale_option(value),
                      ),
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
                      child: Text(
                        AppLocalizations.of(
                          context,
                        )!.setting_region_option(value),
                      ),
                    );
                  }).toList(),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                _saveSettings();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.settings_saved_popup,
                    ),
                  ),
                );
              },
              child: Text(AppLocalizations.of(context)!.settings_save_button),
            ),

            SizedBox(height: 16),

            CheckboxListTile(
              title: Text(
                AppLocalizations.of(context)!.settings_encryption_toggle,
              ),
              value: _encrypt,
              onChanged: (bool? newValue) {
                setState(() {
                  _encrypt = newValue;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),

            SizedBox(height: 16),

            ElevatedButton(
              onPressed: () async {
                if (_encrypt == true) {
                  await _displayTextInputDialog(context);
                  await Saver.exportEncrypted(_key!);
                } else {
                  await Saver.writeEntries();
                }
              },
              child: Text(AppLocalizations.of(context)!.button_export_entries),
            ),

            SizedBox(height: 16),

            ElevatedButton(
              onPressed: () async {
                bool encrypted = false;
                PlatformFile file = await Saver.encryptedImportCheck();
                String dataString = String.fromCharCodes(file.bytes!);
                if (file == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.import_no_file,
                      ),
                    ),
                  );
                  return;
                }
                if (dataString.substring(0, 4) == 'obfu') {
                  encrypted = true;
                  await _displayTextInputDialog(context);
                }
                String res = await Saver.importEntries(
                  dataString,
                  encrypted,
                  _key,
                );
                if (res == "BadFile") {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.import_bad_file,
                      ),
                    ),
                  );
                } else if (res == "Saved") {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.import_success,
                      ),
                    ),
                  );
                }
              },
              child: Text(AppLocalizations.of(context)!.button_import_entries),
            ),

            SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                Saver.clear();
              },
              child: Text(AppLocalizations.of(context)!.button_clear_entries),
            ),

            SizedBox(height: 16),

            Drive.Authorized() ? SizedBox(height: 0) : login,

            Drive.Authorized() ? sync : SizedBox(height: 0),

            Drive.Authorized() ? SizedBox(height: 16) : SizedBox(height: 0),

            Drive.Authorized() ? logout : SizedBox(height: 0),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
