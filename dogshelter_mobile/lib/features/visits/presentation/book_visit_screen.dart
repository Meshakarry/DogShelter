import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/widgets/error_banner.dart';
import 'package:dogshelter_shared/widgets/form_error_scroller.dart';
import 'package:dogshelter_shared/widgets/inline_calendar.dart';
import 'package:dogshelter_shared/widgets/labeled_field.dart';
import 'package:dogshelter_shared/widgets/time_slot_chip.dart';
import '../application/visits_providers.dart';

/// Route-navigation arguments for `/posjete/nova` - carries the dog context (if any) through
/// `GoRouterState.extra` since a plain int/String pair isn't a type go_router can cast reliably.
class BookVisitArgs {
  const BookVisitArgs({this.pasId, this.pasNaziv});

  final int? pasId;
  final String? pasNaziv;
}
///
/// When [pasId] is given (triggered from a dog's detail page) the dog is fixed and shown as
/// read-only text. When null (triggered from the Moje posjete list's "+" button) a dropdown lets
/// the user optionally pick a dog, or leave it unset for a general shelter visit - the backend's
/// PasId is nullable specifically to support that case.
class BookVisitScreen extends ConsumerStatefulWidget {
  const BookVisitScreen({super.key, this.pasId, this.pasNaziv});

  final int? pasId;
  final String? pasNaziv;

  @override
  ConsumerState<BookVisitScreen> createState() => _BookVisitScreenState();
}

class _BookVisitScreenState extends ConsumerState<BookVisitScreen> with FormErrorScroller<BookVisitScreen> {
  final _napomenaController = TextEditingController();
  final _scrollController = ScrollController();
  late final DateTime _firstDate;
  late final DateTime _lastDate;
  int? _selectedPasId;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  bool _isSubmitting = false;
  Object? _apiError;

  @override
  List<String> get fieldOrder => const ['datum', 'vrijeme'];

  @override
  ScrollController get errorScrollController => _scrollController;

  @override
  void initState() {
    super.initState();
    _selectedPasId = widget.pasId;
    _firstDate = firstBookableVisitDate();
    _lastDate = _firstDate.add(const Duration(days: 365));
  }

  @override
  void dispose() {
    _napomenaController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _clearApiError() {
    if (_apiError != null) setState(() => _apiError = null);
  }

  List<String> get _availableTimeSlots => availableTimeSlots(_selectedDate);

  DateTime? get _datumVrijeme {
    final date = _selectedDate;
    final slot = _selectedTimeSlot;
    if (date == null || slot == null) return null;
    final parts = slot.split(':');
    return DateTime(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  Future<void> _submit() async {
    final errors = <String, String>{};
    if (_selectedDate == null) errors['datum'] = 'Odaberite datum posjete.';
    if (_selectedTimeSlot == null) errors['vrijeme'] = 'Odaberite vrijeme posjete.';
    if (errors.isNotEmpty) {
      applyValidationErrors(errors);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _apiError = null;
      clearAllFieldErrors();
    });
    try {
      await ref.read(visitsApiProvider).createPosjeta(
            datumVrijeme: _datumVrijeme!,
            pasId: _selectedPasId,
            napomena: _napomenaController.text.trim(),
          );
      if (mounted) context.pop(true);
    } catch (e) {
      setState(() => _apiError = e);
      scrollToTop();
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

    return Scaffold(
      appBar: AppBar(title: const Text('Zakaži posjetu')),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.pasId != null
                  ? 'Zakazujete posjetu psu ${widget.pasNaziv ?? ''}.'
                  : 'Odaberite termin za posjetu azilu, po želji i konkretnog psa.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ErrorBanner(error: _apiError),
            if (widget.pasId == null) ...[
              LabeledField(
                label: 'Pas (opcionalno)',
                required: false,
                child: dogPickerAsync!.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => ErrorBanner(error: e),
                  data: (dogs) => DropdownButtonFormField<int>(
                    initialValue: _selectedPasId,
                    decoration: const InputDecoration(hintText: 'Odaberite psa ili ostavite praznim', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Opća posjeta (bez odabira psa)')),
                      for (final dog in dogs) DropdownMenuItem(value: dog.pasId, child: Text(dog.naziv)),
                    ],
                    onChanged: (value) {
                      _clearApiError();
                      setState(() => _selectedPasId = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            LabeledField(
              key: keyFor('datum'),
              label: 'Odaberite datum',
              errorText: fieldErrors['datum'],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: fieldErrors['datum'] != null ? Theme.of(context).colorScheme.error : const Color(0xFFE5E7EB)),
                ),
                child: InlineCalendar(
                  firstDate: _firstDate,
                  lastDate: _lastDate,
                  selectedDate: _selectedDate,
                  onDateSelected: (date) {
                    _clearApiError();
                    clearFieldError('datum');
                    setState(() {
                      _selectedDate = date;
                      _selectedTimeSlot = null;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            LabeledField(
              key: keyFor('vrijeme'),
              label: 'Odaberite vrijeme',
              errorText: fieldErrors['vrijeme'],
              child: _selectedDate == null
                  ? Text(
                      'Prvo odaberite datum.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
                    )
                  : timeSlots.isEmpty
                      ? Text(
                          'Nema više dostupnih termina za odabrani dan.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final slot in timeSlots)
                              TimeSlotChip(
                                label: slot,
                                selected: slot == _selectedTimeSlot,
                                taken: zauzetiTimes.contains(slot),
                                onTap: () {
                                  _clearApiError();
                                  clearFieldError('vrijeme');
                                  setState(() => _selectedTimeSlot = slot);
                                },
                              ),
                          ],
                        ),
            ),
            const SizedBox(height: 20),
            LabeledField(
              label: 'Napomena (opcionalno)',
              required: false,
              child: TextField(
                controller: _napomenaController,
                onChanged: (_) => _clearApiError(),
                maxLines: 3,
                maxLength: 1000,
                decoration: const InputDecoration(
                  hintText: 'Dodatne informacije za osoblje azila',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Zakaži'),
            ),
          ],
        ),
      ),
    );
  }
}
