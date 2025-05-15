import 'dart:convert';

import 'package:browser_extension/providers/user.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:browser_extension/utils/format.dart';
import 'package:browser_extension/utils/obfusca.dart';

class EmailViewPage extends StatefulWidget {
  const EmailViewPage({super.key});

  @override
  State<EmailViewPage> createState() => _EmailViewPageState();
}

// Returns HTML part if available, otherwise returns the first part.
Part _getBestContentFormat(List<Part> parts) {
  for (var part in parts) {
    if (part.mediaType == "text/html") {
      // If HTML part is available, return it.
      return part;
    }
  }
  return parts.first;
}

class _EmailViewPageState extends State<EmailViewPage> {
  String? _generalError;
  bool _htmlLoaded = false;

  late final EmailData _message;
  late final String _address;
  late final Part _part;

  late final WebViewController _controller;

  @override
  void initState() async {
    super.initState();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _message = args['email'] as EmailData;
    _address = args['address'] as String;
    _part = _getBestContentFormat(_message.parts);

    if (_part.mediaType == "text/html") {
      print("Initializing webview");
      // Initialize WebView controller for HTML content
      // Severely limited on web platform
      // Based on https://pub.dev/packages/webview_flutter_web/example
      _controller = WebViewController();
      _controller
          .loadHtmlString(_part.content)
          .then((_) {
            print("WebView loaded HTML content");
            setState(() {
              _htmlLoaded = true;
            });
          })
          .catchError((error) {
            setState(() {
              _generalError = "Failed to load HTML content: $error";
            });
          });
    }
  }

  void downloadAttachment(int attachmentIndex) async {
    var (attach, err) = await ObfuscaAPI.getUserEmailAttachment(
      UserProvider.getInstance().userToken!,
      _address,
      _message.uid,
      attachmentIndex,
    );

    if (err != null) {
      setState(() {
        _generalError = "Could not download attachment: $err";
      });
      return;
    }

    await FilePicker.platform
        .saveFile(
          dialogTitle: "Save attachment",
          fileName: attach!.filename,
          bytes: base64Decode(attach.content),
        )
        .then((String? path) {
          if (path != null) {
            print("Attachment saved to $path");
          } else {
            print("Attachment download cancelled");
          }
        })
        .catchError((error) {
          setState(() {
            _generalError = "Failed to save attachment: $error";
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    final errorColor = Colors.red; // TODO: use theme color

    // Ugly workaround to get the available height for the WebView
    // because the WebView doesn't take the full height of the screen
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    double adjustment = 0;

    // TODO: fix eyeballed values
    adjustment += 4 * 8;
    adjustment += 64;
    adjustment += 8;
    adjustment += 24;

    // Adjust for attachment bar
    if (_message.attachments.isNotEmpty) {
      adjustment += 8 + 8 + 16 + 16 + 32;
    }

    final availableHeight =
        screenHeight -
        appBarHeight -
        adjustment; // Adjust for other fixed elements

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.email_view_page_title),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(
                    context,
                  )!.email_view_from(_message.from.toString()),
                ),
                Text(
                  AppLocalizations.of(
                    context,
                  )!.email_view_subject(_message.subject),
                ),
                Text(
                  AppLocalizations.of(
                    context,
                  )!.email_view_date(formatDate(context, _message.date)),
                ),

                if (_generalError != null) ...[
                  SizedBox(height: 16),
                  Text(
                    _generalError ?? "",
                    style: TextStyle(color: errorColor),
                  ),
                ],

                Divider(thickness: 2, color: Colors.grey),

                // Display the content based on the media type
                if (_part.mediaType == "text/html") ...[
                  if (_htmlLoaded) ...[
                    // WebView for HTML content
                    SizedBox(
                      height: availableHeight,
                      // as far as I can tell, it isn't aware of the available height
                      // so this dirty hack is needed
                      child: WebViewWidget(controller: _controller),
                    ),
                  ] else ...[
                    CircularProgressIndicator(),
                  ],
                ] else if (_part.mediaType == "text/plain") ...[
                  SelectableText(_part.content),
                ] else ...[
                  // Fallback to displaying the content as plain text
                  Text(
                    "UNSUPPORTED CONTENT TYPE: ${_part.mediaType}",
                    style: TextStyle(color: errorColor),
                  ),
                  Text(_part.content),
                ],

                Divider(thickness: 2, color: Colors.grey),

                // Display attachments
                if (_message.attachments.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.email_view_attachments),
                ],
                Row(
                  children: [
                    for (var attachment in _message.attachments) ...[
                      InkWell(
                        onTap: () => downloadAttachment(attachment.index),
                        child: Container(
                          padding: EdgeInsets.all(4),
                          margin: EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.attach_file, color: Colors.grey),
                              SizedBox(width: 4),
                              Text(attachment.filename),
                              SizedBox(width: 4),
                              Text(" (${AppLocalizations.of(context)!.email_view_attachment_bytes(attachment.size)})",),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 6),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
