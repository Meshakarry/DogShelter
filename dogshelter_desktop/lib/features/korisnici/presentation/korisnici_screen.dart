import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import 'package:dogshelter_shared/auth/domain/korisnik.dart';
import 'package:dogshelter_shared/core/api_exception.dart';
import 'package:dogshelter_shared/widgets/error_banner.dart';
import 'package:dogshelter_shared/widgets/labeled_field.dart';
import 'package:dogshelter_shared/widgets/status_pill.dart';
import '../../../core/app_theme.dart';
import '../../../widgets/debounced_search_field.dart';
import '../../../widgets/page_footer.dart';
import '../../postavke/data/lookup_api.dart';
import '../../postavke/domain/lookup_item.dart';
import '../application/korisnici_providers.dart';
import '../data/korisnik_admin_api.dart';

const _gradConfig = LookupTableConfig(path: '/api/Grad', idKey: 'gradId', label: 'grad');

final gradOptionsProvider = FutureProvider.autoDispose<List<LookupItem>>((ref) async {
  final api = LookupApi(ref.watch(apiClientProvider), _gradConfig);
  return (await api.search()).items;
});

String _describeError(Object error) => error is ApiException ? error.allMessages.join('\n') : error.toString();

class KorisniciScreen extends ConsumerStatefulWidget {
  const KorisniciScreen({super.key});

  @override
  ConsumerState<KorisniciScreen> createState() => _KorisniciScreenState();
}

class _KorisniciScreenState extends ConsumerState<KorisniciScreen> {
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

  Future<void> _openForm({Korisnik? existing}) async {
    final gradOptions = await ref.read(gradOptionsProvider.future);
    if (!mounted) return;

    final result = await showDialog<KorisnikFormData>(
      context: context,
      builder: (context) => _KorisnikFormDialog(existing: existing, gradOptions: gradOptions),
    );
    if (result == null || !mounted) return;

    final notifier = ref.read(korisnikListProvider.notifier);
    try {
      if (existing == null) {
        await notifier.create(result);
        _showMessage('Korisnik je uspješno dodan.');
      } else {
        await notifier.update(existing.korisnikId, result);
        _showMessage('Korisnik je uspješno izmijenjen.');
      }
    } catch (e) {
      _showMessage(_describeError(e), isError: true);
    }
  }

  Future<void> _confirmDelete(Korisnik korisnik) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content: Text(
          'Da li ste sigurni da želite obrisati korisnika "${korisnik.korisnickoIme}"?\n\n'
          'Ova radnja je nepovratna - lični podaci (ime, email, adresa, itd.) će biti trajno anonimizirani, a korisnik neće moći koristiti ovaj nalog.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Odustani')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(korisnikListProvider.notifier).remove(korisnik.korisnikId);
      _showMessage('Korisnik je obrisan.');
    } catch (e) {
      _showMessage(_describeError(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(korisnikListProvider);

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
                    hintText: 'Pretraga po korisničkom imenu...',
                    onChanged: (value) => ref.read(korisnikListProvider.notifier).load(query: value),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  style: AppTheme.toolbarActionButtonStyle,
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Dodaj korisnika'),
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
                if (items.isEmpty) return const Center(child: Text('Nema korisnika.'));
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final korisnik = items[index];
                      return ListTile(
                        title: Text('${korisnik.ime} ${korisnik.prezime} (${korisnik.korisnickoIme})'),
                        subtitle: Text(korisnik.email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final role in korisnik.roles) ...[
                              StatusPill(label: role),
                              const SizedBox(width: 6),
                            ],
                            StatusPill(
                              label: korisnik.aktivan ? 'Aktivan' : 'Neaktivan',
                              color: korisnik.aktivan
                                  ? Theme.of(context).colorScheme.secondaryContainer
                                  : Theme.of(context).colorScheme.errorContainer,
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Uredi',
                              onPressed: () => _openForm(existing: korisnik),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Obriši',
                              onPressed: () => _confirmDelete(korisnik),
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
              onPageChanged: (page) => ref.read(korisnikListProvider.notifier).goToPage(page),
            ),
          ],
        ],
      ),
    );
  }
}

class _KorisnikFormDialog extends StatefulWidget {
  const _KorisnikFormDialog({this.existing, required this.gradOptions});

  final Korisnik? existing;
  final List<LookupItem> gradOptions;

  @override
  State<_KorisnikFormDialog> createState() => _KorisnikFormDialogState();
}

