import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:browser_extension/utils/obfusca.dart';

class UserRegisterPage extends StatefulWidget {
  const UserRegisterPage({super.key});

  @override
  State<UserRegisterPage> createState() => _UserRegisterPageState();
}

class _UserRegisterPageState extends State<UserRegisterPage> {
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

  void register() async {
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
    var err = await ObfuscaAPI.register(username, password);
    if (err != null) {
      setState(() {
        _generalError = "Could not register: $err";
      });
      return;
    }
    Navigator.pushReplacementNamed(context, '/login');
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
          title: Text(AppLocalizations.of(context)!.user_register_page_title),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  AppLocalizations.of(context)!.user_register_page_hint,
                ),
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
                  onPressed: register,
                  child: Text(
                    AppLocalizations.of(context)!.user_register_page_button,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
