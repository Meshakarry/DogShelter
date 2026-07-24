import 'package:flutter/material.dart';

/// Stub for tabs whose feature increment hasn't landed yet.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('$title - uskoro dostupno', style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
