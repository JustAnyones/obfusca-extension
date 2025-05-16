import 'package:browser_extension/generators/generators.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Generatorcity extends Generators {
  String city = '';
  List<String> Cities = [];
  List<List<double>> boundingBoxes = [];
  List<String> boundingBox = [];

  Generatorcity() : super("nera");

  void setCities(List<String> cities) {
    Cities = cities;
  }

  void setBoundingBoxes(List<List<double>> boundingBoxes) {
    this.boundingBoxes = boundingBoxes;
  }

  @override
  void generate() {
    Random _random = Random();
    int num = _random.nextInt(19);
    this.city = Cities[num];
    boundingBox = [
      boundingBoxes[num][0].toString(),
      boundingBoxes[num][1].toString(),
      boundingBoxes[num][2].toString(),
      boundingBoxes[num][3].toString(),
    ];
    controller.text = this.city;
  }

  @override
  void setLocalization(BuildContext context) {
    localization = AppLocalizations.of(context)!.generator_city;
  }

  @override
  void checkOptions(Map<dynamic, dynamic> options) {
    for (var option in options["options"]) {
      option["selected"] = false;
    }
    for (var option in options["options"]) {
      if (option["value"] == city) {
        option["selected"] = true;
      }
    }
  }
}
