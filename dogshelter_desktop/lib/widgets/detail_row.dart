import 'package:flutter/material.dart';

/// A label/value row used across detail screens (label left, value right, bold).
class DetailRow extends StatelessWidget {
  const DetailRow({super.key, required this.label, required this.value, this.labelWidth = 150});

  final String label;
  final String value;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: labelWidth, child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
