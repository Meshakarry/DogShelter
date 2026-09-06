import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/core/api_exception.dart';
import 'package:dogshelter_shared/core/date_format.dart';
import 'package:dogshelter_shared/core/image_url.dart';
import 'package:dogshelter_shared/widgets/status_pill.dart';
import 'package:dogshelter_shared/zahtjev_za_udomljavanje/domain/zahtjev_za_udomljavanje.dart';
import '../../../core/app_theme.dart';
import '../../../environment.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/page_footer.dart';
import '../../../widgets/razlog_dialog.dart';
import '../../../widgets/status_colors.dart';
import '../application/zahtjevi_providers.dart';

const _naCekanju = 'Na čekanju';
const _odobren = 'Odobren';


class ZahtjeviScreen extends ConsumerWidget {
  const ZahtjeviScreen({super.key});

  void _showMessage(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Theme.of(context).colorScheme.error : null),
    );
  }

  Future<void> _odobri(BuildContext context, WidgetRef ref, ZahtjevZaUdomljavanje zahtjev) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Odobri zahtjev',
      message:
          'Zahtjev za udomljavanje psa "${zahtjev.pasNaziv}" će biti odobren, a pas rezervisan za ovog korisnika. Udomljenje se finalizira posebnim korakom kada bude spremno. Nastaviti?',
      confirmLabel: 'Odobri',
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(zahtjevListProvider.notifier).odobri(zahtjev.zahtjevZaUdomljavanjeId);
      if (context.mounted) _showMessage(context, 'Zahtjev je odobren.');
    } catch (e) {
      if (context.mounted) _showMessage(context, describeApiError(e), isError: true);
    }
  }

  Future<void> _odbij(BuildContext context, WidgetRef ref, ZahtjevZaUdomljavanje zahtjev) async {
    final razlog = await showDialog<String>(
      context: context,
      builder: (context) => const RazlogDialog(title: 'Odbij zahtjev', label: 'Razlog odbijanja'),
    );
    if (razlog == null || !context.mounted) return;

    try {
      await ref.read(zahtjevListProvider.notifier).odbij(zahtjev.zahtjevZaUdomljavanjeId, razlog);
      if (context.mounted) _showMessage(context, 'Zahtjev je odbijen.');
    } catch (e) {
      if (context.mounted) _showMessage(context, describeApiError(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(zahtjevListProvider);
    final statusOptionsAsync = ref.watch(statusZahtjevaOptionsProvider);
    final notifier = ref.read(zahtjevListProvider.notifier);

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
                SizedBox(
                  width: 240,
                  child: statusOptionsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => const SizedBox.shrink(),
                    data: (options) => DropdownButtonFormField<int?>(
                      initialValue: notifier.statusZahtjevaId,
                      decoration:
                          const InputDecoration(border: OutlineInputBorder(), isDense: true, hintText: 'Status'),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Svi')),
                        for (final status in options) DropdownMenuItem<int?>(value: status.id, child: Text(status.naziv)),
                      ],
                      onChanged: (value) => notifier.filterByStatus(value),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(describeApiError(error))),
              data: (result) {
                final items = result.items;
                if (items.isEmpty) return const Center(child: Text('Nema zahtjeva za udomljavanje.'));
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final zahtjev = items[index];
                      final imageUrl = resolveImageUrl(zahtjev.pasSlikaNaslovna, Environment.apiBaseUrl);
                      final colors = zahtjevStatusColors(zahtjev.statusZahtjevaNaziv ?? '');
                      final isPending = zahtjev.statusZahtjevaNaziv == _naCekanju;
                      // The dog may have stopped being adoptable since this request was
                      // submitted (deactivated, or reserved/adopted via a different request in
                      // the meantime) - Odobri() re-checks this server-side regardless, but
                      // disabling it here avoids a round-trip error for the obvious case.
                      final pasOk = zahtjev.pasAktivan && zahtjev.pasStatusNaziv == 'Dostupan';
                      final canApprove = isPending && pasOk;
                      return ListTile(
                        onTap: () => context.go('/zahtjevi/${zahtjev.zahtjevZaUdomljavanjeId}'),
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
                        title: Text('${zahtjev.pasNaziv} — ${zahtjev.korisnikIme} ${zahtjev.korisnikPrezime}'),
                        subtitle: Text('Podneseno: ${formatDate(zahtjev.datumPodnosenja)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StatusPill(
                              label: zahtjev.statusZahtjevaNaziv ?? '-',
                              color: colors.background,
                              foregroundColor: colors.foreground,
                              borderRadius: statusPillRadius,
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                Icons.check_circle_outline,
                                color: canApprove ? zahtjevStatusColors('Odobren').foreground : null,
                              ),
                              tooltip: !isPending
                                  ? (zahtjev.statusZahtjevaNaziv == _odobren
                                      ? 'Zahtjev je odobren i pas je rezervisan. Otvorite detalje da finalizirate udomljenje.'
                                      : 'Zahtjev je već obrađen (status: ${zahtjev.statusZahtjevaNaziv}) i ne može se ponovo odobriti.')
                                  : !pasOk
                                      ? 'Pas "${zahtjev.pasNaziv}" trenutno nije dostupan (status: ${zahtjev.pasStatusNaziv ?? "nepoznat"}) i zahtjev se ne može odobriti.'
                                      : 'Odobri',
                              onPressed: canApprove ? () => _odobri(context, ref, zahtjev) : null,
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.cancel_outlined,
                                color: isPending ? zahtjevStatusColors('Odbijen').foreground : null,
                              ),
                              tooltip: isPending
                                  ? 'Odbij'
                                  : 'Zahtjev je već obrađen (status: ${zahtjev.statusZahtjevaNaziv}) i ne može se ponovo odbiti.',
                              onPressed: isPending ? () => _odbij(context, ref, zahtjev) : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined),
                              tooltip: 'Detalji',
                              onPressed: () => context.go('/zahtjevi/${zahtjev.zahtjevZaUdomljavanjeId}'),
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
