import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/core/api_exception.dart';
import 'package:dogshelter_shared/core/date_format.dart';
import 'package:dogshelter_shared/core/image_url.dart';
import 'package:dogshelter_shared/widgets/error_banner.dart';
import 'package:dogshelter_shared/widgets/status_pill.dart';
import '../../../core/app_theme.dart';
import '../../../environment.dart';
import '../../../widgets/debounced_search_field.dart';
import '../../../widgets/page_footer.dart';
import '../../../widgets/status_colors.dart';
import '../application/obavijesti_providers.dart';


class ObavijestiScreen extends ConsumerStatefulWidget {
  const ObavijestiScreen({super.key});

  @override
  ConsumerState<ObavijestiScreen> createState() => _ObavijestiScreenState();
}

class _ObavijestiScreenState extends ConsumerState<ObavijestiScreen> {
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

  Future<void> _confirmDelete(int id, String naslov) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content: Text('Da li želite trajno obrisati obavijest "$naslov"?\n\nOva radnja je nepovratna.'),
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
      await ref.read(obavijestListProvider.notifier).remove(id);
      _showMessage('Obavijest je obrisana.');
    } catch (e) {
      _showMessage(describeApiError(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(obavijestListProvider);
    final notifier = ref.read(obavijestListProvider.notifier);

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
                    hintText: 'Pretraga po naslovu...',
                    onChanged: (value) => notifier.load(query: value),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<bool?>(
                    initialValue: notifier.aktivna,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, hintText: 'Status'),
                    items: const [
                      DropdownMenuItem<bool?>(value: null, child: Text('Sve')),
                      DropdownMenuItem<bool?>(value: true, child: Text('Objavljeno')),
                      DropdownMenuItem<bool?>(value: false, child: Text('Skica')),
                    ],
                    onChanged: (value) => notifier.filterByAktivna(value),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  style: AppTheme.toolbarActionButtonStyle,
                  onPressed: () => context.go('/obavijesti/novi'),
                  icon: const Icon(Icons.add),
                  label: const Text('Nova obavijest'),
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
                if (items.isEmpty) return const Center(child: Text('Nema obavijesti.'));
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final obavijest = items[index];
                      final imageUrl = resolveImageUrl(obavijest.slikaPutanja, Environment.apiBaseUrl);
                      final colors = obavijestStatusColors(obavijest.aktivna);
                      return ListTile(
                        onTap: () => context.go('/obavijesti/${obavijest.obavijestId}'),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: imageUrl == null
                                ? Container(
                                    color: Theme.of(context).colorScheme.secondaryContainer,
                                    child: const Icon(Icons.campaign_outlined),
                                  )
                                : Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Theme.of(context).colorScheme.secondaryContainer,
                                      child: const Icon(Icons.campaign_outlined),
                                    ),
                                  ),
                          ),
                        ),
                        title: Text(obavijest.naslov),
                        subtitle: Text(
                          '${obavijest.autorIme ?? ''} ${obavijest.autorPrezime ?? ''} · ${formatDate(obavijest.datumObjave)}'
                              .trim(),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StatusPill(
                              label: obavijest.aktivna ? 'Objavljeno' : 'Skica',
                              color: colors.background,
                              foregroundColor: colors.foreground,
                              borderRadius: statusPillRadius,
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Uredi',
                              onPressed: () => context.go('/obavijesti/${obavijest.obavijestId}'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Obriši',
                              onPressed: () => _confirmDelete(obavijest.obavijestId, obavijest.naslov),
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
