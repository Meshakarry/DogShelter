import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/core/date_format.dart';
import 'package:dogshelter_shared/core/image_url.dart';
import 'package:dogshelter_shared/dogadjaj/data/dogadjaj_api.dart';
import 'package:dogshelter_shared/dogadjaj/domain/dogadjaj.dart';
import 'package:dogshelter_shared/dogadjaj_volonter/domain/dogadjaj_volonter.dart';
import 'package:dogshelter_shared/volonter/domain/volonter.dart';
import 'package:dogshelter_shared/widgets/error_banner.dart';
import 'package:dogshelter_shared/widgets/form_error_scroller.dart';
import 'package:dogshelter_shared/widgets/labeled_field.dart';
import '../../../environment.dart';
import '../../../widgets/cover_image_picker.dart';
import '../../../widgets/gradient_button.dart';
import '../../volonteri/application/volonteri_providers.dart' show dogadjajVolonterApiProvider;
import '../application/dogadjaji_providers.dart';

class DogadjajFormScreen extends ConsumerWidget {
  const DogadjajFormScreen({super.key, this.dogadjajId});

  final int? dogadjajId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final body = dogadjajId == null
        ? const _DogadjajFormBody(dogadjajId: null, initial: null)
        : ref.watch(dogadjajDetailProvider(dogadjajId!)).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: ErrorBanner(error: e)),
              data: (dogadjaj) => _DogadjajFormBody(dogadjajId: dogadjajId, initial: dogadjaj),
            );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 24, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Nazad',
                onPressed: () => context.go('/dogadjaji'),
              ),
              Text(
                dogadjajId == null ? 'Novi događaj' : 'Uredi događaj',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}

class _DogadjajFormBody extends ConsumerStatefulWidget {
  const _DogadjajFormBody({required this.dogadjajId, required this.initial});

  final int? dogadjajId;
  final Dogadjaj? initial;

  @override
  ConsumerState<_DogadjajFormBody> createState() => _DogadjajFormBodyState();
}

class _DogadjajFormBodyState extends ConsumerState<_DogadjajFormBody> with FormErrorScroller<_DogadjajFormBody> {
  late final _nazivController = TextEditingController(text: widget.initial?.naziv ?? '');
  late final _opisController = TextEditingController(text: widget.initial?.opis ?? '');
  late final _lokacijaController = TextEditingController(text: widget.initial?.lokacija ?? '');

  late DateTime _datum;
  late bool _aktivan;
  File? _newSlika;
  bool _isSaving = false;
  Object? _submitError;

  List<_RosterEntry>? _rosterEntries;
  final Set<int> _pendingRemoveIds = {};
  Object? _rosterError;

  @override
  final errorScrollController = ScrollController();

  @override
  List<String> get fieldOrder => const ['naziv', 'coverImage', 'datum', 'lokacija'];

  bool get _isEdit => widget.dogadjajId != null;

  @override
  void initState() {
    super.initState();
    _datum = widget.initial?.datum ?? DateTime.now();
    _aktivan = widget.initial?.aktivan ?? true;
    if (_isEdit) _loadInitialRoster();
  }

  Future<void> _loadInitialRoster() async {
    try {
      final result =
          await ref.read(dogadjajVolonterApiProvider).search(dogadjajId: widget.dogadjajId!, pageSize: 100);
      if (mounted) {
        setState(() => _rosterEntries = [for (final z in result.items) _RosterEntry.existing(z)]);
      }
    } catch (e) {
      if (mounted) setState(() => _rosterError = e);
    }
  }

  void _addPendingVolonter(Volonter volonter) {
    setState(() => _rosterEntries = [
          ...?_rosterEntries,
          _RosterEntry.pending(volonter),
        ]);
  }

  void _removeRosterEntry(_RosterEntry entry) {
    setState(() {
      if (entry.dogadjajVolonterId != null) _pendingRemoveIds.add(entry.dogadjajVolonterId!);
      _rosterEntries = _rosterEntries!.where((e) => e != entry).toList();
    });
  }

