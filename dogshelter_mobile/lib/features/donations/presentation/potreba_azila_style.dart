import 'package:flutter/material.dart';

const _hitnoRed = Color(0xFFDC2626);
const _uskoroAmber = Color(0xFFD97706);
const _naStanjuGreen = Color(0xFF008554);
const _neutralGray = Color(0xFF6B7280);

/// Priority color - red (Hitno/Urgent), amber (Potrebno uskoro/Needed Soon),
/// green (Na stanju/In Stock).
Color prioritetPotrebeColor(String? naziv) {
  switch (naziv?.toLowerCase()) {
    case 'hitno':
      return _hitnoRed;
    case 'potrebno uskoro':
      return _uskoroAmber;
    case 'na stanju':
      return _naStanjuGreen;
    default:
      return _neutralGray;
  }
}

/// A colored priority badge for the shelter-needs board - tinted background + bold text in the
/// priority color.
class PrioritetBadge extends StatelessWidget {
  const PrioritetBadge({super.key, required this.naziv});

  final String? naziv;

  @override
  Widget build(BuildContext context) {
    final color = prioritetPotrebeColor(naziv);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        naziv ?? '-',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: color),
      ),
    );
  }
}
