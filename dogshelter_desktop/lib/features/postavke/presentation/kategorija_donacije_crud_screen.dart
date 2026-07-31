import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import 'package:dogshelter_shared/core/api_exception.dart';
import 'package:dogshelter_shared/core/paged_result.dart';
import 'package:dogshelter_shared/widgets/labeled_field.dart';
import '../../../core/app_theme.dart';
import '../../../core/paged_list_notifier.dart';
import '../data/lookup_api.dart';
import '../domain/lookup_item.dart';
import '../../../widgets/debounced_search_field.dart';
import '../../../widgets/page_footer.dart';

const _jedinicaMjereConfig = LookupTableConfig(path: '/api/JedinicaMjere', idKey: 'jedinicaMjereId', label: 'Jedinice mjere');

class KategorijaDonacije {
  const KategorijaDonacije({
    required this.id,
    required this.naziv,
    required this.ikonaKljuc,
    required this.podrazumijevanaJedinicaMjereId,
    required this.dozvoljeneJedinice,
  });

  final int id;
  final String naziv;
  final String ikonaKljuc;
  final int? podrazumijevanaJedinicaMjereId;
  final List<LookupItem> dozvoljeneJedinice;

  factory KategorijaDonacije.fromJson(Map<String, dynamic> json) {
    return KategorijaDonacije(
      id: json['kategorijaDonacijeId'] as int,
      naziv: json['naziv'] as String,
      ikonaKljuc: json['ikonaKljuc'] as String,
      podrazumijevanaJedinicaMjereId: json['podrazumijevanaJedinicaMjereId'] as int?,
      dozvoljeneJedinice: (json['dozvoljeneJedinice'] as List<dynamic>? ?? [])
          .map((e) => LookupItem.fromJson(e as Map<String, dynamic>, 'jedinicaMjereId'))
          .toList(),
    );
  }
}

class KategorijaDonacijeApi {
  KategorijaDonacijeApi(this._client);
  final dynamic _client;

  Future<PagedResult<KategorijaDonacije>> search({String? naziv, int page = 1}) async {
    final json = await _client.get('/api/KategorijaDonacije', query: {
      if (naziv != null && naziv.isNotEmpty) 'Naziv': naziv,
      'Page': page,
      'PageSize': 100,
    });
    return PagedResult<KategorijaDonacije>.fromJson(json as Map<String, dynamic>, KategorijaDonacije.fromJson);
  }

  Future<void> create(String naziv, String ikonaKljuc, int? podrazumijevanaJedinicaMjereId, List<int> dozvoljeneJediniceIds) =>
      _client.post('/api/KategorijaDonacije', body: {
        'naziv': naziv,
        'ikonaKljuc': ikonaKljuc,
        'podrazumijevanaJedinicaMjereId': podrazumijevanaJedinicaMjereId,
        'dozvoljeneJediniceIds': dozvoljeneJediniceIds,
      });

  Future<void> update(
    int id,
    String naziv,
    String ikonaKljuc,
    int? podrazumijevanaJedinicaMjereId,
    List<int> dozvoljeneJediniceIds,
  ) =>
      _client.put('/api/KategorijaDonacije/$id', body: {
        'naziv': naziv,
        'ikonaKljuc': ikonaKljuc,
        'podrazumijevanaJedinicaMjereId': podrazumijevanaJedinicaMjereId,
        'dozvoljeneJediniceIds': dozvoljeneJediniceIds,
      });

  Future<void> delete(int id) => _client.delete('/api/KategorijaDonacije/$id');
}

final kategorijaDonacijeApiProvider = Provider<KategorijaDonacijeApi>((ref) => KategorijaDonacijeApi(ref.watch(apiClientProvider)));

final jedinicaMjereOptionsProvider = FutureProvider<List<LookupItem>>((ref) async {
  final api = LookupApi(ref.watch(apiClientProvider), _jedinicaMjereConfig);
  return (await api.search()).items;
});

class KategorijaDonacijeListNotifier extends PagedListNotifier<KategorijaDonacije> {
  KategorijaDonacijeListNotifier(this._api);
  final KategorijaDonacijeApi _api;

  @override
  Future<PagedResult<KategorijaDonacije>> fetch({String? query, required int page}) =>
      _api.search(naziv: query, page: page);

  Future<void> create(String naziv, String ikonaKljuc, int? jedinicaId, List<int> jedinice) async {
    await _api.create(naziv, ikonaKljuc, jedinicaId, jedinice);
    await refresh();
  }

  Future<void> update(int id, String naziv, String ikonaKljuc, int? jedinicaId, List<int> jedinice) async {
    await _api.update(id, naziv, ikonaKljuc, jedinicaId, jedinice);
    await refresh();
  }

  Future<void> remove(int id) async {
    await _api.delete(id);
    await refresh();
  }
}

final kategorijaDonacijeListProvider =
    StateNotifierProvider<KategorijaDonacijeListNotifier, AsyncValue<PagedResult<KategorijaDonacije>>>((ref) {
  return KategorijaDonacijeListNotifier(ref.watch(kategorijaDonacijeApiProvider));
});

class KategorijaDonacijeCrudScreen extends ConsumerStatefulWidget {
  const KategorijaDonacijeCrudScreen({super.key});

  @override
  ConsumerState<KategorijaDonacijeCrudScreen> createState() => _KategorijaDonacijeCrudScreenState();
}

