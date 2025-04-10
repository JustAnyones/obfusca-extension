import 'package:flutter/material.dart';

class Generators {
  bool isChecked = false;
  final TextEditingController controller = TextEditingController();
  final localization;
  String namespace;

  Generators(this.localization, this.namespace);

  bool checkNamespace(String namespace) {
    if (this.namespace == namespace) {
      return true;
    }
    return false;
  }

  void generate() {}

  String getValue() {
    return controller.text;
  }
}
