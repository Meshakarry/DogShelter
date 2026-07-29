import 'package:flutter/material.dart';

import '../domain/jedinica_mjere.dart';
import 'chip_button.dart';

/// Shows the unit for a Materijalna donation using the least UI the category actually needs:
/// - exactly one allowed unit -> a static label, no decision for the user to make at all
/// - a few allowed units -> tappable chips (fast, no dropdown ceremony)
/// - unrestricted (empty `allowedUnits`, e.g. "Ostalo") -> the full dropdown, since any unit
///   could be valid for an unknown item
class UnitPicker extends StatelessWidget {
  const UnitPicker({
    super.key,
    required this.allUnits,
    required this.allowedUnits,
    required this.selectedId,
    required this.onChanged,
    this.errorText,
  });

  final List<JedinicaMjere> allUnits;
  final List<JedinicaMjere> allowedUnits;
  final int? selectedId;
  final ValueChanged<int?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    if (allowedUnits.length == 1) {
      final naziv = allowedUnits.single.naziv;
      return Text(
        'Mjereno u jedinici: $naziv',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280)),
      );
    }

    if (allowedUnits.isEmpty) {
      return DropdownButtonFormField<int>(
        initialValue: selectedId,
        decoration: InputDecoration(
          hintText: 'Odaberite jedinicu',
          border: const OutlineInputBorder(),
          errorText: errorText,
          errorStyle: const TextStyle(height: 0, fontSize: 0),
        ),
        items: [for (final j in allUnits) DropdownMenuItem(value: j.jedinicaMjereId, child: Text(j.naziv))],
        onChanged: onChanged,
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final j in allowedUnits)
          ChipButton(label: j.naziv, selected: j.jedinicaMjereId == selectedId, onTap: () => onChanged(j.jedinicaMjereId)),
      ],
    );
  }
}
