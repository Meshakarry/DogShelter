import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/auth/domain/korisnik.dart';
import 'package:dogshelter_shared/core/api_exception.dart';
import 'package:dogshelter_shared/core/date_format.dart';
import 'package:dogshelter_shared/core/image_url.dart';
import 'package:dogshelter_shared/pas/domain/pas_list_item.dart';
import 'package:dogshelter_shared/posjeta/domain/posjeta.dart';
import 'package:dogshelter_shared/widgets/inline_calendar.dart';
import 'package:dogshelter_shared/widgets/labeled_field.dart';
import 'package:dogshelter_shared/widgets/status_pill.dart';
import 'package:dogshelter_shared/widgets/time_slot_chip.dart';
import '../../../core/app_theme.dart';
import '../../../environment.dart';
import '../../../widgets/page_footer.dart';
import '../../../widgets/razlog_dialog.dart';
import '../../../widgets/status_colors.dart';
import '../application/posjete_providers.dart';

const _naCekanju = 'Na čekanju';
const _potvrdjena = 'Potvrđena';
const _zavrsena = 'Završena';
const _otkazana = 'Otkazana';


class PosjeteScreen extends ConsumerStatefulWidget {
  const PosjeteScreen({super.key});

  @override
  ConsumerState<PosjeteScreen> createState() => _PosjeteScreenState();
}

