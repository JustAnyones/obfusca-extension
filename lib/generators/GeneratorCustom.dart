import 'package:browser_extension/generators/generators.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GeneratorCustom extends Generators {
  String custom = '';
  String returnValue = '';
  List<String> customList = [];

  GeneratorCustom() : super('');

  void setCustom(
    String custom,
    String returnValue,
    List<String> customList,
    String namespace,
  ) {
    this.custom = custom;
    this.namespace = namespace;
    this.returnValue = returnValue;
    this.customList = customList;
  }

  @override
  void generate() {
    switch (custom) {
      case 'random':
        RandomCustom();
        break;
      case 'returnValue':
        returnValueGen();
        break;
      default:
        controller.text = '';
    }
  }

  void returnValueGen() {
    controller.text = returnValue;
  }

  void RandomCustom() {
    Random _random = Random();
    int num = _random.nextInt(customList.length);
    controller.text = customList[num];
  }

  void setLocalization(BuildContext context) {
    localization = AppLocalizations.of(context)!.generator_custom;
  }
}
