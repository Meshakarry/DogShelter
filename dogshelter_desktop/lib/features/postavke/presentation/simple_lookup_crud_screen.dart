import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/core/api_exception.dart';
import 'package:dogshelter_shared/widgets/error_banner.dart';
import 'package:dogshelter_shared/widgets/labeled_field.dart';
import '../../../core/app_theme.dart';
import '../application/lookup_providers.dart';
import '../domain/lookup_item.dart';
import '../../../widgets/debounced_search_field.dart';
import '../../../widgets/page_footer.dart';

String _describeError(Object error) => error is ApiException ? error.allMessages.join('\n') : error.toString();

/// Reusable CRUD screen for any lookup table shaped as `{id, naziv}` - covers every
/// Postavke table whose backend controller uses the generic LookupSearchRequest/
class SimpleLookupCrudScreen extends ConsumerStatefulWidget {
  const SimpleLookupCrudScreen({super.key, required this.config});

  final LookupTableConfig config;

  @override
  ConsumerState<SimpleLookupCrudScreen> createState() => _SimpleLookupCrudScreenState();
}

class _SimpleLookupCrudScreenState extends ConsumerState<SimpleLookupCrudScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm({LookupItem? existing}) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _LookupFormDialog(title: widget.config.label, existing: existing),
    );
    if (result == null || !mounted) return;

    final notifier = ref.read(lookupListProvider(widget.config).notifier);
    try {
      if (existing == null) {
        await notifier.create(result);
        _showMessage('Stavka je uspješno dodana.');
      } else {
        await notifier.update(existing.id, result);
        _showMessage('Stavka je uspješno izmijenjena.');
      }
    } catch (e) {
      _showMessage(_describeError(e), isError: true);
    }
  }

  Future<void> _confirmDelete(LookupItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content: Text('Da li ste sigurni da želite obrisati "${item.naziv}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Obriši')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(lookupListProvider(widget.config).notifier).remove(item.id);
      _showMessage('Stavka je obrisana.');
    } catch (e) {
      _showMessage(_describeError(e), isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(lookupListProvider(widget.config));

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
                    onChanged: (value) => ref.read(lookupListProvider(widget.config).notifier).load(query: value),
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
              error: (error, _) => Center(child: ErrorBanner(error: error)),
              data: (result) {
                final items = result.items;
                if (items.isEmpty) {
                  return const Center(child: Text('Nema podataka.'));
                }
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        title: Text(item.naziv),
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
              onPageChanged: (page) => ref.read(lookupListProvider(widget.config).notifier).goToPage(page),
            ),
          ],
        ],
      ),
    );
  }
}

class _LookupFormDialog extends StatefulWidget {
  const _LookupFormDialog({required this.title, this.existing});

  final String title;
  final LookupItem? existing;

  @override
  State<_LookupFormDialog> createState() => _LookupFormDialogState();
}

class _LookupFormDialogState extends State<_LookupFormDialog> {
  late final _nazivController = TextEditingController(text: widget.existing?.naziv ?? '');
  String? _error;

  @override
  void dispose() {
    _nazivController.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _nazivController.text.trim();
    if (value.isEmpty) {
      setState(() => _error = 'Naziv je obavezan.');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(isEdit ? 'Uredi - ${widget.title}' : 'Dodaj - ${widget.title}')),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Zatvori',
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: LabeledField(
          label: 'Naziv',
          errorText: _error,
          child: TextField(
            controller: _nazivController,
            autofocus: true,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(border: OutlineInputBorder()),
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
