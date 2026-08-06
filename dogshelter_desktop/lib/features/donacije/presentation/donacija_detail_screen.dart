import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/core/api_exception.dart';
import 'package:dogshelter_shared/core/date_format.dart';
import 'package:dogshelter_shared/donacija/domain/donacija.dart';
import 'package:dogshelter_shared/widgets/error_banner.dart';
import 'package:dogshelter_shared/widgets/status_pill.dart';
import '../../../widgets/razlog_dialog.dart';
import '../../../widgets/status_colors.dart';
import '../application/donacije_providers.dart';

const _naCekanju = 'Na čekanju';
const _uspjesna = 'Uspješna';


/// Dedicated /donacije/:id page - same visual shape as ZahtjevDetailScreen/PosjetaDetailScreen
/// (Card, icon+name header, status pill, label/value rows, errorContainer callout for a
/// rejection/refund reason), plus in-kind pickup details when present.
class DonacijaDetailScreen extends ConsumerWidget {
  const DonacijaDetailScreen({super.key, required this.id});

  final int id;

  void _showMessage(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Theme.of(context).colorScheme.error : null),
    );
  }

  Future<void> _potvrdi(BuildContext context, WidgetRef ref, Donacija donacija) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrdi donaciju'),
        content: const Text('Da li želite potvrditi ovu materijalnu donaciju?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Potvrdi')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(donacijaListProvider.notifier).potvrdi(donacija.donacijaId);
      ref.invalidate(donacijaDetailProvider(id));
      if (context.mounted) _showMessage(context, 'Donacija je potvrđena.');
    } catch (e) {
      if (context.mounted) _showMessage(context, describeApiError(e), isError: true);
    }
  }

  Future<void> _odbij(BuildContext context, WidgetRef ref, Donacija donacija) async {
    final razlog = await showDialog<String>(
      context: context,
      builder: (context) => const RazlogDialog(title: 'Odbij donaciju', label: 'Razlog odbijanja'),
    );
    if (razlog == null) return;

    try {
      await ref.read(donacijaListProvider.notifier).odbij(donacija.donacijaId, razlog);
      ref.invalidate(donacijaDetailProvider(id));
      if (context.mounted) _showMessage(context, 'Donacija je odbijena.');
    } catch (e) {
      if (context.mounted) _showMessage(context, describeApiError(e), isError: true);
    }
  }

  Future<void> _refund(BuildContext context, WidgetRef ref, Donacija donacija) async {
    final razlog = await showDialog<String>(
      context: context,
      builder: (context) => const RazlogDialog(title: 'Vrati donaciju', label: 'Razlog vraćanja'),
    );
    if (razlog == null) return;

    try {
      await ref.read(donacijaListProvider.notifier).refund(donacija.donacijaId, razlog);
      ref.invalidate(donacijaDetailProvider(id));
      if (context.mounted) _showMessage(context, 'Donacija je vraćena.');
    } catch (e) {
      if (context.mounted) _showMessage(context, describeApiError(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(donacijaDetailProvider(id));

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
                onPressed: () => context.go('/donacije'),
              ),
              Text('Detalji donacije', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
        Expanded(
          child: detailAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: ErrorBanner(error: error)),
            data: (donacija) {
              final colors = donacijaStatusColors(donacija.statusDonacijeNaziv ?? '');
              final naziv = donacija.statusDonacijeNaziv;
              final isNovcana = donacija.isNovcana;
              final canPotvrdiOdbij = !isNovcana && naziv == _naCekanju;
              final canRefund = isNovcana && naziv == _uspjesna;

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
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                                  child: Icon(isNovcana ? Icons.payments_outlined : Icons.inventory_2_outlined),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${donacija.korisnikIme} ${donacija.korisnikPrezime}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        donacija.tipDonacijeNaziv ?? '-',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                StatusPill(
                                  label: naziv ?? '-',
                                  color: colors.background,
                                  foregroundColor: colors.foreground,
                                  borderRadius: statusPillRadius,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _DetailRow(label: 'Datum donacije', value: formatDate(donacija.datumDonacije)),
                            if (isNovcana)
                              _DetailRow(label: 'Iznos', value: '${donacija.iznos?.toStringAsFixed(2) ?? '-'} BAM')
                            else ...[
                              _DetailRow(label: 'Stavka', value: donacija.prikazNazivStavke ?? '-'),
                              _DetailRow(
                                label: 'Količina',
                                value: donacija.kolicina == null
                                    ? '-'
                                    : '${donacija.kolicina} ${donacija.jedinicaMjereNaziv ?? ''}'.trim(),
                              ),
                              _DetailRow(
                                label: 'Preuzimanje',
                                value: donacija.trebaPreuzimanje ? 'Potrebno preuzimanje' : 'Donator dostavlja sam',
                              ),
                              if (donacija.trebaPreuzimanje) ...[
                                _DetailRow(label: 'Adresa preuzimanja', value: donacija.adresaPreuzimanja ?? '-'),
                                _DetailRow(label: 'Telefon', value: donacija.telefonPreuzimanja ?? '-'),
                                _DetailRow(
                                  label: 'Željeni datum',
                                  value: donacija.zeljeniDatumDostave == null
                                      ? '-'
                                      : formatDate(donacija.zeljeniDatumDostave!),
                                ),
                              ],
                            ],
                            _DetailRow(label: 'Napomena', value: donacija.napomena ?? '-'),
                            if (donacija.datumObrade != null) ...[
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 12),
                              _DetailRow(label: 'Obrađeno', value: formatDate(donacija.datumObrade!)),
                              _DetailRow(
                                label: 'Obradio',
                                value:
                                    '${donacija.obradioKorisnikIme ?? ''} ${donacija.obradioKorisnikPrezime ?? ''}'
                                        .trim(),
                              ),
                            ],
                            if (donacija.razlogOdbijanja != null) ...[
                              const SizedBox(height: 12),
                              _ReasonCallout(label: 'Razlog odbijanja', text: donacija.razlogOdbijanja!),
                            ],
                            if (donacija.razlogVracanja != null) ...[
                              const SizedBox(height: 12),
                              _ReasonCallout(label: 'Razlog vraćanja', text: donacija.razlogVracanja!),
                            ],
                            const SizedBox(height: 28),
                            if (!canPotvrdiOdbij && !canRefund)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  isNovcana
                                      ? (naziv == _naCekanju
                                          ? 'Novčane donacije se obrađuju automatski putem Stripe-a.'
                                          : 'Donacija je već obrađena (status: $naziv).')
                                      : 'Donacija je već obrađena (status: $naziv) i ne može se ponovo mijenjati.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Theme.of(context).colorScheme.outline),
                                ),
                              ),
                            if (canPotvrdiOdbij)
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _odbij(context, ref, donacija),
                                      icon: Icon(Icons.cancel_outlined, color: donacijaStatusColors('Neuspješna').foreground),
                                      label: const Text('Odbij'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () => _potvrdi(context, ref, donacija),
                                      icon: const Icon(Icons.check_circle_outline),
                                      label: const Text('Potvrdi'),
                                    ),
                                  ),
                                ],
                              ),
                            if (canRefund)
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _refund(context, ref, donacija),
                                  icon: const Icon(Icons.replay_outlined),
                                  label: const Text('Vrati sredstva'),
                                ),
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

class _ReasonCallout extends StatelessWidget {
  const _ReasonCallout({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            label,
            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onErrorContainer),
          ),
          const SizedBox(height: 4),
          Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
        ],
      ),
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
