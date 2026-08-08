import 'package:flutter/material.dart';

/// A label/value row used across detail screens (label left, value right, bold), with an
/// optional leading icon.
class DetailRow extends StatelessWidget {
  const DetailRow({super.key, this.icon, required this.label, required this.value, this.labelWidth = 150});

  final IconData? icon;
  final String label;
  final String value;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: const Color(0xFF6B7280)),
            const SizedBox(width: 8),
          ],
          SizedBox(width: labelWidth, child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
