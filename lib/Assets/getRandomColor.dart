import 'dart:math';
import 'dart:ui';

Color getRandomColor() {
  final Random random = Random();
  return Color.fromARGB(
    255,
    random.nextInt(256),
    random.nextInt(256),
    random.nextInt(256),
  );
}

Color getCategoryColor(String? category) {
  switch (category) {
    case 'Meetings':
      return const Color.fromARGB(255, 255, 165, 0);
    case 'Work':
      return const Color.fromARGB(255, 0, 128, 255);
    case 'Personal':
      return const Color.fromARGB(255, 128, 1, 203);
    case 'Other':
      return const Color.fromARGB(200, 1, 128, 128);
    default:
      return const Color.fromARGB(128, 230, 0, 0);
  }
}

