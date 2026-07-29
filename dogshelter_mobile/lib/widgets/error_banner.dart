import 'package:flutter/material.dart';

import '../core/api_exception.dart';

/// Forwards the backend's actual validation/error messages verbatim, never a generic
/// "something went wrong".
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox.shrink();

    final messages = error is ApiException ? (error as ApiException).allMessages : [error.toString()];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: messages
            .map((m) => Text(m, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)))
            .toList(),
      ),
    );
  }
}
