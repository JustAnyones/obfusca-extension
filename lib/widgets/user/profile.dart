import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:browser_extension/providers/user.dart';
import 'package:browser_extension/utils/obfusca.dart';
import 'package:browser_extension/web/interop.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String? _generalError;

  @override
  void initState() async {
    super.initState();
    await fetchAddresses();
  }

  Future<void> fetchAddresses() async {
    setState(() {
      _generalError = null;
    });
    var (emails, err) = await ObfuscaAPI.getUserAddresses(
      UserProvider.getInstance().userToken!,
    );
    if (err != null) {
      setState(() {
        _generalError = "Could not fetch email addresses: $err";
      });
      return;
    }
    setState(() {
      UserProvider.getInstance().setEmailAddresses(emails);
    });
  }

  void logout() async {
    var err = await ObfuscaAPI.logout(UserProvider.getInstance().userToken!);
    if (err != null) {
      setState(() {
        _generalError = "Could not log in: $err";
      });
      return;
    }

    await UserProvider.getInstance().clearUserState();
    await closeCurrentTab();
  }

  void createNewAddress() async {
    setState(() {
      _generalError = null;
    });
    var err = await ObfuscaAPI.createAddress(
      UserProvider.getInstance().userToken!,
    );
    if (err != null) {
      setState(() {
        _generalError = "Could not create new address: $err";
      });
      return;
    }
    await fetchAddresses();
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
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.user_profile_email_title,
                    style: TextStyle(fontSize: 18),
                  ),
                  ElevatedButton(
                    onPressed: createNewAddress,
                    child: Text(
                      AppLocalizations.of(
                        context,
                      )!.user_profile_email_create_button,
                    ),
                  ),
                  IconButton(
                    onPressed: fetchAddresses,
                    icon: Icon(Icons.refresh),
                  ),
                ],
              ),
              for (var emailAddress
                  in UserProvider.getInstance().emailAddresses) ...[
                Row(
                  children: [
                    Icon(Icons.email, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(emailAddress),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/email/list',
                          arguments: {'address': emailAddress},
                        );
                      },
                      child: Text(
                        AppLocalizations.of(
                          context,
                        )!.user_profile_email_view_button,
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: emailAddress));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(
                                context,
                              )!.user_profile_email_copy_toast,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        AppLocalizations.of(
                          context,
                        )!.user_profile_email_copy_button,
                      ),
                    ),
                  ],
                ),
              ],
              // Show an error message if there is one
              // This is a general error message, not specific to username or password
              if (_generalError != null) ...[
                Text(_generalError ?? "", style: TextStyle(color: errorColor)),
                SizedBox(height: 16),
              ],
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
            ],
          ),
        ),
      ),
    );
  }
}
