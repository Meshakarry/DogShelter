import 'package:flutter/material.dart';

/// Mobile-friendly quantity input: +/- buttons around the value, which can also be tapped
/// directly to type a larger number - a bare numeric TextField alone is slower to use for the
/// common case (1-10 items) and a stepper alone is tedious for large quantities.
class QuantityStepper extends StatefulWidget {
  const QuantityStepper({super.key, required this.value, required this.onChanged, this.step = 1, this.min = 0});

  final double? value;
  final ValueChanged<double?> onChanged;
  final double step;
  final double min;

  @override
  State<QuantityStepper> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<QuantityStepper> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
  }

  @override
  void didUpdateWidget(covariant QuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only sync from outside while the field isn't being typed into, so a step-button tap (or a
    // category switch that resets the value) updates the text without fighting the user's typing.
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _controller.text = _format(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _format(double? value) {
    if (value == null) return '';
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
  }

  void _step(double delta) {
    final next = ((widget.value ?? 0) + delta).clamp(widget.min, double.infinity);
    _controller.text = _format(next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD1D5DB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _StepButton(icon: Icons.remove, onTap: () => _step(-widget.step)),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: Theme.of(context).textTheme.titleMedium,
              decoration: const InputDecoration(border: InputBorder.none, isDense: true),
              onChanged: (text) => widget.onChanged(double.tryParse(text.replaceAll(',', '.'))),
            ),
          ),
          _StepButton(icon: Icons.add, onTap: () => _step(widget.step)),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Icon(icon, color: const Color(0xFF008554)),
      ),
    );
  }
}
