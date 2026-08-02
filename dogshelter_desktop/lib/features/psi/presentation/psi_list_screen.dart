import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/core/api_exception.dart';
import 'package:dogshelter_shared/core/image_url.dart';
import 'package:dogshelter_shared/pas/domain/pas_list_item.dart';
import 'package:dogshelter_shared/widgets/error_banner.dart';
import 'package:dogshelter_shared/widgets/status_pill.dart';
import '../../../core/app_theme.dart';
import '../../../environment.dart';
import '../../../widgets/debounced_search_field.dart';
import '../../../widgets/page_footer.dart';
import '../application/psi_providers.dart';

String _describeError(Object error) => error is ApiException ? error.allMessages.join('\n') : error.toString();

class PsiListScreen extends ConsumerStatefulWidget {
  const PsiListScreen({super.key});

  @override
  ConsumerState<PsiListScreen> createState() => _PsiListScreenState();
}

class _PsiListScreenState extends ConsumerState<PsiListScreen> {
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

  Future<void> _openCreateForm() async {
    final lookups = await ref.read(psiFormLookupsProvider.future);
    if (!mounted) return;

    final missing = [
      if (lookups.rase.isEmpty) 'rase',
      if (lookups.statusi.isEmpty) 'status psa',
      if (lookups.velicine.isEmpty) 'veličine psa',
    ];
    if (missing.isNotEmpty) {
      _showMessage(
        'Prije dodavanja psa morate u Postavke dodati barem jednu stavku za: ${missing.join(', ')}.',
        isError: true,
      );
      return;
    }

    if (mounted) context.go('/psi/novi');
  }

  Future<void> _confirmDelete(PasListItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content: Text('Da li ste sigurni da želite obrisati psa "${item.naziv}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Obriši')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(psiListProvider.notifier).remove(item.pasId);
      _showMessage('Pas je obrisan.');
    } catch (e) {
      _showMessage(_describeError(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(psiListProvider);
    final lookupsAsync = ref.watch(psiFormLookupsProvider);

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
                    hintText: 'Pretraga po nazivu psa...',
                    onChanged: (value) => ref.read(psiListProvider.notifier).applySearch(value),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  style: AppTheme.toolbarActionButtonStyle,
                  onPressed: _openCreateForm,
                  icon: const Icon(Icons.add),
                  label: const Text('Dodaj psa'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: AppTheme.toolbarActionHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: lookupsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => const SizedBox.shrink(),
                    data: (lookups) => DropdownButtonFormField<int>(
                      initialValue: state.filters.rasaId,
                      decoration:
                          const InputDecoration(border: OutlineInputBorder(), isDense: true, hintText: 'Rasa'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Sve rase')),
                        for (final rasa in lookups.rase) DropdownMenuItem(value: rasa.rasaId, child: Text(rasa.naziv)),
                      ],
                      onChanged: (value) => ref
                          .read(psiListProvider.notifier)
                          .applyFilters(state.filters.copyWith(rasaId: value, clearRasaId: value == null)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: lookupsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => const SizedBox.shrink(),
                    data: (lookups) => DropdownButtonFormField<int>(
                      initialValue: state.filters.statusPsaId,
                      decoration:
                          const InputDecoration(border: OutlineInputBorder(), isDense: true, hintText: 'Status'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Svi statusi')),
                        for (final status in lookups.statusi)
                          DropdownMenuItem(value: status.statusPsaId, child: Text(status.naziv)),
                      ],
                      onChanged: (value) => ref
                          .read(psiListProvider.notifier)
                          .applyFilters(state.filters.copyWith(statusPsaId: value, clearStatusPsaId: value == null)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: lookupsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => const SizedBox.shrink(),
                    data: (lookups) => DropdownButtonFormField<int>(
                      initialValue: state.filters.velicinaPsaId,
                      decoration:
                          const InputDecoration(border: OutlineInputBorder(), isDense: true, hintText: 'Veličina'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Sve veličine')),
                        for (final velicina in lookups.velicine)
                          DropdownMenuItem(value: velicina.velicinaPsaId, child: Text(velicina.naziv)),
                      ],
                      onChanged: (value) => ref
                          .read(psiListProvider.notifier)
                          .applyFilters(state.filters.copyWith(velicinaPsaId: value, clearVelicinaPsaId: value == null)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<bool?>(
                    initialValue: state.filters.aktivan,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    items: const [
                      DropdownMenuItem(value: true, child: Text('Aktivni')),
                      DropdownMenuItem(value: false, child: Text('Neaktivni')),
                      DropdownMenuItem(value: null, child: Text('Svi')),
                    ],
                    onChanged: (value) => ref
                        .read(psiListProvider.notifier)
                        .applyFilters(state.filters.copyWith(aktivan: value, clearAktivan: value == null)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: state.isLoading && state.items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.error != null && state.items.isEmpty
                    ? Center(child: ErrorBanner(error: state.error))
                    : state.items.isEmpty
                        ? const Center(child: Text('Nema pasa koji odgovaraju filterima.'))
                        : Card(
                            margin: EdgeInsets.zero,
                            child: ListView.separated(
                              itemCount: state.items.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final item = state.items[index];
                                final imageUrl = resolveImageUrl(item.slikaNaslovna, Environment.apiBaseUrl);
                                return ListTile(
                                  onTap: () => context.go('/psi/${item.pasId}'),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: imageUrl == null
                                          ? Container(
                                              color: Theme.of(context).colorScheme.secondaryContainer,
                                              child: const Icon(Icons.pets),
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
                                  title: Text(item.naziv),
                                  subtitle: Text(
                                    '${item.rasaNaziv ?? '-'} · ${item.statusNaziv ?? '-'} · ${item.velicinaNaziv ?? '-'}',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      StatusPill(
                                        label: item.aktivan ? 'Aktivan' : 'Neaktivan',
                                        color: item.aktivan
                                            ? Theme.of(context).colorScheme.secondaryContainer
                                            : Theme.of(context).colorScheme.errorContainer,
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        tooltip: 'Uredi',
                                        onPressed: () => context.go('/psi/${item.pasId}'),
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
                          ),
          ),
          if (state.totalCount > 0) ...[
            const SizedBox(height: 12),
            PageFooter(
              page: state.page,
              totalPages: state.totalPages,
              totalCount: state.totalCount,
              onPageChanged: (page) => ref.read(psiListProvider.notifier).goToPage(page),
            ),
          ],
        ],
      ),
    );
  }
}
