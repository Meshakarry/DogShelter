import 'package:flutter/material.dart';

import 'required_label.dart';

/// Renders a field's label as a standalone caption above the control, with the control's own
/// hint text (placeholder) shown inside it - unlike Material's built-in `InputDecoration.label`,
/// which overlaps the label and hint in the same slot until the field is focused, making an
/// empty unfocused field unreadable as "label + placeholder" at a glance.
///
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        required ? RequiredLabel(label) : Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        child,
        FieldError(errorText),
      ],
    );
  }
}