class _KorisnikFormDialogState extends State<_KorisnikFormDialog> {
  late final _imeController = TextEditingController(text: widget.existing?.ime ?? '');
  late final _prezimeController = TextEditingController(text: widget.existing?.prezime ?? '');
  late final _emailController = TextEditingController(text: widget.existing?.email ?? '');
  late final _telefonController = TextEditingController(text: widget.existing?.telefon ?? '');
  late final _adresaController = TextEditingController(text: widget.existing?.adresa ?? '');
  late final _korisnickoImeController = TextEditingController(text: widget.existing?.korisnickoIme ?? '');
  final _lozinkaController = TextEditingController();
  final _lozinkaPotvrdaController = TextEditingController();

  int? _gradId;
  late bool _aktivan;
  late Set<String> _selectedRoles;
  final Map<String, String> _errors = {};

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _gradId = widget.existing?.gradId;
    _aktivan = widget.existing?.aktivan ?? true;
    _selectedRoles = widget.existing?.roles.toSet() ?? {};
  }

  @override
  void dispose() {
    _imeController.dispose();
    _prezimeController.dispose();
    _emailController.dispose();
    _telefonController.dispose();
    _adresaController.dispose();
    _korisnickoImeController.dispose();
    _lozinkaController.dispose();
    _lozinkaPotvrdaController.dispose();
    super.dispose();
  }

  void _submit() {
    final ime = _imeController.text.trim();
    final prezime = _prezimeController.text.trim();
    final email = _emailController.text.trim();
    final korisnickoIme = _korisnickoImeController.text.trim();
    final lozinka = _lozinkaController.text;
    final lozinkaPotvrda = _lozinkaPotvrdaController.text;

    final errors = <String, String>{};
    if (ime.isEmpty) errors['ime'] = 'Ime je obavezno.';
    if (prezime.isEmpty) errors['prezime'] = 'Prezime je obavezno.';
    if (email.isEmpty) errors['email'] = 'Email je obavezan.';
    if (korisnickoIme.isEmpty) errors['korisnickoIme'] = 'Korisničko ime je obavezno.';
    if (!_isEdit && lozinka.isEmpty) errors['lozinka'] = 'Lozinka je obavezna.';
    if (lozinka.isNotEmpty && lozinka != lozinkaPotvrda) {
      errors['lozinkaPotvrda'] = 'Lozinke se ne podudaraju.';
    }
    if (errors.isNotEmpty) {
      setState(() => _errors
        ..clear()
        ..addAll(errors));
      return;
    }

    final currentRoles = widget.existing?.roles.toSet() ?? {};
    final added = _selectedRoles.difference(currentRoles).toList();
    final removed = currentRoles.difference(_selectedRoles).toList();

    Navigator.of(context).pop(KorisnikFormData(
      ime: ime,
      prezime: prezime,
      email: email,
      telefon: _telefonController.text.trim().isEmpty ? null : _telefonController.text.trim(),
      gradId: _gradId,
      adresa: _adresaController.text.trim().isEmpty ? null : _adresaController.text.trim(),
      korisnickoIme: korisnickoIme,
      lozinka: lozinka.isEmpty ? null : lozinka,
      lozinkaPotvrda: lozinka.isEmpty ? null : lozinkaPotvrda,
      status: _isEdit ? _aktivan : null,
      uloge: _isEdit ? added : _selectedRoles.toList(),
      ulogeZaBrisanje: _isEdit ? removed : const [],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _isEdit;
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(isEdit ? 'Uredi korisnika' : 'Dodaj korisnika')),
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
                      label: 'Telefon',
                      required: false,
                      child: TextField(
                        controller: _telefonController,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabeledField(
                      label: 'Grad',
                      required: false,
                      child: DropdownButtonFormField<int?>(
                        initialValue: _gradId,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('Nije odabran')),
                          for (final grad in widget.gradOptions)
                            DropdownMenuItem<int?>(value: grad.id, child: Text(grad.naziv)),
                        ],
                        onChanged: (value) => setState(() => _gradId = value),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LabeledField(
                label: 'Adresa',
                required: false,
                child: TextField(
                  controller: _adresaController,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: LabeledField(
                      label: isEdit ? 'Nova lozinka' : 'Lozinka',
                      required: !isEdit,
                      errorText: _errors['lozinka'],
                      child: TextField(
                        controller: _lozinkaController,
                        obscureText: true,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: isEdit ? 'Ostavite prazno da ostane nepromijenjena' : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabeledField(
                      label: 'Potvrda lozinke',
                      required: !isEdit,
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
              Text('Uloge', style: Theme.of(context).textTheme.bodyMedium),
              Wrap(
                spacing: 8,
                children: [
                  for (final role in roleNames)
                    FilterChip(
                      label: Text(role),
                      selected: _selectedRoles.contains(role),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _selectedRoles.add(role);
                        } else {
                          _selectedRoles.remove(role);
                        }
                      }),
                    ),
                ],
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
