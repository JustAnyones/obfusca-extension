import 'package:flutter/services.dart' show rootBundle;

Future<(List<String>, List<double>)> readCSV(String filePath) async {
  List<String> data = [];
  List<double> freq = [];

  try {
    final csvString = await rootBundle.loadString(filePath);
    var lines = csvString.split("\n");
    for (var i = 0; i < lines.length; i++) {
      if (lines[i] == "") break;
      var fields = lines[i].split(",");
      data.add(fields[0].toString());
      freq.add(double.parse(fields[1].toString()));
    }
    return (data, freq);
  } catch (e) {
    print('Error reading file: $e');
    return (data, freq);
  }
}

Future<(List<String>, List<List<double>>)> readCities(
  String filePath,
  String countryCode,
) async {
  List<String> cities = [];
  List<List<double>> boundingBoxes = [];

  try {
    final csvString = await rootBundle.loadString(filePath);
    var lines = csvString.split("\n");
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) break;
      var fields = lines[i].split(",");
      if (fields[1].trim() == countryCode) {
        cities.add(fields[0].trim());
        boundingBoxes.add([
          double.parse(fields[2].trim()),
          double.parse(fields[3].trim()),
          double.parse(fields[4].trim()),
          double.parse(fields[5].trim()),
        ]);
      }
    }
    return (cities, boundingBoxes);
  } catch (e) {
    print('Error reading file: $e');
    return (cities, boundingBoxes);
  }
}
