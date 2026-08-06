import 'package:flutter/material.dart';

import 'package:dogshelter_shared/core/date_format.dart';

/// A date picker that reads like a normal text input (matching the surrounding form fields)
/// instead of a standalone button, with a trailing calendar icon as the visual affordance.
class DateInputField extends StatelessWidget {
  const DateInputField({super.key, required this.value, required this.hintText, required this.onTap, this.onClear});

  final DateTime? value;
  final String hintText;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: onClear != null
              ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: onClear)
              : const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          value == null ? hintText : formatDate(value!),
          style: value == null ? TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant) : null,
        ),
      ),
    );
  }
}
