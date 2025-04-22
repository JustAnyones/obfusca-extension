import 'package:flutter/material.dart';

import 'package:browser_extension/providers/user.dart';
import 'package:browser_extension/utils/format.dart';
import 'package:browser_extension/utils/obfusca.dart';

class EmailListPage extends StatefulWidget {
  const EmailListPage({super.key});

  @override
  State<EmailListPage> createState() => _EmailListPageState();
}

class _EmailListPageState extends State<EmailListPage> {
  String? _generalError;
  List<SlimEmailData> _emails = [];

  late final String _emailAddress;

  @override
  void initState() {
    super.initState();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _emailAddress = args['address'] as String;
  }

  void fetchMessages() async {
    setState(() {
      _generalError = null;
    });

    var (emails, err) = await ObfuscaAPI.getUserEmails(
      UserProvider.getInstance().userToken!,
      _emailAddress,
    );
    if (err != null) {
      setState(() {
        _generalError = "Could not fetch emails: $err";
      });
      return;
    }
    setState(() {
      _emails = emails;
      if (_emails.isEmpty) {
        _generalError = "No emails found";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final errorColor = Colors.red; // TODO: use theme color

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(title: Text("EMAIL LIST FOR $_emailAddress")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text("EMAILS", style: TextStyle(fontSize: 18)),
                  IconButton(
                    onPressed: fetchMessages,
                    icon: Icon(Icons.refresh),
                  ),
                ],
              ),
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
                          child: Text(formatDate(context, email.date)),
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
                            onPressed: () async {
                              var (
                                fetchedEmail,
                                err,
                              ) = await ObfuscaAPI.getUserEmail(
                                UserProvider.getInstance().userToken!,
                                _emailAddress,
                                email.uid,
                              );

                              if (err != null) {
                                setState(() {
                                  _generalError = "Could not fetch email: $err";
                                });
                                return;
                              }
                              if (fetchedEmail == null) {
                                setState(() {
                                  _generalError = "Could not fetch email: $err";
                                });
                                return;
                              }

                              Navigator.pushNamed(
                                context,
                                '/email/view',
                                arguments: {'email': fetchedEmail},
                              );
                            },
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
            ],
          ),
        ),
      ),
    );
  }
}
