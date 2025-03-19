import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:browser_extension/providers/settings.dart';
import 'package:browser_extension/utils/name_generator.dart';
import 'package:browser_extension/utils/read_csv.dart';
import 'package:browser_extension/utils/Saver/saver.dart';
import 'package:browser_extension/web/interop.dart';
import 'package:browser_extension/widgets/settings.dart';

//import '' if (dart.library.html) 'package:browser_extension/web/interop.dart';

class NameGeneratorPage extends StatefulWidget {
  const NameGeneratorPage({super.key});

  @override
  State<NameGeneratorPage> createState() => _NameGeneratorPageState();
}

class _NameGeneratorPageState extends State<NameGeneratorPage> {
  late List<String> names;
  late List<double> nameFreq;
  late List<String> surNames;
  late List<double> surNamesFreq;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();

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

    if (SettingProvider.getInstance().region == 'us') {
      namesFilePath = 'assets/EngNames.csv';
      surnamesFilePath = 'assets/EngSur.csv';
    } else {
      namesFilePath = 'assets/LTNames.csv';
      surnamesFilePath = 'assets/LTSur.csv';
    }

    var result = await readCSV(namesFilePath);
    var result2 = await readCSV(surnamesFilePath);

    setState(() {
      names = result.$1;
      nameFreq = result.$2;
      surNames = result2.$1;
      surNamesFreq = result2.$2;
    });
  }

  void _generateName() {
    if (names.isEmpty ||
        nameFreq.isEmpty ||
        surNames.isEmpty ||
        surNamesFreq.isEmpty) {
      return;
    }

    String fullName = NameGenerator.generateName(
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
      fullName = NameGenerator.generateName(
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

    fullName = '$name $surname';

    setState(() {
      _nameController.text = name;
      _surnameController.text = surname;
    });
  }

  @override
  Widget build(BuildContext context) {
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
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.generator_name_name,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),

              TextField(
                controller: _surnameController,
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.of(context)!.generator_surname_name,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),

              ElevatedButton(
                onPressed: _generateName,
                child: Text(AppLocalizations.of(context)!.button_generate),
              ),
              SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
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
                  Saver.saveInfo(_nameController.text, _surnameController.text);
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
                  Saver.readInfo();
                },
                child: Text("Read"),
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
            ],
          ),
        ),
      ),
    );
  }
}
