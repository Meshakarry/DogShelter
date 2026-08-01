import 'package:flutter/material.dart';

import 'package:dogshelter_shared/widgets/labeled_field.dart';

/// Required-reason dialog used for any state-transition action that needs an explanation
/// (Zahtjev odbij, Posjeta otkazi) - returns the trimmed reason, or null if cancelled.
class RazlogDialog extends StatefulWidget {
  const RazlogDialog({super.key, required this.title, required this.label});

  final String title;
  final String label;

  @override
  State<RazlogDialog> createState() => _RazlogDialogState();
}

class _RazlogDialogState extends State<RazlogDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = '${widget.label} je obavezan.');
      return;
    }
    if (value.length > 1000) {
      setState(() => _error = '${widget.label} može imati najviše 1000 znakova.');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: LabeledField(
          label: widget.label,
          errorText: _error,
          child: TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Odustani')),
        FilledButton(onPressed: _submit, child: const Text('Potvrdi')),
      ],
    );
  }
}
