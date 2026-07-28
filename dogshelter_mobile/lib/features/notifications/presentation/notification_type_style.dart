import 'package:flutter/material.dart';

const _successGreen = Color(0xFF008554);
const _dangerRed = Color(0xFFDC2626);
const _infoBlue = Color(0xFF2563EB);
const _warningAmber = Color(0xFFD97706);
const _neutralGray = Color(0xFF6B7280);

/// Icon + color per `Notifikacija.Tip` (mirrors backend's `NotifikacijaTipovi` constants) - purely
/// a mobile presentation concern, the string itself is never parsed for anything else.
(IconData, Color) notificationTypeStyle(String tip) {
  switch (tip) {
    case 'ZahtjevOdobren':
    case 'PosjetaPotvrdjena':
    case 'DonacijaPotvrdjena':
    case 'DonacijaUspjesna':
      return (Icons.check_circle, _successGreen);
    case 'ZahtjevOdbijen':
    case 'PosjetaOtkazana':
    case 'DonacijaOdbijena':
    case 'DonacijaNeuspjesna':
      return (Icons.cancel, _dangerRed);
    case 'DonacijaVracena':
      return (Icons.replay, _warningAmber);
    case 'PosjetaZavrsena':
      return (Icons.task_alt, _infoBlue);
    case 'DogadjajZaduzenje':
      return (Icons.event, _infoBlue);
    default:
      return (Icons.notifications, _neutralGray);
  }
}
