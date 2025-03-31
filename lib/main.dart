import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:browser_extension/providers/settings.dart';
import 'package:browser_extension/utils/Saver/saver.dart';
import 'package:browser_extension/widgets/extension.dart';

void main() async {
  await SettingProvider().initialize();
  await Saver.initialize();
  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingProvider(),
      child: Extension(),
    ),
  );
}
