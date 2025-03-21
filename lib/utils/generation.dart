import 'dart:math';

class Generation {
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
    Random random = Random();
    double totalWeight = weights.reduce((a, b) => a + b);
    double randomValue = random.nextDouble() * totalWeight;

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
    final random = Random();
    int year = 1950 + random.nextInt(2006 - 1950 + 1);
    int month = random.nextInt(12) + 1;
    int day = random.nextInt(DateTime(year, month + 1, 0).day) + 1;

    return DateTime(year, month, day);
  }

  static String generateUsername(String name, String surname) {
    final random = Random();
    int next = 100 + random.nextInt(1000 - 100);
    return '$name$surname$next';
  }
}
