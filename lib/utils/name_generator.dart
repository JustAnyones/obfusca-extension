import 'dart:math';

class NameGenerator {
  static String generateName(List<String> names, List<double> nameWeights, List<String> surnames, List<double> surnameWeights) {

    String name = _weightedRandomChoice(names, nameWeights);
    String surname = _weightedRandomChoice(surnames, surnameWeights);
    return "$name $surname";
  }

  static String _weightedRandomChoice(List<String> items, List<double> weights) {
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
}