import 'dart:math';

class DateGenerator {
  static DateTime getRandomDateTime() {
    final random = Random();
    int year = 1950 + random.nextInt(2006 - 1950 + 1);
    int month = random.nextInt(12) + 1;
    int day = random.nextInt(DateTime(year, month + 1, 0).day) + 1;

    return DateTime(year, month, day);
  }
}
