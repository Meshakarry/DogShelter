import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/core/api_exception.dart';
import 'package:dogshelter_shared/core/date_format.dart';
import 'package:dogshelter_shared/volonter/domain/volonter.dart';
import 'package:dogshelter_shared/widgets/error_banner.dart';
import 'package:dogshelter_shared/widgets/labeled_field.dart';
import 'package:dogshelter_shared/widgets/status_pill.dart';
import '../../../core/app_theme.dart';
import '../../../widgets/debounced_search_field.dart';
import '../../../widgets/page_footer.dart';
import '../../../widgets/status_colors.dart';
import '../../korisnici/data/korisnik_admin_api.dart';
import '../application/volonteri_providers.dart';

String _describeError(Object error) => error is ApiException ? error.allMessages.join('\n') : error.toString();

class VolonteriScreen extends ConsumerStatefulWidget {
  const VolonteriScreen({super.key});

  @override
  ConsumerState<VolonteriScreen> createState() => _VolonteriScreenState();
}

class _VolonteriScreenState extends ConsumerState<VolonteriScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Theme.of(context).colorScheme.error : null),
    );
  }

  Future<void> _openCreateDialog() async {
    final result = await showDialog<_VolonterFormResult>(
      context: context,
      builder: (context) => const _VolonterFormDialog(existing: null),
    );
    if (result == null || !mounted) return;

    try {
      final korisnik = await ref.read(volonterFormApiProvider).insert(result.korisnik!);
      await ref.read(volonterListProvider.notifier).create(
            korisnikId: korisnik.korisnikId,
            datumPridruzivanja: result.datumPridruzivanja,
            napomena: result.napomena,
          );
      _showMessage('Volonter je uspješno dodan.');
    } catch (e) {
      if (mounted) _showMessage(_describeError(e), isError: true);
    }
  }

  Future<void> _openEditDialog(Volonter volonter) async {
    final result = await showDialog<_VolonterFormResult>(
      context: context,
      builder: (context) => _VolonterFormDialog(existing: volonter),
    );
    if (result == null || !mounted) return;

    try {
      await ref
          .read(volonterListProvider.notifier)
          .update(volonter.volonterId, aktivan: result.aktivan, napomena: result.napomena);
      _showMessage('Volonter je uspješno izmijenjen.');
    } catch (e) {
      if (mounted) _showMessage(_describeError(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(volonterListProvider);
    final notifier = ref.read(volonterListProvider.notifier);

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
                Expanded(
                  child: DebouncedSearchField(
                    controller: _searchController,
                    hintText: 'Pretraga po imenu ili prezimenu...',
                    onChanged: (value) => notifier.load(query: value),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<bool?>(
                    initialValue: notifier.aktivan,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, hintText: 'Status'),
                    items: const [
                      DropdownMenuItem<bool?>(value: null, child: Text('Svi')),
                      DropdownMenuItem<bool?>(value: true, child: Text('Aktivan')),
                      DropdownMenuItem<bool?>(value: false, child: Text('Neaktivan')),
                    ],
                    onChanged: (value) => notifier.filterByAktivan(value),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  style: AppTheme.toolbarActionButtonStyle,
                  onPressed: _openCreateDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Dodaj volontera'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: ErrorBanner(error: error)),
              data: (result) {
                final items = result.items;
                if (items.isEmpty) return const Center(child: Text('Nema volontera.'));
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final volonter = items[index];
                      final colors = volonterStatusColors(volonter.aktivan);
                      return ListTile(
                        onTap: () => context.go('/volonteri/${volonter.volonterId}'),
                        title: Text('${volonter.korisnikIme ?? ''} ${volonter.korisnikPrezime ?? ''}'),
                        subtitle: Text(
                          '${volonter.korisnikEmail ?? ''} · Pridružio se ${formatDate(volonter.datumPridruzivanja)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StatusPill(label: '${volonter.ukupnoSati.toStringAsFixed(1)} h'),
                            const SizedBox(width: 6),
                            StatusPill(
                              label: volonter.aktivan ? 'Aktivan' : 'Neaktivan',
                              color: colors.background,
                              foregroundColor: colors.foreground,
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Uredi',
                              onPressed: () => _openEditDialog(volonter),
                            ),
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined),
                              tooltip: 'Profil',
                              onPressed: () => context.go('/volonteri/${volonter.volonterId}'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          if (itemsAsync.valueOrNull != null && itemsAsync.value!.totalCount > 0) ...[
            const SizedBox(height: 12),
            PageFooter(
              page: itemsAsync.value!.page,
              totalPages: itemsAsync.value!.totalPages,
              totalCount: itemsAsync.value!.totalCount,
              onPageChanged: (page) => notifier.goToPage(page),
            ),
          ],
        ],
      ),
    );
  }
}

class _VolonterFormResult {
  const _VolonterFormResult({this.korisnik, required this.datumPridruzivanja, required this.aktivan, this.napomena});

  final KorisnikFormData? korisnik;
  final DateTime datumPridruzivanja;
  final bool aktivan;
  final String? napomena;
}

class _VolonterFormDialog extends StatefulWidget {
  const _VolonterFormDialog({required this.existing});

  final Volonter? existing;

  @override
  State<_VolonterFormDialog> createState() => _VolonterFormDialogState();
}

class _VolonterFormDialogState extends State<_VolonterFormDialog> {
  late final _imeController = TextEditingController();
  late final _prezimeController = TextEditingController();
  late final _emailController = TextEditingController();
  late final _telefonController = TextEditingController();
  late final _korisnickoImeController = TextEditingController();
  final _lozinkaController = TextEditingController();
  final _lozinkaPotvrdaController = TextEditingController();
  late final _napomenaController = TextEditingController(text: widget.existing?.napomena ?? '');

  late DateTime _datumPridruzivanja;
  late bool _aktivan;
  final Map<String, String> _errors = {};

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _datumPridruzivanja = widget.existing?.datumPridruzivanja ?? DateTime.now();
    _aktivan = widget.existing?.aktivan ?? true;
  }

  @override
  void dispose() {
    _imeController.dispose();
    _prezimeController.dispose();
    _emailController.dispose();
    _telefonController.dispose();
    _korisnickoImeController.dispose();
    _lozinkaController.dispose();
    _lozinkaPotvrdaController.dispose();
    _napomenaController.dispose();
    super.dispose();
  }

  Future<void> _pickDatumPridruzivanja() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _datumPridruzivanja,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _datumPridruzivanja = picked);
  }

  void _submit() {
    final napomena = _napomenaController.text.trim();

    if (_isEdit) {
      Navigator.of(context).pop(_VolonterFormResult(
        datumPridruzivanja: _datumPridruzivanja,
        aktivan: _aktivan,
        napomena: napomena.isEmpty ? null : napomena,
      ));
      return;
    }

    final ime = _imeController.text.trim();
    final prezime = _prezimeController.text.trim();
    final email = _emailController.text.trim();
    final korisnickoIme = _korisnickoImeController.text.trim();
    final lozinka = _lozinkaController.text;

    final errors = <String, String>{};
    if (ime.isEmpty) errors['ime'] = 'Ime je obavezno.';
    if (prezime.isEmpty) errors['prezime'] = 'Prezime je obavezno.';
    if (email.isEmpty) errors['email'] = 'Email je obavezan.';
    if (korisnickoIme.isEmpty) errors['korisnickoIme'] = 'Korisničko ime je obavezno.';
    if (lozinka.isEmpty) errors['lozinka'] = 'Lozinka je obavezna.';
    if (lozinka.isNotEmpty && lozinka != _lozinkaPotvrdaController.text) {
      errors['lozinkaPotvrda'] = 'Lozinke se ne podudaraju.';
    }
    if (errors.isNotEmpty) {
      setState(() => _errors
        ..clear()
        ..addAll(errors));
      return;
    }

    Navigator.of(context).pop(_VolonterFormResult(
      korisnik: KorisnikFormData(
        ime: ime,
        prezime: prezime,
        email: email,
        telefon: _telefonController.text.trim().isEmpty ? null : _telefonController.text.trim(),
        korisnickoIme: korisnickoIme,
        lozinka: lozinka,
        lozinkaPotvrda: _lozinkaPotvrdaController.text,
        uloge: const ['Volonter'],
      ),
      datumPridruzivanja: _datumPridruzivanja,
      aktivan: true,
      napomena: napomena.isEmpty ? null : napomena,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _isEdit;
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(isEdit ? 'Uredi volontera' : 'Dodaj volontera')),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop(), tooltip: 'Zatvori'),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isEdit) ...[
                Row(
                  children: [
                    Expanded(
                      child: LabeledField(
                        label: 'Ime',
                        errorText: _errors['ime'],
                        child: TextField(
                          controller: _imeController,
                          autofocus: true,
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LabeledField(
                        label: 'Prezime',
                        errorText: _errors['prezime'],
                        child: TextField(
                          controller: _prezimeController,
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LabeledField(
                  label: 'Email',
                  errorText: _errors['email'],
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(height: 12),
                LabeledField(
                  label: 'Telefon',
                  required: false,
                  child: TextField(
                    controller: _telefonController,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(height: 12),
                LabeledField(
                  label: 'Korisničko ime',
                  errorText: _errors['korisnickoIme'],
                  child: TextField(
                    controller: _korisnickoImeController,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: LabeledField(
                        label: 'Lozinka',
                        errorText: _errors['lozinka'],
                        child: TextField(
                          controller: _lozinkaController,
                          obscureText: true,
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LabeledField(
                        label: 'Potvrda lozinke',
                        errorText: _errors['lozinkaPotvrda'],
                        child: TextField(
                          controller: _lozinkaPotvrdaController,
                          obscureText: true,
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              LabeledField(
                label: 'Datum pridruživanja',
                child: InkWell(
                  onTap: _pickDatumPridruzivanja,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                    ),
                    child: Text(formatDate(_datumPridruzivanja)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              LabeledField(
                label: 'Napomena',
                required: false,
                child: TextField(
                  controller: _napomenaController,
                  maxLines: 3,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              if (isEdit) ...[
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Aktivan'),
                  value: _aktivan,
                  onChanged: (value) => setState(() => _aktivan = value ?? true),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Odustani')),
        FilledButton(onPressed: _submit, child: const Text('Sačuvaj')),
      ],
    );
  }
}
