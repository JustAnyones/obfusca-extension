import 'package:browser_extension/generators/generators.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Generatoraddress extends Generators {
  String City = '';
  String address = '';
  List<String> BoundingBox = [];
  final Random _random = Random();

  Generatoraddress(String short) : super("nera") {
    setDefault(short);
  }

  void setDefault(String short) {
    if (short == 'us') {
      City = 'New York';
      BoundingBox = ['40.4765780', '40.9176300', '-74.2588430', '-73.7002330'];
    } else {
      City = 'Vilnius';
      BoundingBox = ['54.5689058', '54.8323200', '25.0245351', '25.4814574'];
    }
  }

  void setCity(String city) {
    City = city;
    BoundingBox = [];
  }

  void setBoundingBox(List<String> boundingBox) {
    BoundingBox = boundingBox;
  }

  @override
  void setLocalization(BuildContext context) {
    localization = AppLocalizations.of(context)!.generator_street;
  }

  @override
  void generate() async {
    if (isChecked) {
      Map<String, dynamic> info;
      if (BoundingBox.isEmpty) {
        final coords = await getRandomCoords(City);
        info = await getInfo(coords);
      } else {
        final coords = {
          'lat': randomDoubleInRange(
            double.parse(BoundingBox[0]),
            double.parse(BoundingBox[1]),
          ),
          'lng': randomDoubleInRange(
            double.parse(BoundingBox[2]),
            double.parse(BoundingBox[3]),
          ),
        };
        info = await getInfo(coords);
      }
      address = '${info['road']} ${info['house_number']}';
      controller.text = address;
    }
  }

  Future<Map<String, dynamic>> getRandomCoords(String city) async {
    final response = await fetchWithTimeout(
      Uri.parse(
        'https://nominatim.openstreetmap.org/search?city=$city&format=json&limit=1',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.isEmpty ||
          data[0]['boundingbox'] == null ||
          data[0]['boundingbox'].length < 4) {
        throw Exception('Bounding box data is missing');
      }

      final boundingBox = data[0]['boundingbox'];
      double lat = randomDoubleInRange(
        double.parse(boundingBox[0]),
        double.parse(boundingBox[1]),
      );
      double lng = randomDoubleInRange(
        double.parse(boundingBox[2]),
        double.parse(boundingBox[3]),
      );
      return {'lat': lat, 'lng': lng};
    }
    throw Exception('Failed to fetch bounding box');
  }

  Future<Map<String, dynamic>> getInfo(Map<String, dynamic> coords) async {
    String lat = coords['lat'].toString();
    String lng = coords['lng'].toString();
    final response = await fetchWithTimeout(
      Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final info = data['address'] ?? {};
      return {
        'road': info['road'] ?? '',
        'house_number': info['house_number'] ?? '',
        'postcode': info['postcode'] ?? '',
      };
    }
    throw Exception('Failed to fetch address info');
  }

  double randomDoubleInRange(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }

  Future<http.Response> fetchWithTimeout(Uri url) async {
    return await http.get(url).timeout(Duration(seconds: 5));
  }
}
