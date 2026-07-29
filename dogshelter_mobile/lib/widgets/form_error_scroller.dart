import 'package:flutter/material.dart';

/// Shared submit-time validation plumbing for the app's longer forms: a per-field error map
/// keyed by field name (rendered via [FieldError] below each control, never live while typing),
/// plus scroll-to-first-invalid-field so a failed submit doesn't leave the user stranded above
/// an error near the bottom of a long, scrollable form.
///
/// [fieldOrder] must list every validatable field name, top-to-bottom, so the mixin knows which
/// one to scroll to first when several fail at once.
mixin FormErrorScroller<T extends StatefulWidget> on State<T> {
  List<String> get fieldOrder;
  ScrollController get errorScrollController;

  final Map<String, String> fieldErrors = {};
  late final Map<String, GlobalKey> _fieldKeys = {for (final key in fieldOrder) key: GlobalKey()};

  GlobalKey keyFor(String field) => _fieldKeys[field]!;

  void clearFieldError(String field) {
    if (fieldErrors.containsKey(field)) setState(() => fieldErrors.remove(field));
  }

  void clearFieldErrors(Iterable<String> fields) {
    if (fields.any(fieldErrors.containsKey)) {
      setState(() => fields.forEach(fieldErrors.remove));
    }
  }

  /// Sets [errors] as the current field errors and scrolls to whichever offending field appears
  /// first in [fieldOrder].
  void applyValidationErrors(Map<String, String> errors) {
    setState(() {
      fieldErrors
        ..clear()
        ..addAll(errors);
    });
    final firstInvalidField = fieldOrder.firstWhere(errors.containsKey, orElse: () => '');
    final fieldContext = _fieldKeys[firstInvalidField]?.currentContext;
    if (fieldContext != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Scrollable.ensureVisible(fieldContext, duration: const Duration(milliseconds: 300), curve: Curves.easeOut, alignment: 0.2);
      });
    }
  }

  void clearAllFieldErrors() {
    if (fieldErrors.isNotEmpty) setState(fieldErrors.clear);
  }

  /// Scrolls the form back to the top - used for a top-level (non-field) error such as an API
  /// failure, which unlike field errors isn't tied to one control.
  void scrollToTop() {
    errorScrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }
}
