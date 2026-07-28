import 'package:flutter/material.dart';

const _pendingAmber = Color(0xFFD97706);
const _successGreen = Color(0xFF008554);
const _failedRed = Color(0xFFDC2626);
const _refundedBlue = Color(0xFF2563EB);
const _neutralGray = Color(0xFF6B7280);

/// Status color - amber while pending, green once successful, red once failed, blue once refunded.
Color donacijaStatusColor(String? statusNaziv) {
  switch (statusNaziv?.toLowerCase()) {
    case 'na čekanju':
      return _pendingAmber;
    case 'uspješna':
      return _successGreen;
    case 'neuspješna':
      return _failedRed;
    case 'vraćena':
      return _refundedBlue;
    default:
      return _neutralGray;
  }
}

/// A colored badge for a donacija status - tinted background + bold text in the same status
/// color, same rectangular treatment as PosjetaStatusBadge/ZahtjevStatusBadge.
class DonacijaStatusBadge extends StatelessWidget {
  const DonacijaStatusBadge({super.key, required this.naziv});

  final String? naziv;

  @override
  Widget build(BuildContext context) {
    final color = donacijaStatusColor(naziv);
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
