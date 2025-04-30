import 'package:browser_extension/generators/generators.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GeneratorSurName extends Generators {
  String surName = '';
  List<String> surNames = [];
  List<double> surNameWeights = [];

  GeneratorSurName() : super("namespace::lastname_generator");

  void setSurnames(List<String> surNames, List<double> surNameWeights) {
    this.surNameWeights = surNameWeights;
    this.surNames = surNames;
  }

  @override
  void generate() {
    this.surName = _weightedRandomChoice(surNames, surNameWeights);
    controller.text = this.surName;
  }

  static String _weightedRandomChoice(
    List<String> items,
    List<double> weights,
  ) {
    Random _random = Random();
    double totalWeight = weights.reduce((a, b) => a + b);
    double randomValue = _random.nextDouble() * totalWeight;

    double cumulativeWeight = 0;
    for (int i = 0; i < items.length; i++) {
      cumulativeWeight += weights[i];
      if (randomValue < cumulativeWeight) {
        return items[i];
      }
    }

    return items.last;
  }

  @override
  void setLocalization(BuildContext context) {
    localization = AppLocalizations.of(context)!.generator_surname_name;
  }
}
