import 'package:browser_extension/generators/GeneratorSex.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:browser_extension/providers/settings.dart';
import 'package:browser_extension/providers/user.dart';
import 'package:browser_extension/utils/generation.dart';
import 'package:browser_extension/generators/gens.dart';
import 'package:browser_extension/utils/read_csv.dart';
import 'package:browser_extension/utils/Saver/saver.dart';
import 'package:browser_extension/web/interop.dart';
import 'package:browser_extension/widgets/read_entries.dart';

//import '' if (dart.library.html) 'package:browser_extension/web/interop.dart';

class NameGeneratorPage extends StatefulWidget {
  const NameGeneratorPage({super.key});

  @override
  State<NameGeneratorPage> createState() => _NameGeneratorPageState();
}

class _NameGeneratorPageState extends State<NameGeneratorPage> {
  bool _isButtonDisabled = false;

  late List<String> names;
  late List<double> nameFreq;
  late List<String> surNames;
  late List<double> surNamesFreq;
  late List<String> cities;
  late List<List<double>> boundingBoxes;
  final List<bool> selectedItems = List.filled(10, false);

  int _frameId = -1;
  List<Map> _detectedFields = [];

  late List<Generators> generatorsList;

  @override
  void initState() {
    super.initState();
    SettingProvider.getInstance().addListener(_loadCSVData);
    _loadCSVData();
    generatorsList = [
      GeneratorName(),
      GeneratorSurName(),
      Generatorusername(),
      Generatordate(),
      Generatorcountry(SettingProvider.getInstance().region),
      Generatorcity(),
      Generatoraddress(SettingProvider.getInstance().region),
      Generatorpostal(SettingProvider.getInstance().region),
      GeneratorSex(SettingProvider.getInstance().region),
      GeneratorPassword(),
    ];
    _loadSavedValues();
    for (Generators generator in generatorsList) {
      generator.controller.addListener(_saveCurrentValues);
    }
  }

  Future<void> _loadCSVData() async {
    String namesFilePath;
    String surnamesFilePath;
    String country;

    if (SettingProvider.getInstance().region == 'us') {
      namesFilePath = 'assets/EngNames.csv';
      surnamesFilePath = 'assets/EngSur.csv';
      country = 'United States';
    } else {
      namesFilePath = 'assets/LTNames.csv';
      surnamesFilePath = 'assets/LTSur.csv';
      country = 'Lithuania';
    }

    var result = await readCSV(namesFilePath);
    var result2 = await readCSV(surnamesFilePath);
    var result3 = await readCities('assets/CityList.csv', country);

    setState(() {
      names = result.$1;
      nameFreq = result.$2;
      surNames = result2.$1;
      surNamesFreq = result2.$2;
      cities = result3.$1;
      boundingBoxes = result3.$2;
    });
  }

  @override
  void dispose() {
    SettingProvider.getInstance().removeListener(_loadCSVData);
    for (Generators generator in generatorsList) {
      generator.controller.removeListener(_saveCurrentValues);
    }
    super.dispose();
  }

  Future<void> _loadSavedValues() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      for (int i = 0; i < generatorsList.length; i++) {
        generatorsList[i].controller.text =
            prefs.getString(
              'generated_${generatorsList[i].runtimeType.toString().toLowerCase()}',
            ) ??
            '';
      }

