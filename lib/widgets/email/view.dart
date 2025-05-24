import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:browser_extension/providers/user.dart';
import 'package:browser_extension/utils/format.dart';
import 'package:browser_extension/utils/obfusca.dart';

class EmailViewPage extends StatefulWidget {
  final String address;
  final int uid;

  const EmailViewPage({super.key, required this.address, required this.uid});

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

  // Fetched from API
  EmailData? _message = null;
  Part? _part = null;

  late final WebViewController _controller;

  @override
  void initState() async {
    super.initState();
    ObfuscaAPI.getUserEmail(
          UserProvider.getInstance().userToken!,
          widget.address,
          widget.uid,
        )
        .then((result) {
          var (email, error) = result;
          if (error != null) {
            setState(() {
              _generalError = "Could not fetch email: $error";
            });
            return;
          }

          if (email == null) {
            setState(() {
              _generalError = "Email does not exist";
            });
            return;
          }

          _message = email;
          _part = _getBestContentFormat(email.parts);
          initializePart();
        })
        .catchError((error) {
          setState(() {
            _generalError = "Failed to fetch email: $error";
          });
        });
  }

  void initializePart() {
    if (_part!.mediaType == "text/html") {
      print("Initializing webview");
      // Initialize WebView controller for HTML content
      // Severely limited on web platform
      // Based on https://pub.dev/packages/webview_flutter_web/example
      _controller = WebViewController();
      _controller
          .loadHtmlString(_part!.content)
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
    } else {
      // For other media types, just set _htmlLoaded to true
      setState(() {
        _htmlLoaded = true;
      });
    }
  }

  void downloadAttachment(int attachmentIndex) async {
    var (attach, err) = await ObfuscaAPI.getUserEmailAttachment(
      UserProvider.getInstance().userToken!,
      widget.address,
      widget.uid,
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
    // Ugly hack to not show the back button if it's accessed from anywhere
    // other than the email list page.
    final args = ModalRoute.of(context)!.settings.arguments;
    var isFirstRoute = true;
    if (args != null &&
        args is Map<String, dynamic> &&
        args['internal'] != null &&
        args['internal'] == true) {
      isFirstRoute = false;
    }

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
    if (_message != null && _message!.attachments.isNotEmpty) {
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
          automaticallyImplyLeading: !isFirstRoute,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_generalError != null) ...[
                  Text(
                    _generalError ?? "",
                    style: TextStyle(color: errorColor),
                  ),
                  SizedBox(height: 16),
                ],
                if (!_htmlLoaded || _message == null) ...[
                  CircularProgressIndicator(),
                ] else ...[
                  SelectableText(
                    AppLocalizations.of(
                      context,
                    )!.email_view_from(_message!.from.toString()),
                  ),
                  SelectableText(
                    AppLocalizations.of(
                      context,
                    )!.email_view_subject(_message!.subject),
                  ),
                  SelectableText(
                    AppLocalizations.of(
                      context,
                    )!.email_view_date(formatDate(context, _message!.date)),
                  ),

                  Divider(thickness: 2, color: Colors.grey),

                  // Display the content based on the media type
                  if (_part!.mediaType == "text/html") ...[
                    // WebView for HTML content
                    SizedBox(
                      height: availableHeight,
                      // as far as I can tell, it isn't aware of the available height
                      // so this dirty hack is needed
                      child: WebViewWidget(controller: _controller),
                    ),
                  ] else if (_part!.mediaType == "text/plain") ...[
                    SelectableText(_part!.content),
                  ] else ...[
                    // Fallback to displaying the content as plain text
                    Text(
                      "UNSUPPORTED CONTENT TYPE: ${_part!.mediaType}",
                      style: TextStyle(color: errorColor),
                    ),
                    Text(_part!.content),
                  ],

                  Divider(thickness: 2, color: Colors.grey),

                  // Display attachments
                  if (_message!.attachments.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text(AppLocalizations.of(context)!.email_view_attachments),
                  ],
                  Row(
                    children: [
                      for (var attachment in _message!.attachments) ...[
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
                                Text(
                                  " (${AppLocalizations.of(context)!.email_view_attachment_bytes(attachment.size)})",
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 6),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
