import 'dart:async';

import 'package:flutter/material.dart';

/// A search text field that reports changes only after the user pauses typing
/// (debounced), instead of requiring Enter - also fires immediately when the
/// field is cleared so the underlying list resets to unfiltered right away.
class DebouncedSearchField extends StatefulWidget {
  const DebouncedSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Pretraga po nazivu...',
    this.debounce = const Duration(milliseconds: 400),
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final Duration debounce;

  @override
  State<DebouncedSearchField> createState() => _DebouncedSearchFieldState();
}

class _DebouncedSearchFieldState extends State<DebouncedSearchField> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleChanged(String value) {
    _timer?.cancel();
    if (value.isEmpty) {
      widget.onChanged(value);
      return;
    }
    _timer = Timer(widget.debounce, () => widget.onChanged(value));
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: widget.hintText,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: _handleChanged,
    );
  }
}
