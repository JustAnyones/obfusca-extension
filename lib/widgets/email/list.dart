import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:browser_extension/providers/user.dart';
import 'package:browser_extension/utils/format.dart';
import 'package:browser_extension/utils/obfusca.dart';
import 'package:provider/provider.dart';

class EmailListPage extends StatefulWidget {
  const EmailListPage({super.key});

  @override
  State<EmailListPage> createState() => _EmailListPageState();
}

class _EmailListPageState extends State<EmailListPage> {
  String? _generalError;

  late final String _emailAddress;

  bool _isRefreshing = false;

  @override
  void initState() async {
    super.initState();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _emailAddress = args['address'] as String;
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

    var err = await ObfuscaAPI.changeEmailReadStatus(
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

    message.read = !message.read;
    await UserProvider.getInstance().setMessageForEmailAddress(
      _emailAddress,
      message,
    );
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

    Navigator.pushNamed(
      context,
      '/email/view/$_emailAddress/${message.uid}',
      arguments: {'internal': true},
    );
  }

  @override
  Widget build(BuildContext context) {
    final errorColor = Colors.red; // TODO: use theme color
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final List<SlimEmailData?> emails =
            userProvider
                .getMessageUidsForAddress(_emailAddress)
                .map(
                  (uid) => userProvider.getMessageForEmailAddress(
                    _emailAddress,
                    uid,
                  ),
                )
                .toList();

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
            body: SingleChildScrollView(
              child: Padding(
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
                        for (var email in emails) ...[
                          TableRow(
                            decoration: BoxDecoration(
                              color:
                                  email!.read ? Colors.white : Colors.grey[300],
                            ),
                            children: [
                              SizedBox(child: Icon(Icons.email)),
                              Container(
                                padding: EdgeInsets.all(4),
                                child: SelectableText(
                                  formatDate(context, email.date),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(4),
                                child: SelectableText(email.from.toString()),
                              ),
                              Container(
                                padding: EdgeInsets.all(4),
                                width: 180,
                                child: SelectableText(email.subject),
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
                      Text(
                        _generalError ?? "",
                        style: TextStyle(color: errorColor),
                      ),
                      SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
