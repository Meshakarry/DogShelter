import 'package:flutter/material.dart';

const _availableGreen = Color(0xFF008554);

/// Text-only status styling (no pill background) - green for "Dostupan", neutral otherwise.
Color dogStatusColor(String? statusNaziv) {
  if (statusNaziv?.toLowerCase() == 'dostupan') return _availableGreen;
  return const Color(0xFF6B7280);
}
