/// Formats a DateTime as dd.MM.yyyy (Bosnian date convention). Hand-rolled to avoid pulling in
/// intl for a single format.
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
