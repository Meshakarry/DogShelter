import 'package:flutter/material.dart';

import 'package:dogshelter_shared/widgets/labeled_field.dart';

/// Required-reason dialog used for cancelling a request/visit - returns the trimmed reason,
/// or null if cancelled. [title] is used both as the dialog title and the confirm button label.
class CancelReasonDialog extends StatefulWidget {
  const CancelReasonDialog({super.key, required this.title});

  final String title;

  @override
  State<CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<CancelReasonDialog> {
  final _reasonController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _confirm() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = 'Razlog otkazivanja je obavezan.');
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: LabeledField(
            label: 'Razlog otkazivanja',
            child: TextField(
              controller: _reasonController,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              maxLines: 3,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: 'Unesite razlog otkazivanja',
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Odustani')),
        FilledButton(onPressed: _confirm, child: Text(widget.title)),
      ],
    );
  }
}
