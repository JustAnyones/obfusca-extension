import 'package:browser_extension/generators/generators.dart';
import 'package:browser_extension/providers/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GeneratorEmail extends Generators {
  GeneratorEmail() : super("namespace::email_generator");

  List<String> getEmails() {
    return UserProvider.getInstance().emailAddresses;
  }

  @override
  void setLocalization(BuildContext context) {
    localization = AppLocalizations.of(context)!.generator_email;
  }
}
