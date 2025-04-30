import 'package:browser_extension/generators/generators.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GeneratorSex extends Generators {
  String country;
  String name = '';
  String sex = '';

  GeneratorSex(this.country) : super("namespace::sex_generator");

  Random _random = Random();

  @override
  void generate() {
    if (country == 'lt') {
      if (name.isNotEmpty) {
        if (name[name.length - 1].toLowerCase().codeUnitAt(0) ==
            's'.codeUnitAt(0)) {
          sex = "Vyras";
        } else {
          sex = "Moteris";
        }
      } else {
        sex = "Vyras";
      }
    } else {
      switch (_random.nextInt(2) + 1) {
        case 1:
          sex = "Male";
          break;
        case 2:
          sex = "Female";
          break;
      }
    }
    controller.text = sex;
  }

  @override
  void setLocalization(BuildContext context) {
    localization = AppLocalizations.of(context)!.generator_sex;
  }
}
