import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import 'package:dogshelter_shared/core/api_exception.dart';
import 'package:dogshelter_shared/core/paged_result.dart';
import 'package:dogshelter_shared/widgets/labeled_field.dart';
import '../../../core/app_theme.dart';
import '../../../core/paged_list_notifier.dart';
import '../../../widgets/debounced_search_field.dart';
import '../../../widgets/page_footer.dart';

class Rasa {
  const Rasa({required this.id, required this.naziv, required this.aktivan});

  final int id;
  final String naziv;
  final bool aktivan;

  factory Rasa.fromJson(Map<String, dynamic> json) {
    return Rasa(id: json['rasaId'] as int, naziv: json['naziv'] as String, aktivan: json['aktivan'] as bool);
  }
}

class RasaApi {
  RasaApi(this._client);
  final dynamic _client;

  Future<PagedResult<Rasa>> search({String? naziv, int page = 1}) async {
    final json = await _client.get('/api/Rasa', query: {
      if (naziv != null && naziv.isNotEmpty) 'Naziv': naziv,
      'Page': page,
      'PageSize': 100,
    });
    return PagedResult<Rasa>.fromJson(json as Map<String, dynamic>, Rasa.fromJson);
  }

  Future<void> create(String naziv, bool aktivan) =>
      _client.post('/api/Rasa', body: {'naziv': naziv, 'aktivan': aktivan});

  Future<void> update(int id, String naziv, bool aktivan) =>
      _client.put('/api/Rasa/$id', body: {'naziv': naziv, 'aktivan': aktivan});

  Future<void> delete(int id) => _client.delete('/api/Rasa/$id');
}

final rasaApiProvider = Provider<RasaApi>((ref) => RasaApi(ref.watch(apiClientProvider)));

class RasaListNotifier extends PagedListNotifier<Rasa> {
  RasaListNotifier(this._api);
  final RasaApi _api;

  @override
  Future<PagedResult<Rasa>> fetch({String? query, required int page}) => _api.search(naziv: query, page: page);

  Future<void> create(String naziv, bool aktivan) async {
    await _api.create(naziv, aktivan);
    await refresh();
  }

  Future<void> update(int id, String naziv, bool aktivan) async {
    await _api.update(id, naziv, aktivan);
    await refresh();
  }

  Future<void> remove(int id) async {
    await _api.delete(id);
    await refresh();
  }
}

final rasaListProvider = StateNotifierProvider<RasaListNotifier, AsyncValue<PagedResult<Rasa>>>((ref) {
  return RasaListNotifier(ref.watch(rasaApiProvider));
});

class RasaCrudScreen extends ConsumerStatefulWidget {
  const RasaCrudScreen({super.key});

  @override
  ConsumerState<RasaCrudScreen> createState() => _RasaCrudScreenState();
}

class _RasaCrudScreenState extends ConsumerState<RasaCrudScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm({Rasa? existing}) async {
    final result = await showDialog<(String, bool)>(
      context: context,
      builder: (context) => _RasaFormDialog(existing: existing),
    );
    if (result == null || !mounted) return;

    final notifier = ref.read(rasaListProvider.notifier);
    try {
      if (existing == null) {
        await notifier.create(result.$1, result.$2);
        _showMessage('Rasa je uspješno dodana.');
      } else {
        await notifier.update(existing.id, result.$1, result.$2);
        _showMessage('Rasa je uspješno izmijenjena.');
      }
    } catch (e) {
      _showMessage(e is ApiException ? e.allMessages.join('\n') : e.toString(), isError: true);
    }
  }

  Future<void> _confirmDelete(Rasa rasa) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content: Text('Da li ste sigurni da želite obrisati rasu "${rasa.naziv}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Obriši')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(rasaListProvider.notifier).remove(rasa.id);
      _showMessage('Rasa je obrisana.');
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
    final itemsAsync = ref.watch(rasaListProvider);

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
                    onChanged: (value) => ref.read(rasaListProvider.notifier).load(query: value),
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
                      final rasa = items[index];
                      return ListTile(
                        title: Text(rasa.naziv),
                        leading: Icon(
                          rasa.aktivan ? Icons.check_circle_outline : Icons.cancel_outlined,
                          color: rasa.aktivan ? Colors.green : Colors.grey,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Uredi',
                              onPressed: () => _openForm(existing: rasa),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Obriši',
                              onPressed: () => _confirmDelete(rasa),
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
              onPageChanged: (page) => ref.read(rasaListProvider.notifier).goToPage(page),
            ),
          ],
        ],
      ),
    );
  }
}

class _RasaFormDialog extends StatefulWidget {
  const _RasaFormDialog({this.existing});
  final Rasa? existing;

  @override
  State<_RasaFormDialog> createState() => _RasaFormDialogState();
}

class _RasaFormDialogState extends State<_RasaFormDialog> {
  late final _nazivController = TextEditingController(text: widget.existing?.naziv ?? '');
  late bool _aktivan = widget.existing?.aktivan ?? true;
  String? _nazivError;

  @override
  void dispose() {
    _nazivController.dispose();
    super.dispose();
  }

  void _submit() {
    final naziv = _nazivController.text.trim();
    if (naziv.isEmpty) {
      setState(() => _nazivError = 'Naziv je obavezan.');
      return;
    }
    Navigator.of(context).pop((naziv, _aktivan));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(isEdit ? 'Uredi rasu' : 'Dodaj rasu')),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop(), tooltip: 'Zatvori'),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Aktivna'),
              value: _aktivan,
              onChanged: (value) => setState(() => _aktivan = value ?? true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Odustani')),
        FilledButton(onPressed: _submit, child: const Text('Sačuvaj')),
      ],
    );
  }
}
