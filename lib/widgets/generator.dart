import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:browser_extension/providers/settings.dart';
import 'package:browser_extension/utils/generation.dart';
import 'package:browser_extension/utils/read_csv.dart';
import 'package:browser_extension/utils/Saver/saver.dart';
import 'package:browser_extension/web/interop.dart';
import 'package:browser_extension/widgets/settings.dart';
import 'package:browser_extension/widgets/read_entries.dart';

//import '' if (dart.library.html) 'package:browser_extension/web/interop.dart';

class NameGeneratorPage extends StatefulWidget {
  const NameGeneratorPage({super.key});

  @override
  State<NameGeneratorPage> createState() => _NameGeneratorPageState();
}

class _NameGeneratorPageState extends State<NameGeneratorPage> {
  bool _isButtonDisabled = false;
  bool isChecked_name = true;
  bool isChecked_surname = true;
  bool isChecked_username = true;
  bool isChecked_date = true;
  bool isChecked_country = true;
  bool isChecked_city = true;
  bool isChecked_address = true;
  bool isChecked_postal = true;

  late List<String> names;
  late List<double> nameFreq;
  late List<String> surNames;
  late List<double> surNamesFreq;
  late List<String> cities;
  final List<bool> selectedItems = List.filled(8, false);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _datecontroller = TextEditingController();
  final TextEditingController _countrycontroller = TextEditingController();
  final TextEditingController _citycontroller = TextEditingController();
  final TextEditingController _addresscontroller = TextEditingController();
  final TextEditingController _postalcontroller = TextEditingController();

  int _frameId = -1;
  List<Map> _detectedFields = [];

  @override
  void initState() {
    super.initState();
    SettingProvider.getInstance().addListener(_loadCSVData);
    _loadCSVData();
  }

  @override
  void dispose() {
    SettingProvider.getInstance().removeListener(_loadCSVData);
    super.dispose();
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
      cities = result3;
    });
  }

  void _generateName() async {
    setState(() {
      _isButtonDisabled = true;
    });

    final locationInfo = await Generation.getRandomLocation(cities);
    if (names.isEmpty ||
        nameFreq.isEmpty ||
        surNames.isEmpty ||
        surNamesFreq.isEmpty) {
      return;
    }

    String fullName = Generation.generateName(
      names,
      nameFreq,
      surNames,
      surNamesFreq,
    );

    List<String> nameParts = fullName.split(" ");
    String name = nameParts[0];
    String surname = nameParts[1];
    surname = surname[0].toUpperCase() + surname.substring(1).toLowerCase();

    while (true) {
      if (name[name.length - 1].codeUnitAt(0) == 's'.codeUnitAt(0) &&
          surname[surname.length - 1].codeUnitAt(0) == 's'.codeUnitAt(0)) {
        break;
      } else if (name[name.length - 1].codeUnitAt(0) != 's'.codeUnitAt(0) &&
          surname[surname.length - 1].codeUnitAt(0) != 's'.codeUnitAt(0)) {
        break;
      }
      fullName = Generation.generateName(
        names,
        nameFreq,
        surNames,
        surNamesFreq,
      );
      nameParts = fullName.split(" ");
      name = nameParts[0];
      surname = nameParts[1];
      surname = surname[0].toUpperCase() + surname.substring(1).toLowerCase();
    }

    setState(() {
      if (isChecked_name) _nameController.text = name;
      if (isChecked_surname) _surnameController.text = surname;
      if (isChecked_username) {
        _usernameController.text = Generation.generateUsername(name, surname);
      }
      if (isChecked_date) {
        _datecontroller.text =
            Generation.getRandomDateTime().toIso8601String().split('T')[0];
      }
      if (isChecked_country) {
        _countrycontroller.text = Generation.getCountry(
          SettingProvider.getInstance().region,
          false,
        );
      }
      if (isChecked_city) _citycontroller.text = locationInfo['city'];
      if (isChecked_address) _addresscontroller.text = locationInfo['street'];
      if (isChecked_postal) _postalcontroller.text = locationInfo['postcode'];
    });

    Timer(Duration(seconds: 2), () {
      setState(() {
        _isButtonDisabled = false;
      });
    });
  }

  List<String> getLocalizedGenerators(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return [
      localizations.generator_name_name,
      localizations.generator_surname_name,
      localizations.generator_username,
      localizations.generator_city,
      localizations.generator_country,
      localizations.generator_street,
      localizations.generator_postal_code,
      localizations.generator_date_of_birth,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final generators = getLocalizedGenerators(context);

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
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              if (selectedItems[0])
                CheckboxListTile(
                  title: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context)!.generator_name_name,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  value: isChecked_name,
                  onChanged: (bool? value) {
                    setState(() {
                      isChecked_name = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              if (selectedItems[1])
                CheckboxListTile(
                  title: TextField(
                    controller: _surnameController,
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context)!.generator_surname_name,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  value: isChecked_surname,
                  onChanged: (bool? value) {
                    setState(() {
                      isChecked_surname = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              if (selectedItems[2])
                CheckboxListTile(
                  title: TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context)!.generator_username,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  value: isChecked_username,
                  onChanged: (bool? value) {
                    setState(() {
                      isChecked_username = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              if (selectedItems[3])
                CheckboxListTile(
                  title: TextField(
                    controller: _citycontroller,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.generator_city,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  value: isChecked_city,
                  onChanged: (bool? value) {
                    setState(() {
                      isChecked_city = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              if (selectedItems[4])
                CheckboxListTile(
                  title: TextField(
                    controller: _countrycontroller,
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context)!.generator_country,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  value: isChecked_country,
                  onChanged: (bool? value) {
                    setState(() {
                      isChecked_country = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              if (selectedItems[5])
                CheckboxListTile(
                  title: TextField(
                    controller: _addresscontroller,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.generator_street,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  value: isChecked_address,
                  onChanged: (bool? value) {
                    setState(() {
                      isChecked_address = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              if (selectedItems[6])
                CheckboxListTile(
                  title: TextField(
                    controller: _postalcontroller,
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context)!.generator_postal_code,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  value: isChecked_postal,
                  onChanged: (bool? value) {
                    setState(() {
                      isChecked_postal = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              if (selectedItems[7])
                CheckboxListTile(
                  title: TextField(
                    controller: _datecontroller,
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context)!.generator_date_of_birth,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  value: isChecked_date,
                  onChanged: (bool? value) {
                    setState(() {
                      isChecked_date = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
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
                  if (_nameController.text == '' &&
                      _surnameController.text == '') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.missing_name_surname,
                        ),
                      ),
                    );
                    return;
                  }
                  var favIcon = await getFavIconUrl();
                  Saver.saveInfo(
                    _nameController.text,
                    _surnameController.text,
                    favIcon.toString(),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.entry_saved),
                    ),
                  );
                },
                child: Text(AppLocalizations.of(context)!.button_save_entry),
              ),
              SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  Saver.clear();
                },
                child: Text("Clear"),
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
                      "value":
                          _detectedFields[i]["generator"], // TODO: perform actual generation
                    });
                  }
                  fillFields(_frameId, fieldsToFill);
                },
                child: Text("Fill detected fields"),
              ),
              SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsPage()),
                  );
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
            ],
          ),
        ),
      ),
    );
  }
}
