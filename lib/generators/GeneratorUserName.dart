import 'package:browser_extension/generators/generators.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Generatorusername extends Generators {
  String username = '';
  String name;
  String surName;

  Generatorusername(
    this.name,
    this.surName,
    BuildContext context,
    localization,
    String namespace,
  ) : super(
        AppLocalizations.of(context)!.generator_username,
        "namespace::username_generator",
      );
  @override
  void generate() {
    this.username = generateUsername(name, surName);
    controller.text = this.username;
  }

  static String generateUsername(String name, String surname) {
    Random _random = Random();
    int next = 100 + _random.nextInt(1000 - 100);
    return '$name$surname$next';
  }
}
