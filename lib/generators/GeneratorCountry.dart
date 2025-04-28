import 'package:browser_extension/generators/generators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Generatorcountry extends Generators {
  String country = '';

  Generatorcountry(BuildContext context, localization, String namespace)
    : super(
        AppLocalizations.of(context)!.generator_country,
        "namespace::country_generator",
      );

  String getCountry(bool check) {
    switch (country) {
      case 'us':
        return "United States";
      case 'lt':
        return check ? "Lithuania" : "Lietuva";
      default:
        return "Unknown Country";
    }
  }
}
