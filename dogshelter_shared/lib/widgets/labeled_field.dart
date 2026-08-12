import 'package:flutter/material.dart';

import 'required_label.dart';

/// Pass this widget's [key] as the [GlobalKey] from [FormErrorScroller.keyFor] to make the whole
/// label+control+error block (not just the control) the scroll target on a failed submit.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    this.required = true,
    required this.child,
    this.errorText,
  });

  final String label;
  final bool required;
  final Widget child;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        required ? RequiredLabel(label) : Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        hasError
            ? DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.error, width: 1.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: child,
              )
            : child,
        FieldError(errorText),
      ],
    );
  }
}