class _PosjeteScreenState extends ConsumerState<PosjeteScreen> {
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Theme.of(context).colorScheme.error : null),
    );
  }

  Future<void> _potvrdi(Posjeta posjeta) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrdi posjetu'),
        content: const Text('Da li želite potvrditi ovu posjetu?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Potvrdi')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(posjetaListProvider.notifier).potvrdi(posjeta.posjetaId);
      if (mounted) _showMessage('Posjeta je potvrđena.');
    } catch (e) {
      if (mounted) _showMessage(describeApiError(e), isError: true);
    }
  }

  Future<void> _zavrsi(Posjeta posjeta) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Označi kao završenu'),
        content: const Text('Da li želite označiti ovu posjetu kao završenu?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Završi')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(posjetaListProvider.notifier).zavrsi(posjeta.posjetaId);
      if (mounted) _showMessage('Posjeta je označena kao završena.');
    } catch (e) {
      if (mounted) _showMessage(describeApiError(e), isError: true);
    }
  }

  Future<void> _otkazi(Posjeta posjeta) async {
    final razlog = await showDialog<String>(
      context: context,
      builder: (context) => const RazlogDialog(title: 'Otkaži posjetu', label: 'Razlog otkazivanja'),
    );
    if (razlog == null || !mounted) return;

    try {
      await ref.read(posjetaListProvider.notifier).otkazi(posjeta.posjetaId, razlog);
      if (mounted) _showMessage('Posjeta je otkazana.');
    } catch (e) {
      if (mounted) _showMessage(describeApiError(e), isError: true);
    }
  }

  void _showDetail(Posjeta posjeta) {
    context.go('/posjete/${posjeta.posjetaId}');
  }

  Future<void> _openBookingDialog() async {
    final results = await Future.wait([
      ref.read(posjetaKorisnikOptionsProvider.future),
      ref.read(posjetaDogOptionsProvider.future),
    ]);
    if (!mounted) return;
    final korisnikOptions = results[0] as List<Korisnik>;
    final dogOptions = results[1] as List<PasListItem>;

    final booked = await showDialog<bool>(
      context: context,
      builder: (context) => _BookingDialog(korisnikOptions: korisnikOptions, dogOptions: dogOptions),
    );
    if (booked != true || !mounted) return;
    _showMessage('Posjeta je zakazana.');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(posjetaListProvider);
    final statusOptionsAsync = ref.watch(statusPosjeteOptionsProvider);
    final notifier = ref.read(posjetaListProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: AppTheme.toolbarActionHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 200,
                  child: statusOptionsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => const SizedBox.shrink(),
                    data: (options) => DropdownButtonFormField<int?>(
                      initialValue: state.filters.statusPosjeteId,
                      decoration:
                          const InputDecoration(border: OutlineInputBorder(), isDense: true, hintText: 'Status'),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Svi')),
                        for (final status in options) DropdownMenuItem<int?>(value: status.id, child: Text(status.naziv)),
                      ],
                      onChanged: (value) => notifier.applyFilters(
                        state.filters.copyWith(statusPosjeteId: value, clearStatusPosjeteId: value == null),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateInputField(
                    value: state.filters.datumOd,
                    hintText: 'Datum od',
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: state.filters.datumOd ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        notifier.applyFilters(state.filters.copyWith(datumOd: picked));
                      }
                    },
                    onClear: state.filters.datumOd == null
                        ? null
                        : () => notifier.applyFilters(state.filters.copyWith(clearDatumOd: true)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateInputField(
                    value: state.filters.datumDo,
                    hintText: 'Datum do',
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: state.filters.datumDo ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        notifier.applyFilters(state.filters.copyWith(datumDo: picked));
                      }
                    },
                    onClear: state.filters.datumDo == null
                        ? null
                        : () => notifier.applyFilters(state.filters.copyWith(clearDatumDo: true)),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  style: AppTheme.toolbarActionButtonStyle,
                  onPressed: _openBookingDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Nova posjeta'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: state.isLoading && state.items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.error != null && state.items.isEmpty
                    ? Center(child: Text(describeApiError(state.error!)))
                    : state.items.isEmpty
                        ? const Center(child: Text('Nema posjeta koje odgovaraju filterima.'))
                        : Card(
                            margin: EdgeInsets.zero,
                            child: ListView.separated(
                              itemCount: state.items.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final posjeta = state.items[index];
                                final imageUrl = resolveImageUrl(posjeta.pasSlikaNaslovna, Environment.apiBaseUrl);
                                final colors = posjetaStatusColors(posjeta.statusPosjeteNaziv ?? '');
                                final naziv = posjeta.statusPosjeteNaziv;
                                return ListTile(
                                  onTap: () => _showDetail(posjeta),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: imageUrl == null
                                          ? Container(
                                              color: Theme.of(context).colorScheme.secondaryContainer,
                                              child: Icon(posjeta.pasId == null ? Icons.event_outlined : Icons.pets),
                                            )
                                          : Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                color: Theme.of(context).colorScheme.secondaryContainer,
                                                child: const Icon(Icons.pets),
                                              ),
                                            ),
                                    ),
                                  ),
                                  title: Text('${posjeta.korisnikIme} ${posjeta.korisnikPrezime}'),
                                  subtitle: Text(
                                    '${formatDateTime(posjeta.datumVrijeme)} · ${posjeta.pasNaziv ?? 'Opća posjeta'}',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      StatusPill(
                                        label: naziv ?? '-',
                                        color: colors.background,
                                        foregroundColor: colors.foreground,
                                        borderRadius: statusPillRadius,
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: Icon(
                                          naziv == _potvrdjena ? Icons.flag_circle_outlined : Icons.check_circle_outline,
                                          color: (naziv == _naCekanju || naziv == _potvrdjena)
                                              ? posjetaStatusColors(naziv == _potvrdjena ? _zavrsena : _potvrdjena)
                                                  .foreground
                                              : null,
                                        ),
                                        tooltip: switch (naziv) {
                                          _naCekanju => 'Potvrdi',
                                          _potvrdjena => 'Označi kao završenu',
                                          _ => 'Posjeta je već obrađena (status: $naziv) i ne može se dalje mijenjati.',
                                        },
                                        onPressed: switch (naziv) {
                                          _naCekanju => () => _potvrdi(posjeta),
                                          _potvrdjena => () => _zavrsi(posjeta),
                                          _ => null,
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.cancel_outlined,
                                          color: (naziv == _naCekanju || naziv == _potvrdjena)
                                              ? posjetaStatusColors(_otkazana).foreground
                                              : null,
                                        ),
                                        tooltip: (naziv == _naCekanju || naziv == _potvrdjena)
                                            ? 'Otkaži'
                                            : 'Posjeta je već obrađena (status: $naziv) i ne može se otkazati.',
                                        onPressed:
                                            (naziv == _naCekanju || naziv == _potvrdjena) ? () => _otkazi(posjeta) : null,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.visibility_outlined),
                                        tooltip: 'Detalji',
                                        onPressed: () => _showDetail(posjeta),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
          const SizedBox(height: 12),
          const _StatusLegend(),
          if (state.totalCount > 0) ...[
            const SizedBox(height: 12),
            PageFooter(
              page: state.page,
              totalPages: state.totalPages,
              totalCount: state.totalCount,
              onPageChanged: (page) => notifier.goToPage(page),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusLegend extends StatelessWidget {
  const _StatusLegend();

  @override
  Widget build(BuildContext context) {
    const statuses = [_naCekanju, _potvrdjena, _zavrsena, _otkazana];
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        for (final naziv in statuses)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: posjetaStatusColors(naziv).foreground, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(naziv, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
      ],
    );
  }
}

/// A date picker that reads like a normal text input (matching Psi's form field styling)
/// instead of a standalone button, with a trailing calendar icon and an optional clear button.
class _DateInputField extends StatelessWidget {
  const _DateInputField({required this.value, required this.hintText, required this.onTap, this.onClear});

  final DateTime? value;
  final String hintText;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: onClear != null
              ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: onClear)
              : const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          value == null ? hintText : formatDate(value!),
          style: value == null ? TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant) : null,
        ),
      ),
    );
  }
}

