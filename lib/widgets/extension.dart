import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:browser_extension/providers/settings.dart';
import 'package:browser_extension/widgets/entry_info.dart';
import 'package:browser_extension/widgets/generator.dart';
import 'package:browser_extension/widgets/user/login.dart';
import 'package:browser_extension/widgets/user/profile.dart';
import 'package:browser_extension/widgets/user/register.dart';

class Extension extends StatefulWidget {
  const Extension({super.key});

  @override
  State<Extension> createState() => _ExtensionState();
}

class _ExtensionState extends State<Extension> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingProvider>(
      builder: (context, localeProvider, child) {
        return MaterialApp(
          title: 'Name Generator Extension',
          theme: ThemeData(primarySwatch: Colors.blue),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: localeProvider.locale,
          supportedLocales: [Locale('en'), Locale('lt')],
          home: NameGeneratorPage(),
          routes: {
            '/entry': (context) => const EntryPage(),
            '/login': (context) => const UserLoginPage(),
            '/register': (context) => const UserRegisterPage(),
            '/profile': (context) => const UserProfilePage(),
          },
        );
      },
    );
  }
}
