import 'package:browser_extension/generators/generators.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Generatordate extends Generators {
  DateTime dateTime = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  Generatordate() : super("namespace::birth_date_generator");

  @override
  void generate() {
    controller.text = getRandomDateTime().toIso8601String().split('T')[0];
    dateTime = DateTime.parse(controller.text);
    print("generated date: ${controller.text}");
  }

  @override
  String checkNamespace(String namespace) {
    if (this.namespace == namespace) {
      return controller.text;
    } else if (namespace == "namespace::birth_day_generator") {
      return controller.text.split("-")[2];
    } else if (namespace == "namespace::birth_month_generator") {
      return controller.text.split("-")[1];
    } else if (namespace == "namespace::birth_year_generator") {
      return controller.text.split("-")[0];
    }
    return '';
  }

  @override
  bool checkNamespaceBool(String namespace) {
    if (this.namespace == namespace) {
      return true;
    } else if (namespace == "namespace::birth_day_generator") {
      return true;
    } else if (namespace == "namespace::birth_month_generator") {
      return true;
    } else if (namespace == "namespace::birth_year_generator") {
      return true;
    }
    return false;
  }

  static DateTime getRandomDateTime() {
    Random _random = Random();
    int year = 1950 + _random.nextInt(2006 - 1950 + 1);
    int month = _random.nextInt(12) + 1;
    int day = _random.nextInt(DateTime(year, month + 1, 0).day) + 1;

    return DateTime(year, month, day);
  }

  @override
  void setLocalization(BuildContext context) {
    localization = AppLocalizations.of(context)!.generator_date_of_birth;
  }

  @override
  void checkOptions(Map<dynamic, dynamic> options) {
    print("checking options for date generator: ${options["generator"]}");
    switch (options["generator"]) {
      case "namespace::birth_day_generator":
        print("checking options for day generator");
        for (var option in options["options"]) {
          option["selected"] = false;
        }
        for (var option in options["options"]) {
          print(option);
          print("checking option: ${option["value"]} == ${dateTime.day}");
          if (option["value"] != "" &&
              int.parse(option["value"]) == dateTime.day) {
            option["selected"] = true;
          }
        }
        break;
      case "namespace::birth_month_generator":
        print("checking options for month generator");
        for (var option in options["options"]) {
          option["selected"] = false;
        }
        for (var option in options["options"]) {
          print(option);
          print("checking option: ${option["value"]} == ${dateTime.month}");
          if (option["value"] != "" &&
              int.parse(option["value"]) == dateTime.month) {
            option["selected"] = true;
          }
        }
        break;
      case "namespace::birth_year_generator":
        print("checking options for year generator");
        for (var option in options["options"]) {
          option["selected"] = false;
        }
        for (var option in options["options"]) {
          print(option);
          print("checking option: ${option["value"]} == ${dateTime.year}");
          if (option["value"] != "" &&
              int.parse(option["value"]) == dateTime.year) {
            option["selected"] = true;
          }
        }
        break;
    }
  }
}