class _BookingDialog extends ConsumerStatefulWidget {
  const _BookingDialog({required this.korisnikOptions, required this.dogOptions});

  final List<Korisnik> korisnikOptions;
  final List<PasListItem> dogOptions;

  @override
  ConsumerState<_BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends ConsumerState<_BookingDialog> {
  final _napomenaController = TextEditingController();
  late final DateTime _firstDate;
  late final DateTime _lastDate;
  int? _korisnikId;
  int? _pasId;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  final Map<String, String> _errors = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Same "today onward, never past" range as mobile's self-service booking (shared
    // firstBookableVisitDate/availableTimeSlots helpers) - the backend's InsertAdmin has no
    // future-date restriction of its own, but a walk-in should still never be logged for a
    // moment that has already passed, so the client enforces it consistently on both surfaces.
    _firstDate = firstBookableVisitDate();
    _lastDate = _firstDate.add(const Duration(days: 365));
  }

  @override
  void dispose() {
    _napomenaController.dispose();
    super.dispose();
  }

  DateTime? get _datumVrijeme {
    final date = _selectedDate;
    final slot = _selectedTimeSlot;
    if (date == null || slot == null) return null;
    final parts = slot.split(':');
    return DateTime(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  Future<void> _submit() async {
    final errors = <String, String>{};
    if (_korisnikId == null) errors['korisnikId'] = 'Korisnik je obavezan.';
    if (_selectedDate == null) errors['datum'] = 'Odaberite datum posjete.';
    if (_selectedTimeSlot == null) errors['vrijeme'] = 'Odaberite vrijeme posjete.';
    if (errors.isNotEmpty) {
      setState(() => _errors
        ..clear()
        ..addAll(errors));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(posjetaListProvider.notifier).bookWalkIn(
            korisnikId: _korisnikId!,
            datumVrijeme: _datumVrijeme!,
            pasId: _pasId,
            napomena: _napomenaController.text.trim().isEmpty ? null : _napomenaController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errors['form'] = e is ApiException ? e.allMessages.join('\n') : e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = _selectedDate;
    final zauzetiAsync = selectedDate == null ? null : ref.watch(posjetaZauzetiTerminiProvider(selectedDate));
    final takenTimes = (zauzetiAsync?.valueOrNull ?? const <DateTime>[])
        .map((dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}')
        .toSet();

    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('Nova posjeta')),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop(), tooltip: 'Zatvori'),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errors['form'] != null) ...[
                Text(_errors['form']!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 12),
              ],
              LabeledField(
                label: 'Korisnik',
                errorText: _errors['korisnikId'],
                child: DropdownButtonFormField<int>(
                  initialValue: _korisnikId,
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: [
                    for (final korisnik in widget.korisnikOptions)
                      DropdownMenuItem(
                        value: korisnik.korisnikId,
                        child: Text('${korisnik.ime} ${korisnik.prezime} (${korisnik.korisnickoIme})'),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    _korisnikId = value;
                    _errors.remove('korisnikId');
                  }),
                ),
              ),
              const SizedBox(height: 12),
              LabeledField(
                label: 'Pas',
                required: false,
                child: DropdownButtonFormField<int?>(
                  initialValue: _pasId,
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Opća posjeta (bez psa)')),
                    for (final pas in widget.dogOptions)
                      DropdownMenuItem<int?>(value: pas.pasId, child: Text(pas.naziv)),
                  ],
                  onChanged: (value) => setState(() => _pasId = value),
                ),
              ),
              const SizedBox(height: 12),
              LabeledField(
                label: 'Odaberite datum',
                errorText: _errors['datum'],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _errors['datum'] != null ? Theme.of(context).colorScheme.error : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: InlineCalendar(
                    firstDate: _firstDate,
                    lastDate: _lastDate,
                    selectedDate: _selectedDate,
                    onDateSelected: (date) => setState(() {
                      _selectedDate = date;
                      _selectedTimeSlot = null;
                      _errors.remove('datum');
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              LabeledField(
                label: 'Odaberite vrijeme',
                errorText: _errors['vrijeme'],
                child: selectedDate == null
                    ? Text(
                        'Prvo odaberite datum.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final slot in availableTimeSlots(selectedDate))
                            TimeSlotChip(
                              label: slot,
                              selected: slot == _selectedTimeSlot,
                              taken: takenTimes.contains(slot),
                              onTap: () => setState(() {
                                _selectedTimeSlot = slot;
                                _errors.remove('vrijeme');
                              }),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              LabeledField(
                label: 'Napomena',
                required: false,
                child: TextField(
                  controller: _napomenaController,
                  maxLines: 2,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Odustani')),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Zakaži'),
        ),
      ],
    );
  }
}
