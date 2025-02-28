import 'package:flutter/material.dart';
import 'utils/name_generator.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Name Generator Extension',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NameGeneratorScreen(),
    );
  }
}

class NameGeneratorScreen extends StatefulWidget {
  @override
  _NameGeneratorScreenState createState() => _NameGeneratorScreenState();
}

class _NameGeneratorScreenState extends State<NameGeneratorScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();

  String _generatedName = "";

  void _generateName() {
    String fullName = NameGenerator.generateName();

    List<String> nameParts = fullName.split(" ");
    String name = nameParts[0];
    String surname = nameParts[1];

    setState(() {
      _nameController.text = name;
      _surnameController.text = surname;
      _generatedName = fullName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Name Generator Extension"),
      ),
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
          ],
        ),
      ),
    );
  }
}
