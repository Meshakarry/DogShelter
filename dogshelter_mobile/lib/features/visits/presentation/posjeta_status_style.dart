import 'package:flutter/material.dart';

const _pendingAmber = Color(0xFFD97706);
const _confirmedGreen = Color(0xFF008554);
const _cancelledRed = Color(0xFFDC2626);
const _completedBlue = Color(0xFF2563EB);
const _neutralGray = Color(0xFF6B7280);

/// Status color - amber while pending, green once confirmed, red once cancelled,
/// blue once completed.
Color posjetaStatusColor(String? statusNaziv) {
  switch (statusNaziv?.toLowerCase()) {
    case 'na čekanju':
      return _pendingAmber;
    case 'potvrđena':
      return _confirmedGreen;
    case 'otkazana':
      return _cancelledRed;
    case 'završena':
      return _completedBlue;
    default:
      return _neutralGray;
  }
}

class PosjetaStatusBadge extends StatelessWidget {
  const PosjetaStatusBadge({super.key, required this.naziv});

  final String? naziv;

  @override
  Widget build(BuildContext context) {
    final color = posjetaStatusColor(naziv);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        naziv ?? '-',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color),
      ),
    );
  }
}
