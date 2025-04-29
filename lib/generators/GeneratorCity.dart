import 'package:browser_extension/generators/generators.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Generatorcity extends Generators {
  String city = '';
  List<String> Cities = [];

  Generatorcity() : super("nera");

  void setCities(List<String> cities) {
    Cities = cities;
  }

  @override
  void generate() {
    if (isChecked) {
      Random _random = Random();
      this.city = Cities[_random.nextInt(19)];
      controller.text = this.city;
    }
  }

  @override
  void setLocalization(BuildContext context) {
    localization = AppLocalizations.of(context)!.generator_city;
  }
}
