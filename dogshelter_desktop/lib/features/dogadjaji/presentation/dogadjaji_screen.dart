import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/core/api_exception.dart';
import 'package:dogshelter_shared/core/date_format.dart';
import 'package:dogshelter_shared/core/image_url.dart';
import 'package:dogshelter_shared/dogadjaj/domain/dogadjaj.dart';
import 'package:dogshelter_shared/widgets/error_banner.dart';
import 'package:dogshelter_shared/widgets/status_pill.dart';
import '../../../core/app_theme.dart';
import '../../../environment.dart';
import '../../../widgets/date_input_field.dart';
import '../../../widgets/debounced_search_field.dart';
import '../../../widgets/page_footer.dart';
import '../../../widgets/status_colors.dart';
import '../application/dogadjaji_providers.dart';


class DogadjajiScreen extends ConsumerStatefulWidget {
  const DogadjajiScreen({super.key});

  @override
  ConsumerState<DogadjajiScreen> createState() => _DogadjajiScreenState();
}

class _DogadjajiScreenState extends ConsumerState<DogadjajiScreen> {
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

  Future<void> _otkazi(Dogadjaj dogadjaj) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Otkaži događaj'),
        content: Text('Da li želite otkazati događaj "${dogadjaj.naziv}"? Ova radnja se ne može poništiti.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Otkaži')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(dogadjajListProvider.notifier).otkazi(dogadjaj.dogadjajId);
      if (mounted) _showMessage('Događaj je otkazan.');
    } catch (e) {
      if (mounted) _showMessage(describeApiError(e), isError: true);
    }
  }

  Future<void> _pickDatumOd() async {
    final notifier = ref.read(dogadjajListProvider.notifier);
    final picked = await showDatePicker(
      context: context,
      initialDate: notifier.datumOd ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) notifier.applyFilters(datumOd: picked);
  }

  Future<void> _pickDatumDo() async {
    final notifier = ref.read(dogadjajListProvider.notifier);
    final picked = await showDatePicker(
      context: context,
      initialDate: notifier.datumDo ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) notifier.applyFilters(datumDo: picked);
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(dogadjajListProvider);
    final notifier = ref.read(dogadjajListProvider.notifier);

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
                    hintText: 'Pretraga po nazivu...',
                    onChanged: (value) => notifier.load(query: value),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<bool?>(
                    initialValue: notifier.aktivan,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, hintText: 'Status'),
                    items: const [
                      DropdownMenuItem<bool?>(value: null, child: Text('Svi')),
                      DropdownMenuItem<bool?>(value: true, child: Text('Aktivan')),
                      DropdownMenuItem<bool?>(value: false, child: Text('Otkazan')),
                    ],
                    onChanged: (value) => notifier.applyFilters(aktivan: value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DateInputField(
                    value: notifier.datumOd,
                    hintText: 'Datum od',
                    onTap: _pickDatumOd,
                    onClear: notifier.datumOd == null ? null : () => notifier.applyFilters(clearDatumOd: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DateInputField(
                    value: notifier.datumDo,
                    hintText: 'Datum do',
                    onTap: _pickDatumDo,
                    onClear: notifier.datumDo == null ? null : () => notifier.applyFilters(clearDatumDo: true),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  style: AppTheme.toolbarActionButtonStyle,
                  onPressed: () => context.go('/dogadjaji/novi'),
                  icon: const Icon(Icons.add),
                  label: const Text('Dodaj događaj'),
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
                if (items.isEmpty) return const Center(child: Text('Nema događaja koji odgovaraju filterima.'));
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final dogadjaj = items[index];
                      final colors = dogadjajStatusColors(dogadjaj.aktivan);
                      final imageUrl = resolveImageUrl(dogadjaj.slikaPutanja, Environment.apiBaseUrl);
                      return ListTile(
                        onTap: () => context.go('/dogadjaji/${dogadjaj.dogadjajId}'),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: imageUrl == null
                                ? Container(
                                    color: Theme.of(context).colorScheme.secondaryContainer,
                                    child: const Icon(Icons.event_outlined),
                                  )
                                : Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Theme.of(context).colorScheme.secondaryContainer,
                                      child: const Icon(Icons.event_outlined),
                                    ),
                                  ),
                          ),
                        ),
                        title: Text(dogadjaj.naziv),
                        subtitle: Text('${formatDateTime(dogadjaj.datum)} · ${dogadjaj.lokacija}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StatusPill(label: '${dogadjaj.brojZaduzenihVolontera} volontera'),
                            const SizedBox(width: 6),
                            StatusPill(
                              label: dogadjaj.aktivan ? 'Aktivan' : 'Otkazan',
                              color: colors.background,
                              foregroundColor: colors.foreground,
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Uredi',
                              onPressed: () => context.go('/dogadjaji/${dogadjaj.dogadjajId}'),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.cancel_outlined,
                                color: dogadjaj.aktivan ? dogadjajStatusColors(false).foreground : null,
                              ),
                              tooltip: dogadjaj.aktivan ? 'Otkaži' : 'Događaj je već otkazan.',
                              onPressed: dogadjaj.aktivan ? () => _otkazi(dogadjaj) : null,
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
