import 'package:browser_extension/generators/generators.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GeneratorCustom extends Generators {
  String custom = '';
  String returnValue = '';
  List<String> customList = [];

  GeneratorCustom() : super("");

  GeneratorCustom.withParams({
    required this.custom,
    required this.returnValue,
    required this.customList,
    required String namespace,
  }) : super(namespace);

  void setCustom(
    String custom,
    String returnValue,
    List<String> customList,
    String namespace,
  ) {
    this.custom = custom;
    this.returnValue = returnValue;
    this.customList = customList;
    if (!namespace.contains('namespace::') ||
        !namespace.contains("obfusca::")) {
      this.namespace = namespace;
    } else {
      throw Exception(
        "Namespace should not contain 'namespace::' or 'obfusta::'",
      );
    }
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
    localization = namespace;
  }

  Map<String, dynamic> toJson() => {
    'type': custom,
    'returnValue': returnValue,
    'randomValues': customList,
    'namespace': namespace,
  };

  factory GeneratorCustom.fromJson(Map<String, dynamic> json) =>
      GeneratorCustom.withParams(
        custom: json['type'],
        returnValue: json['returnValue'],
        customList: List<String>.from(json['randomValues']),
        namespace: json['namespace'],
      );
}
