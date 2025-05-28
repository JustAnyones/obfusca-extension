import 'dart:convert';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:browser_extension/utils/Saver/saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  @override
  Widget build(BuildContext context) {
    int index = ModalRoute.of(context)!.settings.arguments as int;

    List<Widget> params = [];
    Map<String, String> entry = jsonDecode(_entries![index]);
    List<String> keys = entry.keys.toList();
    for (var key in keys) {
      Widget row;
      if (key == 'favicon' || key == 'uid') continue;
      if (entry[key] != '' && entry[key] != null) {
        print(key);
        String namespace = key;
        if (key != "domain") {
          namespace = namespace.substring(11);
          namespace = namespace.replaceAll("_generator", "");
        }
        namespace = namespace[0].toUpperCase() + namespace.substring(1);
        row = Row(
          children: [
            Text(
              "$namespace:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 2),
            SelectableText(entry[key]!),
            SizedBox(width: 12),
            IconButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: entry[key]!));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.clipboard),
                  ),
                );
              },
              icon: Icon(Icons.content_copy),
              alignment: Alignment.centerRight,
            ),
          ],
        );
        params.add(row);
        params.add(SizedBox(height: 16));
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.entry_details)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: params),
      ),
    );
  }
}
