import 'package:browser_extension/settings.dart';
import 'package:flutter/material.dart';
import 'utils/name_generator.dart';
import 'utils/read_csv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Name Generator Extension',
      theme: ThemeData(primarySwatch: Colors.blue),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: Locale('lt'),
      supportedLocales: [Locale('en'), Locale('lt')],
      home: NameGeneratorScreen(),
    );
  }
}

class NameGeneratorScreen extends StatefulWidget {
  @override
  _NameGeneratorScreenState createState() => _NameGeneratorScreenState();
}

class _NameGeneratorScreenState extends State<NameGeneratorScreen> {
  late List<String> names;
  late List<double> nameFreq;
  late List<String> surNames;
  late List<double> surNamesFreq;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();

  String _generatedName = "";

  @override
  void initState() {
    super.initState();
    _loadCSVData();
  }

  Future<void> _loadCSVData() async {
    String namesFilePath;
    String surnamesFilePath;

    // TODO: force reload if settings change
    var region = await SettingsState.getRegion();
    if (region == 'America') {
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
      setState(() {
        _generatedName = 'Error: Could not load name data.';
      });
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
      _generatedName = fullName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.ext_title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),

            // Surname TextField
            TextField(
              controller: _surnameController,
              decoration: InputDecoration(
                labelText: "Surname",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),

            ElevatedButton(
              onPressed: _generateName,
              child: Text("Generate Name"),
            ),
            SizedBox(height: 16),

            Text(
              _generatedName,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
    );
  }
}
