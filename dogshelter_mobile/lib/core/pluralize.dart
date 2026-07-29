/// Bosnian plural form for [count], e.g. `pluralize(2, one: 'volonter',
/// few: 'volontera', many: 'volontera')` -> "2 volontera".
String pluralize(int count, {required String one, required String few, required String many}) {
  final lastDigit = count % 10;
  final lastTwoDigits = count % 100;

  final String word;
  if (lastDigit == 1 && lastTwoDigits != 11) {
    word = one;
  } else if (lastDigit >= 2 && lastDigit <= 4 && !(lastTwoDigits >= 12 && lastTwoDigits <= 14)) {
    word = few;
  } else {
    word = many;
  }
  return '$count $word';
}
