import 'package:flutter/material.dart';

/// Shared squarer (chip-like) pill radius used for every status pill in this app -
/// distinct from StatusPill's own fully-round default, which is still used for
/// plain aktivan/neaktivan and role pills elsewhere.
const statusPillRadius = 6.0;

const _green = (background: Color(0xFFDFF3E6), foreground: Color(0xFF1E7D42));
const _red = (background: Color(0xFFFBE1E1), foreground: Color(0xFFB3261E));
const _amber = (background: Color(0xFFFDEBD0), foreground: Color(0xFFB4690E));
const _blueGray = (background: Color(0xFFE2E8F0), foreground: Color(0xFF334155));

({Color background, Color foreground}) zahtjevStatusColors(String naziv) {
  switch (naziv) {
    case 'Odobren':
      return _green;
    case 'Odbijen':
    case 'Otkazan':
      return _red;
    default:
      return _amber; // Na čekanju
  }
}

({Color background, Color foreground}) posjetaStatusColors(String naziv) {
  switch (naziv) {
    case 'Potvrđena':
      return _green;
    case 'Otkazana':
      return _red;
    case 'Završena':
      return _blueGray;
    default:
      return _amber; // Na čekanju
  }
}

({Color background, Color foreground}) donacijaStatusColors(String naziv) {
  switch (naziv) {
    case 'Uspješna':
      return _green;
    case 'Neuspješna':
      return _red;
    case 'Vraćena':
      return _blueGray;
    default:
      return _amber; // Na čekanju
  }
}

({Color background, Color foreground}) obavijestStatusColors(bool aktivna) => aktivna ? _green : _amber;
