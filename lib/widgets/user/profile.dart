import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:browser_extension/providers/user.dart';
import 'package:browser_extension/utils/obfusca.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String? _generalError;

  @override
  void initState() {
    super.initState();
  }

  void logout() async {
    var err = await ObfuscaAPI.logout(UserProvider.getInstance().userToken!);
    if (err != null) {
      setState(() {
        _generalError = "Could not log in: $err";
      });
      return;
    }

    await UserProvider.getInstance().clearUserToken();
    Navigator.pushReplacementNamed(context, "/login");
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
          title: Text(AppLocalizations.of(context)!.user_profile_page_title),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ElevatedButton(
                  onPressed: logout,
                  child: Text(
                    AppLocalizations.of(
                      context,
                    )!.user_profile_page_logout_button,
                  ),
                ),
              ),
              // Show an error message if there is one
              // This is a general error message, not specific to username or password
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
