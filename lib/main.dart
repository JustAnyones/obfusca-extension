import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:browser_extension/providers/settings.dart';
import 'package:browser_extension/providers/user.dart';
import 'package:browser_extension/utils/Saver/saver.dart';
import 'package:browser_extension/widgets/extension.dart';

Future<void> initializeProviders() async {
  await SettingProvider().initialize();
  await UserProvider().initialize();
  await Saver.initialize();
}

void main() async {
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
