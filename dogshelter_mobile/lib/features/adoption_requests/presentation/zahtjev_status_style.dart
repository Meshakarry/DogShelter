import 'package:flutter/material.dart';

const _pendingAmber = Color(0xFFD97706);
const _approvedGreen = Color(0xFF008554);
const _rejectedRed = Color(0xFFDC2626);
const _neutralGray = Color(0xFF6B7280);

/// Status color - amber while pending, green once approved, red once rejected.
Color zahtjevStatusColor(String? statusNaziv) {
  switch (statusNaziv?.toLowerCase()) {
    case 'na čekanju':
      return _pendingAmber;
    case 'odobren':
      return _approvedGreen;
    case 'odbijen':
    case 'otkazan':
      return _rejectedRed;
    default:
      return _neutralGray;
  }
}

class ZahtjevStatusBadge extends StatelessWidget {
  const ZahtjevStatusBadge({super.key, required this.naziv});

  final String? naziv;

  @override
  Widget build(BuildContext context) {
    final color = zahtjevStatusColor(naziv);
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
