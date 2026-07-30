import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import 'package:dogshelter_shared/core/api_exception.dart';
import 'package:dogshelter_shared/core/paged_result.dart';
import 'package:dogshelter_shared/widgets/labeled_field.dart';
import '../../../core/app_theme.dart';
import '../data/lookup_api.dart';
import '../domain/lookup_item.dart';
import '../../../widgets/debounced_search_field.dart';

const _prioritetPotrebeConfig =
    LookupTableConfig(path: '/api/PrioritetPotrebe', idKey: 'prioritetPotrebeId', label: 'Prioritet potrebe');

class PotrebaAzila {
  const PotrebaAzila({
    required this.id,
    required this.naziv,
    required this.opis,
    required this.prioritetPotrebeId,
    required this.prioritetPotrebeNaziv,
    required this.ikonaKljuc,
    required this.aktivna,
  });

  final int id;
  final String naziv;
  final String opis;
  final int prioritetPotrebeId;
  final String? prioritetPotrebeNaziv;
  final String ikonaKljuc;
  final bool aktivna;

  factory PotrebaAzila.fromJson(Map<String, dynamic> json) {
    return PotrebaAzila(
      id: json['potrebaAzilaId'] as int,
      naziv: json['naziv'] as String,
      opis: json['opis'] as String,
      prioritetPotrebeId: json['prioritetPotrebeId'] as int,
      prioritetPotrebeNaziv: json['prioritetPotrebeNaziv'] as String?,
      ikonaKljuc: json['ikonaKljuc'] as String,
      aktivna: json['aktivna'] as bool,
    );
  }
}

class PotrebaAzilaApi {
  PotrebaAzilaApi(this._client);
  final dynamic _client;

  Future<PagedResult<PotrebaAzila>> search({String? naziv}) async {
    final json = await _client.get('/api/PotrebaAzila', query: {
      if (naziv != null && naziv.isNotEmpty) 'Naziv': naziv,
      'Page': 1,
      'PageSize': 100,
    });
    return PagedResult<PotrebaAzila>.fromJson(json as Map<String, dynamic>, PotrebaAzila.fromJson);
  }

  Future<void> create(String naziv, String opis, int prioritetId, String ikonaKljuc, bool aktivna) =>
      _client.post('/api/PotrebaAzila', body: {
        'naziv': naziv,
        'opis': opis,
        'prioritetPotrebeId': prioritetId,
        'ikonaKljuc': ikonaKljuc,
        'aktivna': aktivna,
      });

  Future<void> update(int id, String naziv, String opis, int prioritetId, String ikonaKljuc, bool aktivna) =>
      _client.put('/api/PotrebaAzila/$id', body: {
        'naziv': naziv,
        'opis': opis,
        'prioritetPotrebeId': prioritetId,
        'ikonaKljuc': ikonaKljuc,
        'aktivna': aktivna,
      });

  Future<void> delete(int id) => _client.delete('/api/PotrebaAzila/$id');
}

final potrebaAzilaApiProvider = Provider<PotrebaAzilaApi>((ref) => PotrebaAzilaApi(ref.watch(apiClientProvider)));

final prioritetPotrebeOptionsProvider = FutureProvider<List<LookupItem>>((ref) async {
  final api = LookupApi(ref.watch(apiClientProvider), _prioritetPotrebeConfig);
  return (await api.search()).items;
});

class PotrebaAzilaListNotifier extends StateNotifier<AsyncValue<List<PotrebaAzila>>> {
  PotrebaAzilaListNotifier(this._api) : super(const AsyncValue.loading()) {
    load();
  }
  final PotrebaAzilaApi _api;
  String? _naziv;

  Future<void> load({String? naziv}) async {
    _naziv = naziv ?? _naziv;
    if (!state.hasValue) {
      state = const AsyncValue.loading();
    }
    state = await AsyncValue.guard(() async => (await _api.search(naziv: _naziv)).items);
  }

  Future<void> create(String naziv, String opis, int prioritetId, String ikonaKljuc, bool aktivna) async {
    await _api.create(naziv, opis, prioritetId, ikonaKljuc, aktivna);
    await load();
  }

  Future<void> update(int id, String naziv, String opis, int prioritetId, String ikonaKljuc, bool aktivna) async {
    await _api.update(id, naziv, opis, prioritetId, ikonaKljuc, aktivna);
    await load();
  }

  Future<void> remove(int id) async {
    await _api.delete(id);
    await load();
  }
}

final potrebaAzilaListProvider =
    StateNotifierProvider<PotrebaAzilaListNotifier, AsyncValue<List<PotrebaAzila>>>((ref) {
  return PotrebaAzilaListNotifier(ref.watch(potrebaAzilaApiProvider));
});

class PotrebaAzilaCrudScreen extends ConsumerStatefulWidget {
  const PotrebaAzilaCrudScreen({super.key});

  @override
  ConsumerState<PotrebaAzilaCrudScreen> createState() => _PotrebaAzilaCrudScreenState();
}

class _PotrebaAzilaCrudScreenState extends ConsumerState<PotrebaAzilaCrudScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm({PotrebaAzila? existing}) async {
    final options = await ref.read(prioritetPotrebeOptionsProvider.future);
    if (!mounted) return;
    if (options.isEmpty) {
      _showMessage('Prije dodavanja potrebe azila morate dodati barem jedan prioritet potrebe u Postavke.', isError: true);
      return;
    }

