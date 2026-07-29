import 'package:flutter/material.dart';

const _pawGreen = Color(0xFF008554);

/// "🐾 DogShelter" - shared app title used on the auth screens (plain, non-interactive there)
/// and the main app bar (where [onTap] is wired to jump back to Početna).
class AppTitle extends StatelessWidget {
  const AppTitle({super.key, this.style, this.onTap});

  final TextStyle? style;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.pets, color: _pawGreen),
        const SizedBox(width: 8),
        Text('DogShelter', style: style),
      ],
    );
    if (onTap == null) return content;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: content);
  }
}
