import 'package:browser_extension/generators/generators.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Generatordate extends Generators {
  DateTime dateTime = DateTime.now();

  Generatordate(BuildContext context, localization, String namespace)
    : super(
        AppLocalizations.of(context)!.generator_date_of_birth,
        "namespace::birth_date_generator",
      );

  @override
  void generate() {
    dateTime = getRandomDateTime();
    controller.text = dateTime.toString();
  }

  static DateTime getRandomDateTime() {
    Random _random = Random();
    int year = 1950 + _random.nextInt(2006 - 1950 + 1);
    int month = _random.nextInt(12) + 1;
    int day = _random.nextInt(DateTime(year, month + 1, 0).day) + 1;

    return DateTime(year, month, day);
  }
}
