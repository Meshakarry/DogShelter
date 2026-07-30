import 'package:flutter/material.dart';

/// Temporary body for a sidebar destination whose real screen hasn't been built yet.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.construction_outlined, size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('Ovaj ekran je u izradi.', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
