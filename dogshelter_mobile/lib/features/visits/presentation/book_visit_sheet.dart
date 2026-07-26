import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/error_banner.dart';
import '../application/visits_providers.dart';
import 'inline_calendar.dart';

// Assumed shelter visiting hours (09:00-16:00, hourly) - not modeled anywhere on the backend
// (Posjeta has no time-of-day restriction, only a future-date + exact-slot-overlap check), so
// this is a mobile-only UX choice. Adjust here if the shelter's actual visiting hours differ.
const _timeSlots = ['09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00'];

/// Bottom sheet for booking a real POST /api/Posjeta - pops `true` on success so the caller can
/// navigate/snackbar, same contract as adoption_requests' _SubmitRequestSheet.
///
/// When [pasId] is given (triggered from a dog's detail page) the dog is fixed and shown as
/// read-only text. When null (triggered from the Moje posjete list's "+" button) a dropdown lets
/// the user optionally pick a dog, or leave it unset for a general shelter visit - the backend's
/// PasId is nullable specifically to support that case.
class BookVisitSheet extends ConsumerStatefulWidget {
  const BookVisitSheet({super.key, this.pasId, this.pasNaziv});

  final int? pasId;
  final String? pasNaziv;

  @override
  ConsumerState<BookVisitSheet> createState() => _BookVisitSheetState();
}

class _BookVisitSheetState extends ConsumerState<BookVisitSheet> {
  final _napomenaController = TextEditingController();
  late final DateTime _firstDate;
  late final DateTime _lastDate;
  int? _selectedPasId;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  bool _isSubmitting = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _selectedPasId = widget.pasId;
    final now = DateTime.now();
    _firstDate = DateTime(now.year, now.month, now.day);
    _lastDate = _firstDate.add(const Duration(days: 365));
  }

  @override
  void dispose() {
    _napomenaController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  List<String> get _availableTimeSlots {
    final date = _selectedDate;
    if (date == null) return _timeSlots;
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    if (!isToday) return _timeSlots;
    return _timeSlots.where((slot) {
      final parts = slot.split(':');
      final slotTime = DateTime(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]));
      return slotTime.isAfter(now);
    }).toList();
  }

  DateTime? get _datumVrijeme {
    final date = _selectedDate;
    final slot = _selectedTimeSlot;
    if (date == null || slot == null) return null;
    final parts = slot.split(':');
    return DateTime(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  Future<void> _submit() async {
    if (_selectedDate == null) {
      setState(() => _error = 'Odaberite datum posjete.');
      return;
    }
    if (_selectedTimeSlot == null) {
      setState(() => _error = 'Odaberite vrijeme posjete.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await ref.read(visitsApiProvider).createPosjeta(
            datumVrijeme: _datumVrijeme!,
            pasId: _selectedPasId,
            napomena: _napomenaController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dogPickerAsync = widget.pasId == null ? ref.watch(dogPickerOptionsProvider) : null;
    final timeSlots = _availableTimeSlots;
    final zauzetiAsync = _selectedDate == null ? null : ref.watch(zauzetiTerminiProvider(_selectedDate!));
    final zauzetiTimes = (zauzetiAsync?.valueOrNull ?? const <DateTime>[])
        .map((dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}')
        .toSet();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Zakaži posjetu',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.pasId != null
                  ? 'Zakazujete posjetu psu ${widget.pasNaziv ?? ''}.'
                  : 'Odaberite termin za posjetu azilu, po želji i konkretnog psa.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ErrorBanner(error: _error),
            if (widget.pasId == null) ...[
              dogPickerAsync!.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => ErrorBanner(error: e),
                data: (dogs) => DropdownButtonFormField<int>(
                  initialValue: _selectedPasId,
                  decoration: const InputDecoration(labelText: 'Pas (opcionalno)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Opća posjeta (bez odabira psa)')),
                    for (final dog in dogs) DropdownMenuItem(value: dog.pasId, child: Text(dog.naziv)),
                  ],
                  onChanged: (value) {
                    _clearError();
                    setState(() => _selectedPasId = value);
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
            Text('Odaberite datum', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: InlineCalendar(
                firstDate: _firstDate,
                lastDate: _lastDate,
                selectedDate: _selectedDate,
                onDateSelected: (date) {
                  _clearError();
                  setState(() {
                    _selectedDate = date;
                    _selectedTimeSlot = null;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            Text('Odaberite vrijeme', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_selectedDate == null)
              Text(
                'Prvo odaberite datum.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
              )
            else if (timeSlots.isEmpty)
              Text(
                'Nema više dostupnih termina za odabrani dan.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final slot in timeSlots)
                    _TimeSlotChip(
                      label: slot,
                      selected: slot == _selectedTimeSlot,
                      taken: zauzetiTimes.contains(slot),
                      onTap: () {
                        _clearError();
                        setState(() => _selectedTimeSlot = slot);
                      },
                    ),
                ],
              ),
            const SizedBox(height: 20),
            TextField(
              controller: _napomenaController,
              onChanged: (_) => _clearError(),
              maxLines: 3,
              maxLength: 1000,
              decoration: const InputDecoration(labelText: 'Napomena (opcionalno)', alignLabelWithHint: true),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                    child: const Text('Otkaži'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Zakaži'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeSlotChip extends StatelessWidget {
  const _TimeSlotChip({required this.label, required this.selected, required this.taken, required this.onTap});

  final String label;
  final bool selected;
  final bool taken;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: taken ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF008554) : (taken ? const Color(0xFFF3F4F6) : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF008554) : const Color(0xFFD1D5DB),
          ),
        ),
        child: Text(
          taken ? '$label (zauzeto)' : label,
          style: TextStyle(
            color: selected ? Colors.white : (taken ? const Color(0xFFBDBDBD) : Colors.black87),
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            decoration: taken ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }
}
