import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/core/api_exception.dart';
import 'package:dogshelter_shared/core/date_format.dart';
import 'package:dogshelter_shared/core/image_url.dart';
import 'package:dogshelter_shared/widgets/error_banner.dart';
import 'package:dogshelter_shared/widgets/status_pill.dart';
import 'package:dogshelter_shared/zahtjev_za_udomljavanje/domain/zahtjev_za_udomljavanje.dart';
import '../../../environment.dart';
import '../../../widgets/razlog_dialog.dart';
import '../../../widgets/status_colors.dart';
import '../application/zahtjevi_providers.dart';

const _naCekanju = 'Na čekanju';

String _describeError(Object error) => error is ApiException ? error.allMessages.join('\n') : error.toString();

/// Dedicated /zahtjevi/:id page - richer visual layout than the old AlertDialog-based
/// "Detalji" popup, matching mobile's zahtjev_detail_screen.dart section rhythm (image+name
/// header, status pill, label/value rows, errorContainer callout for a rejection reason) but
/// wrapped in a Card + desktop's own back-button+title header (no Scaffold/AppBar), per
/// psi_form_screen.dart's standalone-route convention.
class ZahtjevDetailScreen extends ConsumerWidget {
  const ZahtjevDetailScreen({super.key, required this.id});

  final int id;

  void _showMessage(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Theme.of(context).colorScheme.error : null),
    );
  }

  Future<void> _odobri(BuildContext context, WidgetRef ref, ZahtjevZaUdomljavanje zahtjev) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Odobri zahtjev'),
        content: Text(
          'Zahtjev za udomljavanje psa "${zahtjev.pasNaziv}" će biti odobren, a pas označen kao udomljen. Nastaviti?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Odobri')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(zahtjevListProvider.notifier).odobri(zahtjev.zahtjevZaUdomljavanjeId);
      ref.invalidate(zahtjevDetailProvider(id));
      if (context.mounted) _showMessage(context, 'Zahtjev je odobren.');
    } catch (e) {
      if (context.mounted) _showMessage(context, _describeError(e), isError: true);
    }
  }

  Future<void> _odbij(BuildContext context, WidgetRef ref, ZahtjevZaUdomljavanje zahtjev) async {
    final razlog = await showDialog<String>(
      context: context,
      builder: (context) => const RazlogDialog(title: 'Odbij zahtjev', label: 'Razlog odbijanja'),
    );
    if (razlog == null) return;

    try {
      await ref.read(zahtjevListProvider.notifier).odbij(zahtjev.zahtjevZaUdomljavanjeId, razlog);
      ref.invalidate(zahtjevDetailProvider(id));
      if (context.mounted) _showMessage(context, 'Zahtjev je odbijen.');
    } catch (e) {
      if (context.mounted) _showMessage(context, _describeError(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(zahtjevDetailProvider(id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 24, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Nazad',
                onPressed: () => context.go('/zahtjevi'),
              ),
              Text('Detalji zahtjeva', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
        Expanded(
          child: detailAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: ErrorBanner(error: error)),
            data: (zahtjev) {
              final colors = zahtjevStatusColors(zahtjev.statusZahtjevaNaziv ?? '');
              final isPending = zahtjev.statusZahtjevaNaziv == _naCekanju;
              final imageUrl = resolveImageUrl(zahtjev.pasSlikaNaslovna, Environment.apiBaseUrl);

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 84,
                                    height: 84,
                                    child: imageUrl == null
                                        ? Container(
                                            color: Theme.of(context).colorScheme.secondaryContainer,
                                            child: const Icon(Icons.pets, size: 32),
                                          )
                                        : Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: Theme.of(context).colorScheme.secondaryContainer,
                                              child: const Icon(Icons.pets, size: 32),
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        zahtjev.pasNaziv ?? '-',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${zahtjev.korisnikIme} ${zahtjev.korisnikPrezime}',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                StatusPill(
                                  label: zahtjev.statusZahtjevaNaziv ?? '-',
                                  color: colors.background,
                                  foregroundColor: colors.foreground,
                                  borderRadius: statusPillRadius,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _DetailRow(label: 'Podneseno', value: formatDate(zahtjev.datumPodnosenja)),
                            _DetailRow(label: 'Napomena', value: zahtjev.napomena ?? '-'),
                            if (zahtjev.datumObrade != null) ...[
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 12),
                              _DetailRow(label: 'Obrađeno', value: formatDate(zahtjev.datumObrade!)),
                              _DetailRow(
                                label: 'Obradio',
                                value:
                                    '${zahtjev.obradioKorisnikIme ?? ''} ${zahtjev.obradioKorisnikPrezime ?? ''}'
                                        .trim(),
                              ),
                              if (zahtjev.razlogOdbijanja != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        zahtjev.statusZahtjevaNaziv == 'Otkazan' ? 'Razlog otkazivanja' : 'Razlog odbijanja',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onErrorContainer,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        zahtjev.razlogOdbijanja!,
                                        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                            const SizedBox(height: 28),
                            if (!isPending)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'Zahtjev je već obrađen (status: ${zahtjev.statusZahtjevaNaziv}) i ne može se ponovo odobriti niti odbiti.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Theme.of(context).colorScheme.outline),
                                ),
                              ),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: isPending ? () => _odbij(context, ref, zahtjev) : null,
                                    icon: Icon(
                                      Icons.cancel_outlined,
                                      color: isPending ? zahtjevStatusColors('Odbijen').foreground : null,
                                    ),
                                    label: const Text('Odbij'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: isPending ? () => _odobri(context, ref, zahtjev) : null,
                                    icon: const Icon(Icons.check_circle_outline),
                                    label: const Text('Odobri'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 150, child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
