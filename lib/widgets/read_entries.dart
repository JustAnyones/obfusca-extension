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

  void _loadEntries() {
    _entries = Saver.readInfo();
  }

  Future<List<TableRow>> _getRows() async {
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
          Container(),
        ],
      ),
    );
    if (_entries == null) {
      return Future.value(rows);
    }
    for (int i = 0; i < _entries!.length; i++) {
      final entry = jsonDecode(_entries![i]);
      rows.add(
        TableRow(
          children: <Widget>[
            Container(
              height: 32,
              child: Builder(
                builder: (context) {
                  if (entry['favicon'] == null || entry['favicon'] == "") {
                    return Text("??");
                  }
                  var image = Image.network(
                    entry['favicon'],
                    errorBuilder: (ctx, ex, trace) {
                      return Text("??");
                    },
                  );
                  return image;
                },
              ),
            ),
            Container(child: Text(entry['name'])),
            Container(child: Text(entry['surname'])),
            Container(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/entry', arguments: i);
                },
                child: Text(AppLocalizations.of(context)!.button_entry_details),
              ),
            ),
          ],
        ),
      );
    }
    return Future.value(rows);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.entries_title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            FutureBuilder<List<TableRow>>(
              future: _getRows(),
              builder: (
                BuildContext context,
                AsyncSnapshot<List<TableRow>> snapshot,
              ) {
                var child = Table(
                  border: TableBorder.all(),
                  columnWidths: const <int, TableColumnWidth>{
                    0: FlexColumnWidth(),
                    1: FlexColumnWidth(),
                    2: FlexColumnWidth(),
                    3: FlexColumnWidth(),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: snapshot.data!,
                );
                return child;
              },
            ),
          ],
        ),
      ),
    );
  }
}
