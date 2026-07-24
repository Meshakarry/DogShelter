/// Formats a DateTime as dd.MM.yyyy - the Bosnian date convention used across this app's UI.
/// Hand-rolled rather than pulling in `intl`, matching this project's preference for small
/// dependency-free helpers (see resolveImageUrl, normalizeForSearch).
String formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}
