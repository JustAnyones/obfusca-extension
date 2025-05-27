import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';

import 'package:browser_extension/providers/settings.dart';
import 'package:browser_extension/providers/user.dart';
import 'package:browser_extension/utils/Saver/saver.dart';
import 'package:browser_extension/widgets/extension.dart';
import 'package:browser_extension/utils/drive.dart';
import 'package:browser_extension/utils/session_data.dart';

Future<void> initializeProviders() async {
  await SettingProvider().initialize();
  await UserProvider().initialize();
  await Saver.initialize();
  await Drive.initialize();
  await SessionData.initialize();
}

void main() async {
  WebViewPlatform.instance = WebWebViewPlatform();
  await initializeProviders();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SettingProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
      ],
      child: Extension(),
    ),
  );
}
