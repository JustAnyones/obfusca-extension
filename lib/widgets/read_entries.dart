import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:browser_extension/utils/Saver/saver.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:browser_extension/providers/user.dart';
import 'package:browser_extension/web/interop.dart';

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
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.entries_title),
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Side Navigation Bar
          Container(
            width: 60,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(height: 20),
                // Home button (now first)
                Tooltip(
                  message: "Home",
                  child: IconButton(
                    icon: Icon(Icons.home),
                    iconSize: 28,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                SizedBox(height: 16),
                // User Profile Button (second)
                Tooltip(
                  message: AppLocalizations.of(context)!.user_profile_page_title,
                  child: IconButton(
                    icon: Icon(Icons.person),
                    iconSize: 28,
                    onPressed: () async {
                      if (UserProvider.getInstance().isLoggedIn) {
                        await navigateToPageRoute('/profile');
                      } else {
                        Navigator.pushNamed(context, '/login');
                      }
                    },
                  ),
                ),
                SizedBox(height: 16),
                // Entries Button (third) - highlighted since this is the current page
                Tooltip(
                  message: AppLocalizations.of(context)!.button_view_entries,
                  child: IconButton(
                    icon: Icon(Icons.list_alt),
                    iconSize: 28,
                    color: Theme.of(context).colorScheme.primary, // Highlight current page icon
                    onPressed: null, // Disabled since we're already on this page
                  ),
                ),
                SizedBox(height: 16),
                // Settings Button (last)
                Tooltip(
                  message: AppLocalizations.of(context)!.settings_title,
                  child: IconButton(
                    icon: Icon(Icons.settings),
                    iconSize: 28,
                    onPressed: () async {
                      // First navigate back to main page, then open settings
                      Navigator.pop(context);
                      await createSettingsPage();
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Main Content - Entries table
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  FutureBuilder<List<TableRow>>(
                    future: _getRows(),
                    builder: (
                      BuildContext context,
                      AsyncSnapshot<List<TableRow>> snapshot,
                    ) {
                      if (!snapshot.hasData) {
                        return CircularProgressIndicator();
                      }
                      return Table(
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
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}