import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:browser_extension/providers/settings.dart';
import 'package:browser_extension/providers/user.dart';
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
    _loadSavedValues();
    _nameController.addListener(_saveCurrentValues);
    _surnameController.addListener(_saveCurrentValues);
    _usernameController.addListener(_saveCurrentValues);
    _datecontroller.addListener(_saveCurrentValues);
    _countrycontroller.addListener(_saveCurrentValues);
    _citycontroller.addListener(_saveCurrentValues);
    _addresscontroller.addListener(_saveCurrentValues);
    _postalcontroller.addListener(_saveCurrentValues);
  }

  @override
  void dispose() {
    SettingProvider.getInstance().removeListener(_loadCSVData);
    _nameController.removeListener(_saveCurrentValues);
    _surnameController.removeListener(_saveCurrentValues);
    _usernameController.removeListener(_saveCurrentValues);
    _datecontroller.removeListener(_saveCurrentValues);
    _countrycontroller.removeListener(_saveCurrentValues);
    _citycontroller.removeListener(_saveCurrentValues);
    _addresscontroller.removeListener(_saveCurrentValues);
    _postalcontroller.removeListener(_saveCurrentValues);
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

  Future<void> _loadSavedValues() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _nameController.text = prefs.getString('generated_name') ?? '';
      _surnameController.text = prefs.getString('generated_surname') ?? '';
      _usernameController.text = prefs.getString('generated_username') ?? '';
      _datecontroller.text = prefs.getString('generated_date') ?? '';
      _countrycontroller.text = prefs.getString('generated_country') ?? '';
      _citycontroller.text = prefs.getString('generated_city') ?? '';
      _addresscontroller.text = prefs.getString('generated_address') ?? '';
      _postalcontroller.text = prefs.getString('generated_postal') ?? '';

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

    await prefs.setString('generated_name', _nameController.text);
    await prefs.setString('generated_surname', _surnameController.text);
    await prefs.setString('generated_username', _usernameController.text);
    await prefs.setString('generated_date', _datecontroller.text);
    await prefs.setString('generated_country', _countrycontroller.text);
    await prefs.setString('generated_city', _citycontroller.text);
    await prefs.setString('generated_address', _addresscontroller.text);
    await prefs.setString('generated_postal', _postalcontroller.text);

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

    _saveCurrentValues();
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

  String getGeneratorName(String generator) {
    switch (generator) {
      case "namespace::username_generator":
        return _usernameController.text;
      case "namespace::firstname_generator":
        return _nameController.text;
      case "namespace::lastname_generator":
        return _surnameController.text;
      case "namespace::birthdate_generator":
        return _datecontroller.text;
      case "namespace::birth_day_generator":
        return _datecontroller.text.split('-')[2];
      case "namespace::birth_month_generator":
        return _datecontroller.text.split('-')[1];
      case "namespace::birth_year_generator":
        return _datecontroller.text.split('-')[0];
      case "namespace::country_generator":
        return _countrycontroller.text;
      default:
        return "nera autofill";
    }
  }

  @override
  Widget build(BuildContext context) {
    final generators = getLocalizedGenerators(context);

    final fields = [
      {
        'controller': _nameController,
        'label': AppLocalizations.of(context)!.generator_name_name,
        'isChecked': isChecked_name,
        'onChanged':
            (bool? value) => setState(() => isChecked_name = value ?? false),
      },
      {
        'controller': _surnameController,
        'label': AppLocalizations.of(context)!.generator_surname_name,
        'isChecked': isChecked_surname,
        'onChanged':
            (bool? value) => setState(() => isChecked_surname = value ?? false),
      },
      {
        'controller': _usernameController,
        'label': AppLocalizations.of(context)!.generator_username,
        'isChecked': isChecked_username,
        'onChanged':
            (bool? value) =>
                setState(() => isChecked_username = value ?? false),
      },
      {
        'controller': _citycontroller,
        'label': AppLocalizations.of(context)!.generator_city,
        'isChecked': isChecked_city,
        'onChanged':
            (bool? value) => setState(() => isChecked_city = value ?? false),
      },
      {
        'controller': _countrycontroller,
        'label': AppLocalizations.of(context)!.generator_country,
        'isChecked': isChecked_country,
        'onChanged':
            (bool? value) => setState(() => isChecked_country = value ?? false),
      },
      {
        'controller': _addresscontroller,
        'label': AppLocalizations.of(context)!.generator_street,
        'isChecked': isChecked_address,
        'onChanged':
            (bool? value) => setState(() => isChecked_address = value ?? false),
      },
      {
        'controller': _postalcontroller,
        'label': AppLocalizations.of(context)!.generator_postal_code,
        'isChecked': isChecked_postal,
        'onChanged':
            (bool? value) => setState(() => isChecked_postal = value ?? false),
      },
      {
        'controller': _datecontroller,
        'label': AppLocalizations.of(context)!.generator_date_of_birth,
        'isChecked': isChecked_date,
        'onChanged':
            (bool? value) => setState(() => isChecked_date = value ?? false),
      },
    ];

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
                return CheckboxListTile(
                  title: TextField(
                    controller: field['controller'] as TextEditingController?,
                    decoration: InputDecoration(
                      labelText: field['label'] as String?,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  value: field['isChecked'] as bool?,
                  onChanged: field['onChanged'] as ValueChanged<bool?>?,
                  controlAffinity: ListTileControlAffinity.leading,
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
                  String address = '';
                  String city = '';
                  String country = '';
                  String date = '';
                  String name = '';
                  String postal = '';
                  String surname = '';
                  String username = '';
                  if (isChecked_address) {
                    total++;
                    if (_addresscontroller.text != '') {
                      sum++;
                      address = _addresscontroller.text;
                    }
                  }
                  if (isChecked_city) {
                    total++;
                    if (_citycontroller.text != '') {
                      sum++;
                      city = _citycontroller.text;
                    }
                  }
                  if (isChecked_country) {
                    total++;
                    if (_countrycontroller.text != '') {
                      sum++;
                      country = _countrycontroller.text;
                    }
                  }
                  if (isChecked_date) {
                    total++;
                    if (_datecontroller.text != '') {
                      sum++;
                      date = _datecontroller.text;
                    }
                  }
                  if (isChecked_name) {
                    total++;
                    if (_nameController.text != '') {
                      sum++;
                      name = _nameController.text;
                    }
                  }
                  if (isChecked_postal) {
                    total++;
                    if (_postalcontroller.text != '') {
                      sum++;
                      postal = _postalcontroller.text;
                    }
                  }
                  if (isChecked_surname) {
                    total++;
                    if (_surnameController.text != '') {
                      sum++;
                      surname = _surnameController.text;
                    }
                  }
                  if (isChecked_username) {
                    total++;
                    if (_usernameController.text != '') {
                      sum++;
                      username = _usernameController.text;
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
                      name,
                      surname,
                      favIcon,
                      domain,
                      address,
                      city,
                      country,
                      date,
                      postal,
                      username,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.entry_saved,
                        ),
                      ),
                    );
                  }
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
                      "value": getGeneratorName(
                        _detectedFields[i]["generator"],
                      ),
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

              ElevatedButton(
                onPressed: () {
                  if (UserProvider.getInstance().isLoggedIn) {
                    Navigator.pushNamed(context, '/profile');
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
