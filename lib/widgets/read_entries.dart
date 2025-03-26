import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:browser_extension/utils/Saver/saver.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EntriesPage extends StatefulWidget {
  const EntriesPage({super.key});

  @override
  State<EntriesPage> createState() => _EntriesPageState();
}

class _EntriesPageState extends State<EntriesPage> {
  List<String>? _entries;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    _entries = Saver.readInfo();
  }

  List<TableRow> _getRows() {
    List<TableRow> rows = [];
    rows.add(
      TableRow(
        children: <Widget>[
          Container(child: Text("")),
          Container(
            child: Text(AppLocalizations.of(context)!.generator_name_name),
          ),
          Container(
            child: Text(AppLocalizations.of(context)!.generator_surname_name),
          ),
        ],
      ),
    );
    if (_entries == null) {
      return rows;
    }
    for (int i = 0; i < _entries!.length; i++) {
      final _entry = jsonDecode(_entries![i]);
      rows.add(
        TableRow(
          children: <Widget>[
            Container(
              height: 32,
              child: Builder(
                builder: (context) {
                  if (_entry['favicon'] == null || _entry['favicon'] == "") {
                    return Text("??");
                  }
                  var image = Image.network(
                    _entry['favicon'],
                    width: 16,
                    height: 16,
                    errorBuilder: (ctx, ex, trace) {
                      print(ex);
                      print(trace);
                      return Text("??");
                    },
                  );
                  return image;
                },
              ),
            ),
            Container(child: Text(_entry['name'])),
            Container(child: Text(_entry['surname'])),
          ],
        ),
      );
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.entries_title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Table(
          border: TableBorder.all(),
          columnWidths: const <int, TableColumnWidth>{
            0: FlexColumnWidth(),
            1: FlexColumnWidth(),
            2: FlexColumnWidth(),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: _getRows(),
        ),
      ),
    );
  }
}
