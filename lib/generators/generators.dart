import 'package:flutter/material.dart';

class Generators {
  bool isChecked = false;
  final TextEditingController controller = TextEditingController();
  String localization = "";
  String namespace;

  Generators(this.namespace);

  String checkNamespace(String namespace) {
    print("Checking namespace: $namespace vs ${this.namespace}");
    if (this.namespace == namespace) {
      print(
        "Namespace matched: $namespace = ${this.namespace}, returning value: ${controller.text}",
      );
      return controller.text;
    }
    return '';
  }

  bool checkNamespaceBool(String namespace) {
    if (this.namespace == namespace) {
      return true;
    }
    return false;
  }

  void generate() {}

  String getValue() {
    return controller.text;
  }

  void setLocalization(BuildContext context) {}

  void checkOptions(Map<dynamic, dynamic> options) {}
}