      List<String>? selectedIndices = prefs.getStringList('selected_items');
      if (selectedIndices != null) {
        for (int i = 0; i < selectedItems.length; i++) {
          selectedItems[i] = false;
        }

        for (String indexStr in selectedIndices) {
          int index = int.tryParse(indexStr) ?? -1;
          if (index >= 0 && index < selectedItems.length) {
            selectedItems[index] = true;
          }
        }
      }
    });
  }

  Future<void> _saveCurrentValues() async {
    final prefs = await SharedPreferences.getInstance();

    for (Generators generator in generatorsList) {
      await prefs.setString(
        'generated_${generator.runtimeType.toString().toLowerCase()}',
        generator.controller.text,
      );
    }

    List<String> selectedItemsStrings = [];
    for (int i = 0; i < selectedItems.length; i++) {
      if (selectedItems[i]) {
        selectedItemsStrings.add(i.toString());
      }
    }
    await prefs.setStringList('selected_items', selectedItemsStrings);
  }

  void _generateName() async {
    setState(() {
      _isButtonDisabled = true;
    });

    if (names.isEmpty ||
        nameFreq.isEmpty ||
        surNames.isEmpty ||
        surNamesFreq.isEmpty) {
      return;
    }

    (generatorsList[0] as GeneratorName).setNames(names, nameFreq);
    (generatorsList[1] as GeneratorSurName).setSurnames(surNames, surNamesFreq);
    (generatorsList[5] as Generatorcity).setCities(cities);
    (generatorsList[5] as Generatorcity).setBoundingBoxes(boundingBoxes);

    for (Generators generator in generatorsList) {
      if (generator.isChecked) {
        generator.generate();
        if (generator is GeneratorName) {
          final name = generator.name.trim();
          (generatorsList[8] as GeneratorSex).name = name;
        }
        if (generator is Generatorcity) {
          final city = generator.boundingBox;
          (generatorsList[6] as Generatoraddress).setBoundingBox(city);
          (generatorsList[7] as Generatorpostal).setBoundingBox(city);
        }
      }
    }

    if (generatorsList[0].isChecked && generatorsList[1].isChecked) {
      String name = (generatorsList[0] as GeneratorName).name;
      String surname = (generatorsList[1] as GeneratorSurName).surName;
      surname = surname[0].toUpperCase() + surname.substring(1).toLowerCase();
      while (true) {
        if (name[name.length - 1].codeUnitAt(0) == 's'.codeUnitAt(0) &&
            surname[surname.length - 1].codeUnitAt(0) == 's'.codeUnitAt(0)) {
          break;
        } else if (name[name.length - 1].codeUnitAt(0) != 's'.codeUnitAt(0) &&
            surname[surname.length - 1].codeUnitAt(0) != 's'.codeUnitAt(0)) {
          break;
        }
        generatorsList[0].generate();
        generatorsList[1].generate();
        name = (generatorsList[0] as GeneratorName).name;
        surname = (generatorsList[1] as GeneratorSurName).surName;
        surname = surname[0].toUpperCase() + surname.substring(1).toLowerCase();
      }
    }

    _saveCurrentValues();
    Timer(Duration(seconds: 2), () {
      setState(() {
        _isButtonDisabled = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> generators = [];
    for (Generators generator in generatorsList) {
      generator.setLocalization(context);
      generators.add(generator.localization);
    }

    final fields =
        generatorsList.asMap().entries.map((entry) {
          final generator = entry.value;
          return {
            'controller': generator.controller,
            'label': generator.localization,
            'isChecked': generator.isChecked,
            'onChanged':
                (bool? value) => setState(() {
                  generator.isChecked = value ?? false;
                  _saveCurrentValues();
                }),
            'generator': generator,
          };
        }).toList();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.ext_title)),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ExpansionTile(
                title: Text(AppLocalizations.of(context)!.expansion_tile),
                initiallyExpanded: false,
                children: [
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      itemCount: generators.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(generators[index]),
                          selected: selectedItems[index],
                          selectedTileColor: Colors.green,
                          onTap: () {
                            setState(() {
                              selectedItems[index] = !selectedItems[index];
                              _saveCurrentValues(); // Save when selection changes
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ...fields.asMap().entries.map((entry) {
                final index = entry.key;
                final field = entry.value;
                if (!selectedItems[index]) return SizedBox.shrink();
                return Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: TextField(
                          controller:
                              field['controller'] as TextEditingController?,
                          decoration: InputDecoration(
                            labelText: field['label'] as String?,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        value: field['isChecked'] as bool?,
                        onChanged: field['onChanged'] as ValueChanged<bool?>?,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        final generator = field['generator'] as Generators;
                        generator.generate();
                        if (generator is Generatorcity) {
                          final city = generator.boundingBox;
                          (generatorsList[6] as Generatoraddress)
                              .setBoundingBox(city);
                          (generatorsList[7] as Generatorpostal).setBoundingBox(
                            city,
                          );
                        }
                        if (generator is GeneratorName) {
                          final name = generator.name.trim();
                          (generatorsList[8] as GeneratorSex).name = name;
                        }
                      },
                      icon: Icon(Icons.casino, size: 24),
                    ),
                  ],
                );
              }).toList(),
              ElevatedButton(
                onPressed: _isButtonDisabled ? null : _generateName,
                child: Text(
                  _isButtonDisabled
                      ? AppLocalizations.of(context)!.button_wait
                      : AppLocalizations.of(context)!.button_generate,
                ),
              ),
              SizedBox(height: 16),

              ElevatedButton(
                onPressed: () async {
                  int total = 0;
                  int sum = 0;
                  List<String> saverFields = [];
                  for (Generators generator in generatorsList) {
                    if (generator.isChecked) {
                      total++;
                      if (generator.controller.text != '') {
                        sum++;
                        saverFields.add(generator.controller.text);
                      }
                    }
                  }

                  if (total == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.entry_no_fields,
                        ),
                      ),
                    );
                  } else if (sum < total) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.entry_empty_fields,
                        ),
                      ),
                    );
                  } else if (sum == total) {
                    String domain = await getURL();
                    String favIcon = await getFavIconUrl();
                    Saver.saveInfo(
                      saverFields[0],
                      saverFields[1],
                      favIcon,
                      domain,
                      saverFields[6],
                      saverFields[5],
                      saverFields[4],
                      saverFields[3],
                      saverFields[7],
                      saverFields[2],
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.entry_saved,
                        ),
                      ),
                    );
                  }
                },
                child: Text(AppLocalizations.of(context)!.button_save_entry),
              ),
              SizedBox(height: 16),

              ElevatedButton(
                onPressed: () async {
                  var result = await queryFields();
                  if (result["status"] != "FOUND") {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.detect_fail,
                        ),
                      ),
                    );
                    return;
                  }

                  _frameId = result["frameId"];
                  _detectedFields = result["data"];

                  print("Detected fields size: ${_detectedFields.length}");
                  print("Generators size: ${generatorsList.length}");

                  for (int i = 0; i < generatorsList.length; i++) {
                    for (int j = 0; j < _detectedFields.length; j++) {
                      if (generatorsList[i].checkNamespaceBool(
                        _detectedFields[j]["generator"],
                      )) {
                        setState(() {
                          selectedItems[i] = true;
                          generatorsList[i].isChecked = true;
                        });
                      }
                    }
                  }

                  print("Received fields:");
                  print(_detectedFields);
                },
                child: Text("Detect fields from current website"),
              ),
              SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  if (_detectedFields.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.detect_fail,
                        ),
                      ),
                    );
                    return;
                  }

                  List<Map<String, dynamic>> fieldsToFill = [];
                  for (var i = 0; i < _detectedFields.length; i++) {
                    fieldsToFill.add({
                      "ref": _detectedFields[i]["ref"],
                      "value": generatorsList
                          .map(
                            (generator) => generator.checkNamespace(
                              _detectedFields[i]["generator"],
                            ),
                          )
                          .firstWhere(
                            (value) => value.isNotEmpty,
                            orElse: () => '',
                          ),
                    });
                  }
                  fillFields(_frameId, fieldsToFill);
                },
                child: Text("Fill detected fields"),
              ),
              SizedBox(height: 16),

              ElevatedButton(
                onPressed: () async {
                  await createSettingsPage();
                  /*
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsPage()),
                  );
                  */
                },
                child: Text(AppLocalizations.of(context)!.settings_title),
              ),
              SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EntriesPage()),
                  );
                },
                child: Text(AppLocalizations.of(context)!.button_view_entries),
              ),

              ElevatedButton(
                onPressed: () async {
                  if (UserProvider.getInstance().isLoggedIn) {
                    await navigateToPageRoute('/profile');
                  } else {
                    Navigator.pushNamed(context, '/login');
                  }
                },
                child: Text(
                  AppLocalizations.of(context)!.user_profile_page_title,
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
