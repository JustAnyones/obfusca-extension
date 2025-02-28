import 'dart:math';

class NameGenerator {
  static String generateName() {
    List<String> names = ["Alice", "Bob", "Charlie", "Diana"];
    List<double> nameWeights = [0.5, 0.3, 0.15, 0.05];

    List<String> surnames = ["Smith", "Johnson", "Williams", "Brown"];
    List<double> surnameWeights = [0.4, 0.35, 0.2, 0.05];

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