  @override
  void dispose() {
    _nazivController.dispose();
    _opisController.dispose();
    _lokacijaController.dispose();
    errorScrollController.dispose();
    super.dispose();
  }

  Future<void> _pickSlika() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path == null) return;
    clearFieldError('coverImage');
    setState(() => _newSlika = File(path));
  }

  Future<void> _pickDatum() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _datum,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_datum));
    if (time == null) return;
    setState(() {
      _datum = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      clearFieldError('datum');
    });
  }

  Future<void> _submit() async {
    final errors = <String, String>{};
    final naziv = _nazivController.text.trim();
    final lokacija = _lokacijaController.text.trim();
    if (naziv.isEmpty) errors['naziv'] = 'Naziv je obavezan.';
    if (lokacija.isEmpty) errors['lokacija'] = 'Lokacija je obavezna.';
    if (!_isEdit && _newSlika == null) errors['coverImage'] = 'Naslovna slika je obavezna.';

    if (errors.isNotEmpty) {
      applyValidationErrors(errors);
      return;
    }
    clearAllFieldErrors();

    final data = DogadjajFormData(
      naziv: naziv,
      opis: _opisController.text.trim().isEmpty ? null : _opisController.text.trim(),
      datum: _datum,
      lokacija: lokacija,
      aktivan: _isEdit ? _aktivan : true,
    );

    setState(() {
      _isSaving = true;
      _submitError = null;
    });
    try {
      final api = ref.read(dogadjajApiProvider);
      if (_isEdit) {
        await api.update(widget.dogadjajId!, data, slika: _newSlika);
        await _applyRosterDiff(widget.dogadjajId!);
        ref.invalidate(dogadjajDetailProvider(widget.dogadjajId!));
        if (mounted) _showMessage('Događaj je uspješno izmijenjen.');
      } else {
        final created = await api.insert(data, _newSlika!);
        if (mounted) {
          _showMessage('Događaj je uspješno dodan.');
          context.go('/dogadjaji/${created.dogadjajId}');
        }
      }
      ref.invalidate(dogadjajListProvider);
    } catch (e) {
      setState(() => _submitError = e);
      scrollToTop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Applies the locally-staged roster changes (pending adds + pending removes) as the actual
  /// zaduzi/ukloni API calls - only ever called after the Dogadjaj itself has saved successfully.
  Future<void> _applyRosterDiff(int dogadjajId) async {
    final entries = _rosterEntries;
    if (entries == null) return;

    final rosterApi = ref.read(dogadjajVolonterApiProvider);
    for (final entry in entries.where((e) => e.dogadjajVolonterId == null)) {
      await rosterApi.zaduzi(dogadjajId: dogadjajId, volonterId: entry.volonterId);
    }
    for (final id in _pendingRemoveIds) {
      await rosterApi.ukloni(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: errorScrollController,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SizedBox(
          width: 720,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_submitError != null) ErrorBanner(error: _submitError),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CoverImagePicker(
                    key: keyFor('coverImage'),
                    existingUrl: resolveImageUrl(widget.initial?.slikaPutanja, Environment.apiBaseUrl),
                    newImage: _newSlika,
                    onPick: _pickSlika,
                    errorText: fieldErrors['coverImage'],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LabeledField(
                          key: keyFor('naziv'),
                          label: 'Naziv',
                          errorText: fieldErrors['naziv'],
                          child: TextField(
                            controller: _nazivController,
                            onChanged: (_) => clearFieldError('naziv'),
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(height: 12),
                        LabeledField(
                          key: keyFor('lokacija'),
                          label: 'Lokacija',
                          errorText: fieldErrors['lokacija'],
                          child: TextField(
                            controller: _lokacijaController,
                            onChanged: (_) => clearFieldError('lokacija'),
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LabeledField(
                key: keyFor('datum'),
                label: 'Datum i vrijeme',
                errorText: fieldErrors['datum'],
                child: InkWell(
                  onTap: _pickDatum,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                    ),
                    child: Text(formatDateTime(_datum)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              LabeledField(
                label: 'Opis',
                required: false,
                child: TextField(
                  controller: _opisController,
                  maxLines: 4,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(height: 12),
              if (_isEdit)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Aktivan'),
                  value: _aktivan,
                  onChanged: (value) => setState(() => _aktivan = value ?? true),
                ),
              if (_isEdit) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                Text('Zaduženi volonteri', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _RosterSection(
                  entries: _rosterEntries,
                  error: _rosterError,
                  onAdd: _addPendingVolonter,
                  onRemove: _removeRosterEntry,
                ),
              ],
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: GradientButton(
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Sačuvaj'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One roster row - either an already-persisted assignment ([dogadjajVolonterId] set, loaded
/// from the server) or a locally-staged pending add ([dogadjajVolonterId] null, not yet sent).
class _RosterEntry {
  const _RosterEntry({required this.dogadjajVolonterId, required this.volonterId, required this.ime, required this.prezime});

  factory _RosterEntry.existing(DogadjajVolonter zaduzenje) => _RosterEntry(
        dogadjajVolonterId: zaduzenje.dogadjajVolonterId,
        volonterId: zaduzenje.volonterId,
        ime: zaduzenje.volonterIme ?? '',
        prezime: zaduzenje.volonterPrezime ?? '',
      );

  factory _RosterEntry.pending(Volonter volonter) => _RosterEntry(
        dogadjajVolonterId: null,
        volonterId: volonter.volonterId,
        ime: volonter.korisnikIme ?? '',
        prezime: volonter.korisnikPrezime ?? '',
      );

  final int? dogadjajVolonterId;
  final int volonterId;
  final String ime;
  final String prezime;
}

/// Pure display + local staging - no network calls of its own. Add/remove only mutate the
/// parent's [_DogadjajFormBodyState._rosterEntries]/[_pendingRemoveIds]; the actual zaduzi/ukloni
/// requests are only issued once, as a diff, when Sačuvaj is pressed (see [_applyRosterDiff]).
class _RosterSection extends ConsumerStatefulWidget {
  const _RosterSection({required this.entries, required this.error, required this.onAdd, required this.onRemove});

  final List<_RosterEntry>? entries;
  final Object? error;
  final ValueChanged<Volonter> onAdd;
  final ValueChanged<_RosterEntry> onRemove;

  @override
  ConsumerState<_RosterSection> createState() => _RosterSectionState();
}

class _RosterSectionState extends ConsumerState<_RosterSection> {
  int? _selectedVolonterId;

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    final aktivniVolonteriAsync = ref.watch(aktivniVolonteriProvider);

    if (widget.error != null) return ErrorBanner(error: widget.error);
    if (entries == null) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (entries.isEmpty)
          const Text('Trenutno nema zaduženih volontera.')
        else
          Card(
            margin: EdgeInsets.zero,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text('${entry.ime} ${entry.prezime}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Ukloni',
                    onPressed: () => widget.onRemove(entry),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: aktivniVolonteriAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Greška: $e'),
                data: (volonteri) {
                  final assignedIds = entries.map((e) => e.volonterId).toSet();
                  final available = volonteri.where((v) => !assignedIds.contains(v.volonterId)).toList();
                  return DropdownButtonFormField<int>(
                    initialValue: _selectedVolonterId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      hintText: 'Odaberite volontera',
                    ),
                    items: [
                      for (final volonter in available)
                        DropdownMenuItem(
                          value: volonter.volonterId,
                          child: Text('${volonter.korisnikIme ?? ''} ${volonter.korisnikPrezime ?? ''}'),
                        ),
                    ],
                    onChanged: (value) => setState(() => _selectedVolonterId = value),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _selectedVolonterId == null
                  ? null
                  : () {
                      final volonter = aktivniVolonteriAsync.valueOrNull
                          ?.firstWhere((v) => v.volonterId == _selectedVolonterId);
                      if (volonter == null) return;
                      widget.onAdd(volonter);
                      setState(() => _selectedVolonterId = null);
                    },
              icon: const Icon(Icons.add),
              label: const Text('Zaduži'),
            ),
          ],
        ),
      ],
    );
  }
}

