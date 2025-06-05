import 'package:browser_extension/generators/generators.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GeneratorPassword extends Generators {
  String password = '';
  bool _isFieldVisible = false;

  GeneratorPassword() : super("namespace::password_generator");

  bool get isFieldVisible => _isFieldVisible;
  void toggleVisibility() {
    _isFieldVisible = !_isFieldVisible;
  }

  @override
  void generate() {
    this.password = generatePassword();
    controller.text = this.password;
  }

  static String generatePassword() {
    const String chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()_+[]{}|;:,.<>?';
    Random _random = Random();
    int length = 20 + _random.nextInt(11);
    return List.generate(
      length,
      (index) => chars[_random.nextInt(chars.length)],
    ).join();
  }

  @override
  void setLocalization(BuildContext context) {
    localization = AppLocalizations.of(context)!.generator_password;
  }
}
