import 'dart:async';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import 'package:browser_extension/providers/settings.dart';
import 'package:browser_extension/generators/gens.dart';
import 'package:browser_extension/utils/read_csv.dart';
import 'package:browser_extension/utils/Saver/saver.dart';
import 'package:browser_extension/web/interop.dart';
import 'package:browser_extension/widgets/sidebar.dart';

class NameGeneratorPage extends StatefulWidget {
  const NameGeneratorPage({super.key});

  @override
  State<NameGeneratorPage> createState() => _NameGeneratorPageState();
}

class _NameGeneratorPageState extends State<NameGeneratorPage> {
  bool _isButtonDisabled = false;
  bool _isAddressDiceDisabled = false;
  bool _isPostalDiceDisabled = false;

  late List<String> names;
  late List<double> nameFreq;
  late List<String> surNames;
  late List<double> surNamesFreq;
  late List<String> cities;
  late List<List<double>> boundingBoxes;
  final List<bool> selectedItems = List.filled(13, false);

  int _frameId = -1;
  List<Map> _detectedFields = [];

  late List<Generators> generatorsList;

  @override
  void initState() {
    super.initState();
    SettingProvider.getInstance().addListener(_loadCSVData);
    _loadCSVData();
    GeneratorCustom custom1 = GeneratorCustom();
    custom1.setCustom("returnValue", "Glorp", [], "custom::glorp");
    GeneratorCustom custom2 = GeneratorCustom();
    List<String> customList = [
      "Glorp",
      "Buh",
      "Guh",
      "Balls",
      "uhh",
      "Balding",
      "BLOOMING",
    ];
    custom2.setCustom("random", "Glorp", customList, "custom::buh");

    generatorsList = [
      GeneratorName(),
      GeneratorSurName(),
      Generatorusername(),
      Generatordate(),
      Generatorcountry(SettingProvider.getInstance().region),
      GeneratorCity(),
      Generatoraddress(SettingProvider.getInstance().region),
      GeneratorPostal(SettingProvider.getInstance().region),
      GeneratorSex(SettingProvider.getInstance().region),
      GeneratorPassword(),
      GeneratorEmail(),
      custom1,
      custom2,
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
    (generatorsList[5] as GeneratorCity).setCities(cities);
    (generatorsList[5] as GeneratorCity).setBoundingBoxes(boundingBoxes);

    for (Generators generator in generatorsList) {
      if (selectedItems[generatorsList.indexOf(generator)]) {
        generator.generate();
        if (generator is GeneratorName) {
          final name = generator.name.trim();
          (generatorsList[8] as GeneratorSex).name = name;
        }
        if (generator is GeneratorCity) {
          final city = generator.boundingBox;
          (generatorsList[6] as Generatoraddress).setBoundingBox(city);
          (generatorsList[7] as GeneratorPostal).setBoundingBox(city);
        }
      }
    }

    if (selectedItems[0] && selectedItems[1]) {
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
    // Only apply cooldown if address or postal code fields are selected
    if (selectedItems[6] || selectedItems[7]) {  // 6 is address, 7 is postal code
      Timer(Duration(seconds: 2), () {
        setState(() {
          _isButtonDisabled = false;
        });
      });
    } else {
      setState(() {
        _isButtonDisabled = false;
      });
    }
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
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Side Navigation Bar with reordered icons
            buildSidebar(context, 'home'),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Add top padding for menu bar spacing
                    SizedBox(height: 32),
                    // Contained expansion tile with fixed height and ClipRect to prevent overflow
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child: ExpansionTile(
                          title: Text(
                            AppLocalizations.of(context)!.expansion_tile,
                          ),
                          initiallyExpanded: false,
                          children: [
                            Container(
                              height: 250,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  top: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              child: ListView.builder(
                                scrollDirection: Axis.vertical,
                                shrinkWrap: true,
                                itemCount: generators.length,
                                itemBuilder: (context, index) {
                                  return Material(
                                    color: Colors.transparent,
                                    child: ListTile(
                                      title: Text(generators[index]),
                                      selected: selectedItems[index],
                                      selectedTileColor: Colors.green,
                                      onTap: () {
                                        setState(() {
                                          selectedItems[index] =
                                              !selectedItems[index];
                                          _saveCurrentValues();
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Fields section
                    ...fields.asMap().entries.map((entry) {
                      final index = entry.key;
                      final field = entry.value;
                      if (!selectedItems[index]) return SizedBox.shrink();
                      return Row(
                        children: [
                          Expanded(
                            child:
                                field['generator'] is GeneratorEmail
                                    ? DropdownButtonFormField<String>(
                                      value:
                                          (field['controller']
                                                  as TextEditingController?)
                                              ?.text,
                                      decoration: InputDecoration(
                                        labelText: field['label'] as String?,
                                        border: OutlineInputBorder(),
                                      ),
                                      isExpanded: true,
                                      items:
                                          (field['generator'] as GeneratorEmail)
                                              .getEmails()
                                              .map(
                                                (email) =>
                                                    DropdownMenuItem<String>(
                                                      value: email,
                                                      child: Text(
                                                        email,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                        maxLines: 1,
                                                      ),
                                                    ),
                                              )
                                              .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          (field['controller']
                                                  as TextEditingController?)
                                              ?.text = value ?? '';
                                        });
                                      },
                                    )
                                    : Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: TextField(
                                          controller:
                                              field['controller']
                                                  as TextEditingController?,
                                          decoration: InputDecoration(
                                            labelText: field['label'] as String?,
                                            border: OutlineInputBorder(),
                                            suffixIcon: field['generator'] is GeneratorPassword
                                                ? IconButton(
                                                    icon: Icon(
                                                      (field['generator'] as GeneratorPassword).isFieldVisible
                                                          ? Icons.visibility
                                                          : Icons.visibility_off,
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        (field['generator'] as GeneratorPassword).toggleVisibility();
                                                      });
                                                    },
                                                  )
                                                : null,
                                          ),
                                          obscureText: field['generator'] is GeneratorPassword && 
                                              !(field['generator'] as GeneratorPassword).isFieldVisible,
                                        ),
                                      ),
                          ),
                          SizedBox(width: 16),  // Increased spacing before dice button
                          IconButton(
                            onPressed: () {
                              final generator = field['generator'] as Generators;
                              final index = generatorsList.indexOf(generator);
                              
                              // Check if it's address or postal field
                              if (index == 6) { // Address field
                                if (_isAddressDiceDisabled) return;
                                setState(() {
                                  _isAddressDiceDisabled = true;
                                });
                                Timer(Duration(seconds: 2), () {
                                  setState(() {
                                    _isAddressDiceDisabled = false;
                                  });
                                });
                              } else if (index == 7) { // Postal field
                                if (_isPostalDiceDisabled) return;
                                setState(() {
                                  _isPostalDiceDisabled = true;
                                });
                                Timer(Duration(seconds: 2), () {
                                  setState(() {
                                    _isPostalDiceDisabled = false;
                                  });
                                });
                              }

                              generator.generate();
                              if (generator is GeneratorCity) {
                                final city = generator.boundingBox;
                                (generatorsList[6] as Generatoraddress)
                                    .setBoundingBox(city);
                                (generatorsList[7] as GeneratorPostal)
                                    .setBoundingBox(city);
                              }
                              if (generator is GeneratorName) {
                                final name = generator.name.trim();
                                (generatorsList[8] as GeneratorSex).name = name;
                              }
                            },
                            icon: Icon(
                              Icons.casino,
                              size: 24,
                              color: (field['generator'] is Generatoraddress && _isAddressDiceDisabled) ||
                                     (field['generator'] is GeneratorPostal && _isPostalDiceDisabled)
                                  ? Colors.grey
                                  : null,
                            ),
                          ),
                        ],
                      );
                    }).toList(),

                    // Action Buttons Row
                    Row(
                      children: [
                        // Generate Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isButtonDisabled ? null : _generateName,
                            child: Text(
                              _isButtonDisabled
                                  ? AppLocalizations.of(context)!.button_wait
                                  : AppLocalizations.of(
                                    context,
                                  )!.button_generate,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        // Clear Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                // Clear all text fields
                                for (Generators generator in generatorsList) {
                                  generator.controller.text = '';
                                }
                                // Save empty values
                                _saveCurrentValues();
                              });
                              // Show confirmation
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('All fields cleared'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade100,
                              foregroundColor: Colors.red.shade900,
                            ),
                            child: Text("Clear All"),
                          ),
                        ),
                      ],
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
                                AppLocalizations.of(
                                  context,
                                )!.entry_empty_fields,
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
                      child: Text(
                        AppLocalizations.of(context)!.button_save_entry,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Detection and field-filling buttons
                    Row(
                      children: [
                        // Detect fields button
                        Expanded(
                          child: ElevatedButton(
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

                              print(
                                "Detected fields size: ${_detectedFields.length}",
                              );
                              print(
                                "Generators size: ${generatorsList.length}",
                              );

                              for (int i = 0; i < generatorsList.length; i++) {
                                for (
                                  int j = 0;
                                  j < _detectedFields.length;
                                  j++
                                ) {
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
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!.detect_fields_button,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),

                    // Fill detected fields button
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
                          // If it's a SELECT type of input
                          if (int.parse(_detectedFields[i]["options"].length) !=
                              0) {
                            for (Generators generator in generatorsList) {
                              if (generator.checkNamespaceBool(
                                _detectedFields[i]["generator"],
                              )) {
                                generator.checkOptions(_detectedFields[i]);
                              }
                            }
                            for (var option in _detectedFields[i]["options"]) {
                              if (option["selected"] == true) {
                                fieldsToFill.add({
                                  "ref": _detectedFields[i]["ref"],
                                  "value": option["value"],
                                });
                              }
                            }
                            continue;
                          }

                          // Otherwise, it's a TEXT type of input
                          // Pick the first generator that matches the namespace
                          // and has a generated value
                          for (var generator in generatorsList) {
                            if (generator.checkNamespaceBool(
                                  _detectedFields[i]["generator"],
                                ) &&
                                generator.isPresent()) {
                              fieldsToFill.add({
                                "ref": _detectedFields[i]["ref"],
                                "value": generator.getValue(),
                              });
                              break;
                            }
                          }
                        }
                        fillFields(_frameId, fieldsToFill);
                      },
                      child: Text(
                        AppLocalizations.of(context)!.fill_fields_button,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
