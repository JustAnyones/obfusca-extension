import 'package:flutter/material.dart';

import 'package:webview_flutter/webview_flutter.dart';

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
  late final Part _part;

  late final WebViewController _controller;

  @override
  void initState() async {
    super.initState();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _message = args['email'] as EmailData;
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

      print(_part.content);
    }
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
        appBar: AppBar(title: Text("VIEWING EMAIL")),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("FROM: ${_message.from.name} (${_message.from.address})"),
                Text("SUBJECT: ${_message.subject}"),
                Text("DATE: ${formatDate(context, _message.date)}"),

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
                    // TODO: Disabled for now as I don't know how to make it use the entire page height
                    //SizedBox.expand(
                    //  child: WebViewWidget(controller: _controller),
                    //),
                    //Expanded(child: WebViewWidget(controller: _controller)),
                    Text(_part.content),
                  ] else ...[
                    CircularProgressIndicator(),
                  ],
                ] else if (_part.mediaType == "text/plain") ...[
                  Text(_part.content),
                ] else ...[
                  // Fallback to displaying the content as plain text
                  Text(
                    "UNSUPPORTED CONTENT TYPE: ${_part.mediaType}",
                    style: TextStyle(color: errorColor),
                  ),
                  Text(_part.content),
                ],

                // Display attachments
                if (_message.attachments.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text("ATTACHMENTS:"),
                ],
                Row(
                  children: [
                    for (var attachment in _message.attachments) ...[
                      Container(
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
                            //Text(" (${attachment.content} bytes)"),
                          ],
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
