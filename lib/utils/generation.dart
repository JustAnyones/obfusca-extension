import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:browser_extension/providers/settings.dart';

class Generation {
  static const String geoNamesUsername = 'buhmaster69';
  static final _random = Random();

  static String generateName(
    List<String> names,
    List<double> nameWeights,
    List<String> surnames,
    List<double> surnameWeights,
  ) {
    String name = _weightedRandomChoice(names, nameWeights);
    String surname = _weightedRandomChoice(surnames, surnameWeights);
    return "$name $surname";
  }

  static String _weightedRandomChoice(
    List<String> items,
    List<double> weights,
  ) {
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

  static DateTime getRandomDateTime() {
    int year = 1950 + _random.nextInt(2006 - 1950 + 1);
    int month = _random.nextInt(12) + 1;
    int day = _random.nextInt(DateTime(year, month + 1, 0).day) + 1;

    return DateTime(year, month, day);
  }

  static String getCountry(String short, bool check) {
    switch (short) {
      case 'us':
        return "United States";
      case 'lt':
        return check ? "Lithuania" : "Lietuva";
      default:
        return "Unknown Country";
    }
  }

  static String generateUsername(String name, String surname) {
    int next = 100 + _random.nextInt(1000 - 100);
    return '$name$surname$next';
  }

  static double randomDoubleInRange(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }

  static Future<http.Response> fetchWithTimeout(Uri url) async {
    return await http.get(url).timeout(Duration(seconds: 5));
  }

  static Future<String> getRandomCity(String countryCode) async {
    final response = await fetchWithTimeout(
      Uri.parse(
        'http://api.geonames.org/searchJSON?country=$countryCode&featureClass=P&maxRows=10&username=$geoNamesUsername',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data == null ||
          !data.containsKey('geonames') ||
          data['geonames'].isEmpty) {
        throw Exception('No cities found');
      }
      final cities = data['geonames'];
      final randomCity = cities[_random.nextInt(cities.length)];
      return randomCity['name'].toString();
    }
    throw Exception('Failed to fetch city');
  }

  static Future<Map<String, dynamic>> getRandomCoords(String city) async {
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

  static Future<Map<String, dynamic>> getInfo(
    Map<String, dynamic> coords,
  ) async {
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

  static Future<Map<String, dynamic>> getRandomLocation() async {
    final region = await Future.value(SettingProvider.getInstance().region);
    final city = await getRandomCity(region);
    final coords = await getRandomCoords(city);
    final info = await getInfo(coords);

    return {
      'city': city,
      'street': '${info['road']} ${info['house_number']}',
      'postcode': info['postcode'],
    };
  }
}