    final result = await showDialog<(String, String, int, String, bool)>(
      context: context,
      builder: (context) => _PotrebaFormDialog(existing: existing, prioritetOptions: options),
    );
    if (result == null || !mounted) return;

    final notifier = ref.read(potrebaAzilaListProvider.notifier);
    try {
      if (existing == null) {
        await notifier.create(result.$1, result.$2, result.$3, result.$4, result.$5);
        _showMessage('Potreba azila je uspješno dodana.');
      } else {
        await notifier.update(existing.id, result.$1, result.$2, result.$3, result.$4, result.$5);
        _showMessage('Potreba azila je uspješno izmijenjena.');
      }
    } catch (e) {
      _showMessage(e is ApiException ? e.allMessages.join('\n') : e.toString(), isError: true);
    }
  }

  Future<void> _confirmDelete(PotrebaAzila item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content: Text('Da li ste sigurni da želite obrisati potrebu "${item.naziv}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Obriši')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(potrebaAzilaListProvider.notifier).remove(item.id);
      _showMessage('Potreba azila je obrisana.');
    } catch (e) {
      _showMessage(e is ApiException ? e.allMessages.join('\n') : e.toString(), isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Theme.of(context).colorScheme.error : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(potrebaAzilaListProvider);

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
                    onChanged: (value) => ref.read(potrebaAzilaListProvider.notifier).load(naziv: value),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  style: AppTheme.toolbarActionButtonStyle,
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Dodaj'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Greška: $error')),
              data: (items) {
                if (items.isEmpty) return const Center(child: Text('Nema podataka.'));
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        title: Text(item.naziv),
                        subtitle: Text('${item.opis}\nPrioritet: ${item.prioritetPotrebeNaziv ?? '-'}'),
                        isThreeLine: true,
                        leading: Icon(
                          item.aktivna ? Icons.check_circle_outline : Icons.cancel_outlined,
                          color: item.aktivna ? Colors.green : Colors.grey,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Uredi',
                              onPressed: () => _openForm(existing: item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Obriši',
                              onPressed: () => _confirmDelete(item),
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
        ],
      ),
    );
  }
}

class _PotrebaFormDialog extends StatefulWidget {
  const _PotrebaFormDialog({this.existing, required this.prioritetOptions});
  final PotrebaAzila? existing;
  final List<LookupItem> prioritetOptions;

  @override
  State<_PotrebaFormDialog> createState() => _PotrebaFormDialogState();
}

class _PotrebaFormDialogState extends State<_PotrebaFormDialog> {
  late final _nazivController = TextEditingController(text: widget.existing?.naziv ?? '');
  late final _opisController = TextEditingController(text: widget.existing?.opis ?? '');
  late final _ikonaController = TextEditingController(text: widget.existing?.ikonaKljuc ?? '');
  late int _prioritetId = widget.existing?.prioritetPotrebeId ?? widget.prioritetOptions.first.id;
  late bool _aktivna = widget.existing?.aktivna ?? true;
  String? _nazivError;
  String? _opisError;
  String? _ikonaError;

  @override
  void dispose() {
    _nazivController.dispose();
    _opisController.dispose();
    _ikonaController.dispose();
    super.dispose();
  }

  void _submit() {
    final naziv = _nazivController.text.trim();
    final opis = _opisController.text.trim();
    final ikona = _ikonaController.text.trim();
    setState(() {
      _nazivError = naziv.isEmpty ? 'Naziv je obavezan.' : null;
      _opisError = opis.isEmpty ? 'Opis je obavezan.' : null;
      _ikonaError = ikona.isEmpty ? 'Ikona je obavezna.' : null;
    });
    if (_nazivError != null || _opisError != null || _ikonaError != null) return;
    Navigator.of(context).pop((naziv, opis, _prioritetId, ikona, _aktivna));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(isEdit ? 'Uredi potrebu azila' : 'Dodaj potrebu azila')),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop(), tooltip: 'Zatvori'),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LabeledField(
                label: 'Naziv',
                errorText: _nazivError,
                child: TextField(
                  controller: _nazivController,
                  autofocus: true,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(height: 12),
              LabeledField(
                label: 'Opis',
                errorText: _opisError,
                child: TextField(
                  controller: _opisController,
                  maxLines: 3,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(height: 12),
              LabeledField(
                label: 'Prioritet',
                child: DropdownButtonFormField<int>(
                  initialValue: _prioritetId,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: [
                    for (final option in widget.prioritetOptions)
                      DropdownMenuItem<int>(value: option.id, child: Text(option.naziv)),
                  ],
                  onChanged: (value) => setState(() => _prioritetId = value ?? _prioritetId),
                ),
              ),
              const SizedBox(height: 12),
              LabeledField(
                label: 'Ključ ikone',
                errorText: _ikonaError,
                child: TextField(
                  controller: _ikonaController,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'npr. hrana'),
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Aktivna'),
                value: _aktivna,
                onChanged: (value) => setState(() => _aktivna = value ?? true),
              ),
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
