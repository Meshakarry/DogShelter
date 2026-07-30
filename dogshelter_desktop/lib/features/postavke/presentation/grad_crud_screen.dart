import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import 'package:dogshelter_shared/core/api_exception.dart';
import 'package:dogshelter_shared/core/paged_result.dart';
import 'package:dogshelter_shared/widgets/labeled_field.dart';
import '../../../core/app_theme.dart';
import '../../../widgets/debounced_search_field.dart';

class Grad {
  const Grad({required this.id, required this.naziv, required this.postanskiBroj});

  final int id;
  final String naziv;
  final String postanskiBroj;

  factory Grad.fromJson(Map<String, dynamic> json) {
    return Grad(id: json['gradId'] as int, naziv: json['naziv'] as String, postanskiBroj: json['postanskiBroj'] as String);
  }
}

class GradApi {
  GradApi(this._client);
  final dynamic _client;

  Future<PagedResult<Grad>> search({String? naziv}) async {
    final json = await _client.get('/api/Grad', query: {
      if (naziv != null && naziv.isNotEmpty) 'Naziv': naziv,
      'Page': 1,
      'PageSize': 100,
    });
    return PagedResult<Grad>.fromJson(json as Map<String, dynamic>, Grad.fromJson);
  }

  Future<void> create(String naziv, String postanskiBroj) =>
      _client.post('/api/Grad', body: {'naziv': naziv, 'postanskiBroj': postanskiBroj});

  Future<void> update(int id, String naziv, String postanskiBroj) =>
      _client.put('/api/Grad/$id', body: {'naziv': naziv, 'postanskiBroj': postanskiBroj});

  Future<void> delete(int id) => _client.delete('/api/Grad/$id');
}

final gradApiProvider = Provider<GradApi>((ref) => GradApi(ref.watch(apiClientProvider)));

class GradListNotifier extends StateNotifier<AsyncValue<List<Grad>>> {
  GradListNotifier(this._api) : super(const AsyncValue.loading()) {
    load();
  }
  final GradApi _api;
  String? _naziv;

  Future<void> load({String? naziv}) async {
    _naziv = naziv ?? _naziv;
    if (!state.hasValue) {
      state = const AsyncValue.loading();
    }
    state = await AsyncValue.guard(() async => (await _api.search(naziv: _naziv)).items);
  }

  Future<void> create(String naziv, String postanskiBroj) async {
    await _api.create(naziv, postanskiBroj);
    await load();
  }

  Future<void> update(int id, String naziv, String postanskiBroj) async {
    await _api.update(id, naziv, postanskiBroj);
    await load();
  }

  Future<void> remove(int id) async {
    await _api.delete(id);
    await load();
  }
}

final gradListProvider = StateNotifierProvider<GradListNotifier, AsyncValue<List<Grad>>>((ref) {
  return GradListNotifier(ref.watch(gradApiProvider));
});

class GradCrudScreen extends ConsumerStatefulWidget {
  const GradCrudScreen({super.key});

  @override
  ConsumerState<GradCrudScreen> createState() => _GradCrudScreenState();
}

class _GradCrudScreenState extends ConsumerState<GradCrudScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm({Grad? existing}) async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (context) => _GradFormDialog(existing: existing),
    );
    if (result == null || !mounted) return;

    final notifier = ref.read(gradListProvider.notifier);
    try {
      if (existing == null) {
        await notifier.create(result.$1, result.$2);
        _showMessage('Grad je uspješno dodan.');
      } else {
        await notifier.update(existing.id, result.$1, result.$2);
        _showMessage('Grad je uspješno izmijenjen.');
      }
    } catch (e) {
      _showMessage(e is ApiException ? e.allMessages.join('\n') : e.toString(), isError: true);
    }
  }

  Future<void> _confirmDelete(Grad grad) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content: Text('Da li ste sigurni da želite obrisati grad "${grad.naziv}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Obriši')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(gradListProvider.notifier).remove(grad.id);
      _showMessage('Grad je obrisan.');
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
    final itemsAsync = ref.watch(gradListProvider);

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
                    onChanged: (value) => ref.read(gradListProvider.notifier).load(naziv: value),
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
                      final grad = items[index];
                      return ListTile(
                        title: Text(grad.naziv),
                        subtitle: Text('Poštanski broj: ${grad.postanskiBroj}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Uredi',
                              onPressed: () => _openForm(existing: grad),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Obriši',
                              onPressed: () => _confirmDelete(grad),
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

class _GradFormDialog extends StatefulWidget {
  const _GradFormDialog({this.existing});
  final Grad? existing;

  @override
  State<_GradFormDialog> createState() => _GradFormDialogState();
}

class _GradFormDialogState extends State<_GradFormDialog> {
  late final _nazivController = TextEditingController(text: widget.existing?.naziv ?? '');
  late final _postanskiBrojController = TextEditingController(text: widget.existing?.postanskiBroj ?? '');
  String? _nazivError;
  String? _postanskiBrojError;

  @override
  void dispose() {
    _nazivController.dispose();
    _postanskiBrojController.dispose();
    super.dispose();
  }

  void _submit() {
    final naziv = _nazivController.text.trim();
    final postanskiBroj = _postanskiBrojController.text.trim();
    setState(() {
      _nazivError = naziv.isEmpty ? 'Naziv je obavezan.' : null;
      _postanskiBrojError = postanskiBroj.isEmpty ? 'Poštanski broj je obavezan.' : null;
    });
    if (_nazivError != null || _postanskiBrojError != null) return;
    Navigator.of(context).pop((naziv, postanskiBroj));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(isEdit ? 'Uredi grad' : 'Dodaj grad')),
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
            LabeledField(
              label: 'Poštanski broj',
              errorText: _postanskiBrojError,
              child: TextField(
                controller: _postanskiBrojController,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
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
