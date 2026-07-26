/// Formats a DateTime as dd.MM.yyyy - the Bosnian date convention used across this app's UI.
/// Hand-rolled rather than pulling in `intl`, matching this project's preference for small
/// dependency-free helpers (see resolveImageUrl, normalizeForSearch).
String formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

/// Formats a DateTime as dd.MM.yyyy HH:mm - used for entities carrying a specific time slot
/// (e.g. Posjeta), not just a date, unlike formatDate above.
String formatDateTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${formatDate(date)} $hour:$minute';
}
