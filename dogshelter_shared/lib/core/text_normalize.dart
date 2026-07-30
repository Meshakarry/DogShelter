const _diacriticMap = {
  'č': 'c', 'ć': 'c', 'š': 's', 'ž': 'z', 'đ': 'd',
};

/// Lowercases and strips Bosnian diacritics (č/ć→c, š→s, ž→z, đ→d) so search matching doesn't
/// depend on the user typing special characters, e.g. "Njemacki" still matches "Njemački".
String normalizeForSearch(String input) {
  final buffer = StringBuffer();
  for (final ch in input.toLowerCase().split('')) {
    buffer.write(_diacriticMap[ch] ?? ch);
  }
  return buffer.toString();
}
