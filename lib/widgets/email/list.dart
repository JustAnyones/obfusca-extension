import 'package:flutter/material.dart';

import 'package:browser_extension/providers/user.dart';
import 'package:browser_extension/utils/obfusca.dart';
import 'package:intl/intl.dart';

class EmailListPage extends StatefulWidget {
  const EmailListPage({super.key});

  @override
  State<EmailListPage> createState() => _EmailListPageState();
}

class _EmailListPageState extends State<EmailListPage> {
  String? _generalError;
  List<SlimEmailData> _emails = [];

  @override
  void initState() {
    super.initState();
  }

  String formatDate(DateTime date) {
    DateTime localDate = date.toLocal();
    String locale = Localizations.localeOf(context).languageCode;
    String yearMonthDay = DateFormat.yMd(locale).format(localDate);
    String hourMinutes = DateFormat.Hm(locale).format(localDate);
    String formattedDate = "$yearMonthDay $hourMinutes";
    return formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final emailAddress = args['address'] as String;

    final errorColor = Colors.red; // TODO: use theme color

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(title: Text("EMAIL LIST FOR $emailAddress")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Table(
                border: TableBorder.all(),
                defaultColumnWidth: IntrinsicColumnWidth(),
                children: [
                  for (var email in _emails) ...[
                    TableRow(
                      children: [
                        SizedBox(child: Icon(Icons.email)),
                        Container(
                          padding: EdgeInsets.all(4),
                          child: Text(formatDate(email.date)),
                        ),
                        Container(
                          padding: EdgeInsets.all(4),
                          width: 180,
                          child: Text(
                            "${email.from.name}\n(${email.from.address})",
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(4),
                          width: 180,
                          child: Text(email.subject),
                        ),
                        SizedBox(
                          child: IconButton(
                            icon: Icon(Icons.visibility),
                            onPressed: () {},
                          ),
                        ),
                        SizedBox(
                          child: ElevatedButton(
                            onPressed: () {},
                            child: Text("MARK AS READ/UNREAD"),
                          ),
                        ),
                        SizedBox(
                          child: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              SizedBox(height: 16),
              if (_generalError != null) ...[
                Text(_generalError ?? "", style: TextStyle(color: errorColor)),
                SizedBox(height: 16),
              ],

              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _generalError = null;
                  });

                  var (emails, err) = await ObfuscaAPI.getUserEmails(
                    UserProvider.getInstance().userToken!,
                    emailAddress,
                  );
                  if (err != null) {
                    setState(() {
                      _generalError = "Could not fetch emails: $err";
                    });
                    return;
                  }
                  setState(() {
                    _emails = emails;
                  });
                },
                child: Text("FETCH USER EMAILS"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
