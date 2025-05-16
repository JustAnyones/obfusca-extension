import 'dart:convert';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:browser_extension/utils/Saver/saver.dart';
import 'package:flutter/material.dart';

class EntryPage extends StatefulWidget {
  const EntryPage({super.key});

  @override
  State<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> {
  List<String>? _entries;
  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  void _loadEntries() {
    _entries = Saver.readInfo();
  }

  List<Widget> _getEntryValues(int index) {
    List<Widget> params = [];
    Map<String, String> entry = jsonDecode(_entries![index]);
    List<String> keys = entry.keys.toList();
    for (var key in keys) {
      if (key == 'favicon' || key == 'uid') continue;
      if (entry[key] != '' && entry[key] != null) {
        params.add(Text("$key:\t${entry[key]}"));
        params.add(SizedBox(height: 16));
      }
    }
    return params;
  }

  @override
  Widget build(BuildContext context) {
    int index = ModalRoute.of(context)!.settings.arguments as int;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.entry_details)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: _getEntryValues(index)),
      ),
    );
  }
}
