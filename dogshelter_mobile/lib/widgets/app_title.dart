import 'package:flutter/material.dart';

const _pawGreen = Color(0xFF008554);

/// "🐾 DogShelter" - shared app title used on the login screen and the main app bar.
class AppTitle extends StatelessWidget {
  const AppTitle({super.key, this.style});

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.pets, color: _pawGreen),
        const SizedBox(width: 8),
        Text('DogShelter', style: style),
      ],
    );
  }
}
