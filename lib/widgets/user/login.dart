import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:browser_extension/providers/user.dart';
import 'package:browser_extension/utils/obfusca.dart';
import 'package:browser_extension/web/interop.dart';

class UserLoginPage extends StatefulWidget {
  const UserLoginPage({super.key});

  @override
  State<UserLoginPage> createState() => _UserLoginPageState();
}

class _UserLoginPageState extends State<UserLoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _usernameError;
  String? _passwordError;
  String? _generalError;

  bool _hidePassword = true;

  @override
  void initState() {
    super.initState();
  }

  void login() async {
    // Store username and password in variables
    String username = _usernameController.text;
    String password = _passwordController.text;

    // Clear previous error messages
    setState(() {
      _usernameError = null;
      _passwordError = null;
      _generalError = null;
    });

    // Check if username and password are empty
    var ok = true;
    if (username.isEmpty) {
      setState(() {
        _usernameError = AppLocalizations.of(context)!.field_empty;
      });
      ok = false;
    }
    if (password.isEmpty) {
      setState(() {
        _passwordError = AppLocalizations.of(context)!.field_empty;
      });
      ok = false;
    }
    if (!ok) {
      return;
    }

    // Clear the password field
    _passwordController.clear();

    // send http request
    var (data, err) = await ObfuscaAPI.login(username, password);
    if (err != null) {
      setState(() {
        _generalError = "Could not log in: $err";
      });
      return;
    }

    // Save user state
    await UserProvider.getInstance().setUserToken(data!.token, data.dateExpire);
    await navigateToPageRoute("/profile");
    Navigator.pop(context);
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
          title: Text(AppLocalizations.of(context)!.user_login_page_title),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(AppLocalizations.of(context)!.user_login_page_hint),
              ),

              // Username field
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.field_username_title,
                  errorText: _usernameError,
                  border: OutlineInputBorder(),
                ),
              ),

              // Password field
              SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _hidePassword,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.field_password_title,
                  errorText: _passwordError,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),

              // Show an error message if there is one
              // This is a general error message, not specific to username or password
              if (_generalError != null) ...[
                Text(_generalError ?? "", style: TextStyle(color: errorColor)),
                SizedBox(height: 16),
              ],

              Center(
                child: ElevatedButton(
                  onPressed: login,
                  child: Text(
                    AppLocalizations.of(context)!.user_login_page_button,
                  ),
                ),
              ),

              SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text:
                          AppLocalizations.of(
                            context,
                          )!.user_login_page_register_upsell_1 +
                          " ",
                      style: TextStyle(color: Colors.black),
                    ),
                    TextSpan(
                      text:
                          AppLocalizations.of(
                            context,
                          )!.user_login_page_register_upsell_2,
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer:
                          TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushNamed(context, '/register');
                            },
                    ),
                    TextSpan(text: '.', style: TextStyle(color: Colors.black)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