class _KategorijaDonacijeCrudScreenState extends ConsumerState<KategorijaDonacijeCrudScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm({KategorijaDonacije? existing}) async {
    final options = await ref.read(jedinicaMjereOptionsProvider.future);
    if (!mounted) return;

    final result = await showDialog<(String, String, int?, List<int>)>(
      context: context,
      builder: (context) => _KategorijaFormDialog(existing: existing, jediniceOptions: options),
    );
    if (result == null || !mounted) return;

    final notifier = ref.read(kategorijaDonacijeListProvider.notifier);
    try {
      if (existing == null) {
        await notifier.create(result.$1, result.$2, result.$3, result.$4);
        _showMessage('Kategorija je uspješno dodana.');
      } else {
        await notifier.update(existing.id, result.$1, result.$2, result.$3, result.$4);
        _showMessage('Kategorija je uspješno izmijenjena.');
      }
    } catch (e) {
      _showMessage(e is ApiException ? e.allMessages.join('\n') : e.toString(), isError: true);
    }
  }

  Future<void> _confirmDelete(KategorijaDonacije item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content: Text('Da li ste sigurni da želite obrisati kategoriju "${item.naziv}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Obriši')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(kategorijaDonacijeListProvider.notifier).remove(item.id);
      _showMessage('Kategorija je obrisana.');
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
    final itemsAsync = ref.watch(kategorijaDonacijeListProvider);

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
                    onChanged: (value) => ref.read(kategorijaDonacijeListProvider.notifier).load(query: value),
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
              data: (result) {
                final items = result.items;
                if (items.isEmpty) return const Center(child: Text('Nema podataka.'));
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final unitLabel = item.dozvoljeneJedinice.isEmpty
                          ? 'Sve jedinice mjere'
                          : item.dozvoljeneJedinice.map((e) => e.naziv).join(', ');
                      return ListTile(
                        title: Text(item.naziv),
                        subtitle: Text('Ikona: ${item.ikonaKljuc} · Dozvoljene jedinice: $unitLabel'),
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
          if (itemsAsync.valueOrNull != null && itemsAsync.value!.totalCount > 0) ...[
            const SizedBox(height: 12),
            PageFooter(
              page: itemsAsync.value!.page,
              totalPages: itemsAsync.value!.totalPages,
              totalCount: itemsAsync.value!.totalCount,
              onPageChanged: (page) => ref.read(kategorijaDonacijeListProvider.notifier).goToPage(page),
            ),
          ],
        ],
      ),
    );
  }
}

class _KategorijaFormDialog extends StatefulWidget {
  const _KategorijaFormDialog({this.existing, required this.jediniceOptions});
  final KategorijaDonacije? existing;
  final List<LookupItem> jediniceOptions;

  @override
  State<_KategorijaFormDialog> createState() => _KategorijaFormDialogState();
}

class _KategorijaFormDialogState extends State<_KategorijaFormDialog> {
  late final _nazivController = TextEditingController(text: widget.existing?.naziv ?? '');
  late final _ikonaController = TextEditingController(text: widget.existing?.ikonaKljuc ?? '');
  int? _podrazumijevanaJedinicaId;
  late Set<int> _selectedJedinice;
  String? _nazivError;
  String? _ikonaError;

  @override
  void initState() {
    super.initState();
    _podrazumijevanaJedinicaId = widget.existing?.podrazumijevanaJedinicaMjereId;
    _selectedJedinice = widget.existing?.dozvoljeneJedinice.map((e) => e.id).toSet() ?? {};
  }

  @override
  void dispose() {
    _nazivController.dispose();
    _ikonaController.dispose();
    super.dispose();
  }

  void _submit() {
    final naziv = _nazivController.text.trim();
    final ikona = _ikonaController.text.trim();
    setState(() {
      _nazivError = naziv.isEmpty ? 'Naziv je obavezan.' : null;
      _ikonaError = ikona.isEmpty ? 'Ikona je obavezna.' : null;
    });
    if (_nazivError != null || _ikonaError != null) return;
    Navigator.of(context).pop((naziv, ikona, _podrazumijevanaJedinicaId, _selectedJedinice.toList()));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(isEdit ? 'Uredi kategoriju donacije' : 'Dodaj kategoriju donacije')),
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
                label: 'Ključ ikone',
                required: true,
                errorText: _ikonaError,
                child: TextField(
                  controller: _ikonaController,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'npr. hrana'),
                ),
              ),
              const SizedBox(height: 12),
              LabeledField(
                label: 'Podrazumijevana jedinica mjere',
                required: false,
                child: DropdownButtonFormField<int?>(
                  initialValue: _podrazumijevanaJedinicaId,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Nije odabrano')),
                    for (final unit in widget.jediniceOptions)
                      DropdownMenuItem<int?>(value: unit.id, child: Text(unit.naziv)),
                  ],
                  onChanged: (value) => setState(() => _podrazumijevanaJedinicaId = value),
                ),
              ),
              const SizedBox(height: 12),
              Text('Dozvoljene jedinice mjere (prazno = sve dozvoljene)', style: Theme.of(context).textTheme.bodyMedium),
              Wrap(
                spacing: 8,
                children: [
                  for (final unit in widget.jediniceOptions)
                    FilterChip(
                      label: Text(unit.naziv),
                      selected: _selectedJedinice.contains(unit.id),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _selectedJedinice.add(unit.id);
                        } else {
                          _selectedJedinice.remove(unit.id);
                        }
                      }),
                    ),
                ],
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
