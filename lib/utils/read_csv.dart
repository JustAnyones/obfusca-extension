import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

Future<(List<String>, List<double>)> readCSV(String filePath) async {
  List<String> data = [];
  List<double> freq = [];
  try {

    final csvString = await rootBundle.loadString(filePath);

    final csvTable = const CsvToListConverter().convert(csvString);

    for (var i = 1; i < csvTable.length; i++) {
      final row = csvTable[i];

      data.add(row[0].toString());
      freq.add(double.parse(row[1].toString()));
    }

    return (data, freq);
  } catch (e) {
    print('Error reading file: $e');
    return (data, freq);
  }
}