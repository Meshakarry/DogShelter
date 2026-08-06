import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/core/api_exception.dart';
import 'package:dogshelter_shared/core/date_format.dart';
import 'package:dogshelter_shared/core/image_url.dart';
import 'package:dogshelter_shared/posjeta/domain/posjeta.dart';
import 'package:dogshelter_shared/widgets/error_banner.dart';
import 'package:dogshelter_shared/widgets/status_pill.dart';
import '../../../environment.dart';
import '../../../widgets/detail_row.dart';
import '../../../widgets/razlog_dialog.dart';
import '../../../widgets/status_colors.dart';
import '../application/posjete_providers.dart';

const _naCekanju = 'Na čekanju';
const _potvrdjena = 'Potvrđena';


/// Dedicated /posjete/:id page - image+name header, status pill, label/value rows, an
/// errorContainer callout for the cancellation reason, and potvrdi/otkazi/zavrsi actions.
class PosjetaDetailScreen extends ConsumerWidget {
  const PosjetaDetailScreen({super.key, required this.id});

  final int id;

  void _showMessage(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Theme.of(context).colorScheme.error : null),
    );
  }

  Future<void> _potvrdi(BuildContext context, WidgetRef ref, Posjeta posjeta) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrdi posjetu'),
        content: const Text('Da li želite potvrditi ovu posjetu?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Potvrdi')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(posjetaListProvider.notifier).potvrdi(posjeta.posjetaId);
      ref.invalidate(posjetaDetailProvider(id));
      if (context.mounted) _showMessage(context, 'Posjeta je potvrđena.');
    } catch (e) {
      if (context.mounted) _showMessage(context, describeApiError(e), isError: true);
    }
  }

  Future<void> _zavrsi(BuildContext context, WidgetRef ref, Posjeta posjeta) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Označi kao završenu'),
        content: const Text('Da li želite označiti ovu posjetu kao završenu?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Završi')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(posjetaListProvider.notifier).zavrsi(posjeta.posjetaId);
      ref.invalidate(posjetaDetailProvider(id));
      if (context.mounted) _showMessage(context, 'Posjeta je označena kao završena.');
    } catch (e) {
      if (context.mounted) _showMessage(context, describeApiError(e), isError: true);
    }
  }

  Future<void> _otkazi(BuildContext context, WidgetRef ref, Posjeta posjeta) async {
    final razlog = await showDialog<String>(
      context: context,
      builder: (context) => const RazlogDialog(title: 'Otkaži posjetu', label: 'Razlog otkazivanja'),
    );
    if (razlog == null) return;

    try {
      await ref.read(posjetaListProvider.notifier).otkazi(posjeta.posjetaId, razlog);
      ref.invalidate(posjetaDetailProvider(id));
      if (context.mounted) _showMessage(context, 'Posjeta je otkazana.');
    } catch (e) {
      if (context.mounted) _showMessage(context, describeApiError(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(posjetaDetailProvider(id));

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
                onPressed: () => context.go('/posjete'),
              ),
              Text('Detalji posjete', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
        Expanded(
          child: detailAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: ErrorBanner(error: error)),
            data: (posjeta) {
              final naziv = posjeta.statusPosjeteNaziv ?? '';
              final colors = posjetaStatusColors(naziv);
              final imageUrl = resolveImageUrl(posjeta.pasSlikaNaslovna, Environment.apiBaseUrl);

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
                                            child: Icon(
                                              posjeta.pasId == null ? Icons.event_outlined : Icons.pets,
                                              size: 32,
                                            ),
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
                                        '${posjeta.korisnikIme} ${posjeta.korisnikPrezime}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        posjeta.pasNaziv ?? 'Opća posjeta',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                StatusPill(
                                  label: naziv.isEmpty ? '-' : naziv,
                                  color: colors.background,
                                  foregroundColor: colors.foreground,
                                  borderRadius: statusPillRadius,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            DetailRow(label: 'Termin', value: formatDateTime(posjeta.datumVrijeme)),
                            DetailRow(label: 'Kreirano', value: formatDateTime(posjeta.datumKreiranja)),
                            DetailRow(label: 'Napomena', value: posjeta.napomena ?? '-'),
                            if (posjeta.datumObrade != null) ...[
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 12),
                              DetailRow(label: 'Obrađeno', value: formatDateTime(posjeta.datumObrade!)),
                              DetailRow(
                                label: 'Obradio',
                                value:
                                    '${posjeta.obradioKorisnikIme ?? ''} ${posjeta.obradioKorisnikPrezime ?? ''}'
                                        .trim(),
                              ),
                              if (posjeta.razlogOtkazivanja != null) ...[
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
                                        'Razlog otkazivanja',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onErrorContainer,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        posjeta.razlogOtkazivanja!,
                                        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                            const SizedBox(height: 28),
                            if (naziv != _naCekanju && naziv != _potvrdjena)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'Posjeta je već obrađena (status: $naziv) i ne može se dalje mijenjati.',
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
                                    onPressed: (naziv == _naCekanju || naziv == _potvrdjena)
                                        ? () => _otkazi(context, ref, posjeta)
                                        : null,
                                    icon: Icon(
                                      Icons.cancel_outlined,
                                      color: (naziv == _naCekanju || naziv == _potvrdjena)
                                          ? posjetaStatusColors('Otkazana').foreground
                                          : null,
                                    ),
                                    label: const Text('Otkaži'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: switch (naziv) {
                                      _naCekanju => () => _potvrdi(context, ref, posjeta),
                                      _potvrdjena => () => _zavrsi(context, ref, posjeta),
                                      _ => null,
                                    },
                                    icon: Icon(naziv == _potvrdjena ? Icons.flag_circle_outlined : Icons.check_circle_outline),
                                    label: Text(naziv == _potvrdjena ? 'Završi' : 'Potvrdi'),
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

