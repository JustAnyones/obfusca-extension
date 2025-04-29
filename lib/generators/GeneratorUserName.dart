import 'package:browser_extension/generators/generators.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:english_words/english_words.dart';

class Generatorusername extends Generators {
  String username = '';

  Generatorusername() : super("namespace::username_generator");
  @override
  void generate() {
    if (isChecked) {
      this.username = generateUsername();
      controller.text = this.username;
    }
  }

  static String generateUsername() {
    Random _random = Random();
    int next = 100 + _random.nextInt(1000 - 100);
    final wordPair = WordPair.random();
    return '$wordPair$next';
  }

  @override
  void setLocalization(BuildContext context) {
    localization = AppLocalizations.of(context)!.generator_username;
  }
}
