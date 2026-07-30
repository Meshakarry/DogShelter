import 'package:flutter/material.dart';

/// A form label with a red required-field asterisk. Used on every required field across the
/// app's forms so users can tell at a glance which fields must be filled in.
class RequiredLabel extends StatelessWidget {
  const RequiredLabel(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: style ?? Theme.of(context).textTheme.titleMedium),
        const SizedBox(width: 4),
        const Text('*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

/// Validation messages render clearly below their control, never inside the input or as a
/// dialog - this is that inline message, used under every field that can fail client-side
/// validation.
class FieldError extends StatelessWidget {
  const FieldError(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message;
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
      ),
    );
  }
}
