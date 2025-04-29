import 'package:browser_extension/generators/generators.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GeneratorName extends Generators {
  String name = '';
  List<String> names = [];
  List<double> nameWeights = [];

  GeneratorName() : super("namespace::firstname_generator");

  @override
  void generate() {
    if (isChecked) {
      this.name = _weightedRandomChoice(names, nameWeights);
      controller.text = this.name;
    }
  }

  void setNames(List<String> names, List<double> nameWeights) {
    this.nameWeights = nameWeights;
    this.names = names;
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
    localization = AppLocalizations.of(context)!.generator_name_name;
  }
}
