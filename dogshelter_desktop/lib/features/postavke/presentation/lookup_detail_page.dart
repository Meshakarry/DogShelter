import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Adds a back button + page title above [child] - the sub-pages under /postavke
/// aren't sidebar destinations themselves, so AppShell's top bar just shows "Postavke".
class LookupDetailPage extends StatelessWidget {
  const LookupDetailPage({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 24, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Nazad',
                onPressed: () => context.go('/postavke'),
              ),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
