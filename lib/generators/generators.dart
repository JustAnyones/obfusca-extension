import 'package:flutter/material.dart';

class Generators {
  bool isChecked = false;
  final TextEditingController controller = TextEditingController();
  String localization = "";
  String namespace;

  Generators(this.namespace);

  String checkNamespace(String namespace) {
    if (this.namespace == namespace) {
      return controller.text;
    }
    return '';
  }

  void generate() {}

  String getValue() {
    return controller.text;
  }

  void setLocalization(BuildContext context) {}
}
