import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

  late final String _emailAddress;

  Timer? _timer;

  bool _isRefreshing = false;

  @override
  void initState() async {
    super.initState();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _emailAddress = args['address'] as String;

    // Setup periodic refresh of messages
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    fetchMessages();
    _timer = Timer.periodic(Duration(seconds: 15), (Timer timer) {
      fetchMessages();
    });
  }

  Future<void> fetchMessages() async {
    print("fetching messages");
    setState(() {
      _isRefreshing = true;
      _generalError = null;
    });

    var (emails, err) = await ObfuscaAPI.getUserEmails(
      UserProvider.getInstance().userToken!,
      _emailAddress,
    );
    if (err != null) {
      setState(() {
        _isRefreshing = false;
        _generalError = "Could not fetch emails: $err";
      });
      return;
    }
    setState(() {
      _isRefreshing = false;
      if (emails.isEmpty) {
        _generalError = "No emails found";
      }
      for (var email in emails) {
        UserProvider.getInstance().setMessageForEmailAddress(
          _emailAddress,
          email,
        );
      }
    });
  }

  Future<void> changeReadStatus(SlimEmailData message) async {
    setState(() {
      _generalError = null;
    });

    var (err) = await ObfuscaAPI.changeEmailReadStatus(
      UserProvider.getInstance().userToken!,
      _emailAddress,
      message.uid,
      !message.read,
    );
    if (err != null) {
      setState(() {
        _generalError = "Could not change email read status: $err";
      });
      return;
    }
    fetchMessages();
  }

  Future<void> viewMessage(SlimEmailData message) async {
    var cachedMessage = UserProvider.getInstance().getMessageForEmailAddress(
      _emailAddress,
      message.uid,
    );
    if (cachedMessage != null) {
      cachedMessage.read = true;
      await UserProvider.getInstance().setMessageForEmailAddress(
        _emailAddress,
        cachedMessage,
      );
    }

    var (fetchedEmail, err) = await ObfuscaAPI.getUserEmail(
      UserProvider.getInstance().userToken!,
      _emailAddress,
      message.uid,
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

    // On second thought, horrible idea to cache this
    // because it will be a lot of data
    /*UserProvider.getInstance().setMessageForEmailAddress(
      _emailAddress,
      fetchedEmail,
    );
    print("Caching fetched message");*/

    Navigator.pushNamed(
      context,
      '/email/view',
      arguments: {'email': fetchedEmail, 'address': _emailAddress},
    );
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
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(
              context,
            )!.email_message_list_page_title(_emailAddress),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.email_message_list_name,
                    style: TextStyle(fontSize: 18),
                  ),
                  IconButton(
                    onPressed: _isRefreshing ? null : fetchMessages,
                    icon: Icon(Icons.refresh),
                  ),
                ],
              ),
              Table(
                border: TableBorder.all(),
                defaultColumnWidth: IntrinsicColumnWidth(),
                children: [
                  for (var email in UserProvider.getInstance()
                      .getMessagesForEmailAddress(_emailAddress)) ...[
                    TableRow(
                      decoration: BoxDecoration(
                        color: email.read ? Colors.white : Colors.grey[300],
                      ),
                      children: [
                        SizedBox(child: Icon(Icons.email)),
                        Container(
                          padding: EdgeInsets.all(4),
                          child: Text(formatDate(context, email.date)),
                        ),
                        Container(
                          padding: EdgeInsets.all(4),
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
                              await viewMessage(email);
                            },
                          ),
                        ),
                        if (email.read) ...[
                          SizedBox(
                            child: ElevatedButton(
                              onPressed: () {
                                changeReadStatus(email);
                              },
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                )!.email_message_list_mark_as_unread,
                              ),
                            ),
                          ),
                        ] else ...[
                          SizedBox(
                            child: ElevatedButton(
                              onPressed: () {
                                changeReadStatus(email);
                              },
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                )!.email_message_list_mark_as_read,
                              ),
                            ),
                          ),
                        ],
                        /*
                        // Not gonna support this yet
                        SizedBox(
                          child: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {},
                          ),
                        ),*/
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
