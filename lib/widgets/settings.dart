import 'package:browser_extension/utils/session_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:browser_extension/providers/settings.dart';
import 'package:browser_extension/utils/Saver/saver.dart';
import 'package:browser_extension/web/interop.dart';
import 'package:http/http.dart' as http;
import 'package:browser_extension/generators/gens.dart';
import 'package:browser_extension/utils/drive.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  List<GeneratorCustom> _customGenerators = [];
  bool? _password = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _authorized = false;
    _loadCustomGenerators();
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
                    _password = false;
                    Navigator.pop(context);
                  });
                },
                child: Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _password = true;
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

  Future<void> _loadCustomGenerators() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? saved = prefs.getStringList('custom_generators');
    if (saved != null) {
      setState(() {
        _customGenerators =
            saved.map((e) => GeneratorCustom.fromJson(jsonDecode(e))).toList();
      });
    }
  }

  Future<void> _saveCustomGenerators() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> toSave =
        _customGenerators.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('custom_generators', toSave);
  }

  @override
  Widget build(BuildContext context) {
    Widget login = ElevatedButton(
      onPressed: () async {
        await Drive.Login();
        setState(() {});
      },
      child: Text(AppLocalizations.of(context)!.google_sign_in),
    );
    Widget logout = ElevatedButton(
      onPressed: () async {
        await Drive.logout();
        setState(() {});
      },
      child: Text(AppLocalizations.of(context)!.google_logout),
    );
    Widget sync = ElevatedButton(
      onPressed: () async {
        String res = await Drive.needSend();
        if (res == "BadAuth") {
          await Drive.logout();
          setState(() {});
        } else if (res == "NoId") {
          _keyController.text = "";
          _key = "";
          await _displayTextInputDialog(context);
          SessionData.session!.set('key', _key!);
          SessionData.session!.set('sync', true);
          await Drive.sendFile(await SessionData.session!.get('key'));
        } else {
          if (await SessionData.session!.get('sync') != true) {
            _keyController.text = "";
            _key = "";
            await _displayTextInputDialog(context);
            SessionData.session!.set('key', _key!);
            SessionData.session!.set('sync', true);
          }
          bool import = await Drive.importFromDrive(
            res,
            await SessionData.session!.get('key'),
          );
          if (import == false) {
            return;
          }
          await Drive.updateDrive(res, await SessionData.session!.get('key'));
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.google_synced)),
        );
      },
      child: Text(AppLocalizations.of(context)!.google_sync),
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
                  _keyController.text = "";
                  await _displayTextInputDialog(context);
                  if (_password == false) {
                    return;
                  }
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

            Text(
              AppLocalizations.of(context)!.google_explain,
              style: const TextStyle(fontSize: 24),
            ),

            SizedBox(height: 16),

            Drive.Authorized() ? SizedBox(height: 0) : login,

            Drive.Authorized() ? sync : SizedBox(height: 0),

            Drive.Authorized() ? SizedBox(height: 16) : SizedBox(height: 0),

            Drive.Authorized() ? logout : SizedBox(height: 0),

            SizedBox(height: 16),

            // Custom Generator button
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text(
                AppLocalizations.of(context)!.settings_custom_generator_create,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    final TextEditingController returnValueController =
                        TextEditingController();
                    final TextEditingController namespaceController =
                        TextEditingController();
                    String selectedType = 'random';
                    List<TextEditingController> randomControllers = [
                      TextEditingController(),
                    ];

                    return GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      child: StatefulBuilder(
                        builder: (context, setState) {
                          return AlertDialog(
                            title: Text(
                              AppLocalizations.of(
                                context,
                              )!.settings_custom_generator_create,
                            ),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  DropdownButton<String>(
                                    value: selectedType,
                                    items: [
                                      DropdownMenuItem(
                                        value: 'random',
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.settings_custom_generator_random,
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'returnValue',
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.settings_custom_generator_return_value,
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        selectedType = value!;
                                      });
                                    },
                                  ),
                                  if (selectedType == 'random') ...[
                                    Column(
                                      children: [
                                        for (
                                          int i = 0;
                                          i < randomControllers.length;
                                          i++
                                        )
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextField(
                                                  controller:
                                                      randomControllers[i],
                                                  decoration: InputDecoration(
                                                    labelText:
                                                        AppLocalizations.of(
                                                          context,
                                                        )!.settings_custom_generator_value +
                                                        (i + 1).toString(),
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.remove_circle,
                                                  color: Colors.red,
                                                ),
                                                onPressed:
                                                    randomControllers.length > 1
                                                        ? () {
                                                          setState(() {
                                                            randomControllers
                                                                .removeAt(i);
                                                          });
                                                        }
                                                        : null,
                                              ),
                                            ],
                                          ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton.icon(
                                            icon: Icon(Icons.add),
                                            label: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.settings_custom_generator_add_value,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                randomControllers.add(
                                                  TextEditingController(),
                                                );
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (selectedType == 'returnValue')
                                    TextField(
                                      controller: returnValueController,
                                      decoration: InputDecoration(
                                        labelText:
                                            AppLocalizations.of(
                                              context,
                                            )!.settings_custom_generator_return_value,
                                      ),
                                    ),
                                  TextField(
                                    controller: namespaceController,
                                    decoration: InputDecoration(
                                      labelText:
                                          AppLocalizations.of(
                                            context,
                                          )!.settings_custom_generator_namespace,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.settings_custom_generator_cancel,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  bool valid = true;
                                  String errorMsg = '';
                                  if (namespaceController.text.trim().isEmpty) {
                                    valid = false;
                                    errorMsg =
                                        '${AppLocalizations.of(context)!.settings_custom_generator_namespace} ${AppLocalizations.of(context)!.settings_custom_generator_required}';
                                  } else if (selectedType == 'random' &&
                                      randomControllers.any(
                                        (c) => c.text.trim().isEmpty,
                                      )) {
                                    valid = false;
                                    errorMsg =
                                        '${AppLocalizations.of(context)!.settings_custom_generator_value} ${AppLocalizations.of(context)!.settings_custom_generator_required}';
                                  } else if (selectedType == 'returnValue' &&
                                      returnValueController.text
                                          .trim()
                                          .isEmpty) {
                                    valid = false;
                                    errorMsg =
                                        '${AppLocalizations.of(context)!.settings_custom_generator_return_value} ${AppLocalizations.of(context)!.settings_custom_generator_required}';
                                  }

                                  if (!valid) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(errorMsg)),
                                    );
                                    return;
                                  }

                                  try {
                                    final model = GeneratorCustom.withParams(
                                      custom: selectedType,
                                      returnValue: returnValueController.text,
                                      customList:
                                          selectedType == 'random'
                                              ? randomControllers
                                                  .map((c) => c.text)
                                                  .where((v) => v.isNotEmpty)
                                                  .toList()
                                              : [],
                                      namespace: namespaceController.text,
                                    );
                                    setState(() {
                                      _customGenerators.add(model);
                                    });
                                    await _saveCustomGenerators();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.settings_custom_generator_creation_success,
                                        ),
                                      ),
                                    );
                                    Navigator.of(context).pop();
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppLocalizations.of(
                                                context,
                                              )!.settings_custom_generator_creation_error +
                                              e.toString(),
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.settings_custom_generator_create_button,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),

            SizedBox(height: 16),

            ElevatedButton.icon(
              icon: Icon(Icons.delete_forever, color: Colors.red),
              label: Text(
                AppLocalizations.of(
                  context,
                )!.settings_custom_generator_delete_all,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('custom_generators');
                setState(() {
                  _customGenerators.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(
                        context,
                      )!.settings_custom_generator_delete_all_success,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
