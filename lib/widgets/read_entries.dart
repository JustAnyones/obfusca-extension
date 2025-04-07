import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:browser_extension/utils/Saver/saver.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

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
        ],
      ),
    );
    if (_entries == null) {
      return Future.value(rows);
    }
    for (int i = 0; i < _entries!.length; i++) {
      final entry = jsonDecode(_entries![i]);
      var res = await http.get(Uri.parse(entry['favicon']));
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
                      var bytes = Uint8List.fromList(res.body.codeUnits);
                      var test = img.IcoDecoder().decode(bytes);
                      var image2 = img.JpegEncoder().encode(test!);
                      return Image.memory(
                        image2,
                        errorBuilder: (ctx, ex, trace) {
                          return Text("??");
                        },
                      );
                    },
                  );
                  return image;
                },
              ),
            ),
            Container(child: Text(entry['name'])),
            Container(child: Text(entry['surname'])),
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
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: snapshot.data!,
                );
                return child;
              },
            ),

            ElevatedButton(
              onPressed: () async {
                await Saver.writeEntries();
              },
              child: Text("Export"),
            ),
            ElevatedButton(
              onPressed: () async {
                await Saver.importEntries();
              },
              child: Text("Import"),
            ),
          ],
        ),
      ),
    );
  }
}
