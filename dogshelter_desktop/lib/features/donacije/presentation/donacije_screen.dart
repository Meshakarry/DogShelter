import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/core/api_exception.dart';
import 'package:dogshelter_shared/core/date_format.dart';
import 'package:dogshelter_shared/donacija/domain/donacija.dart';
import 'package:dogshelter_shared/widgets/status_pill.dart';
import '../../../core/app_theme.dart';
import '../../../widgets/date_input_field.dart';
import '../../../widgets/page_footer.dart';
import '../../../widgets/razlog_dialog.dart';
import '../../../widgets/status_colors.dart';
import '../application/donacije_providers.dart';

const _naCekanju = 'Na čekanju';
const _uspjesna = 'Uspješna';


class DonacijeScreen extends ConsumerStatefulWidget {
  const DonacijeScreen({super.key});

  @override
  ConsumerState<DonacijeScreen> createState() => _DonacijeScreenState();
}

class _DonacijeScreenState extends ConsumerState<DonacijeScreen> {
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Theme.of(context).colorScheme.error : null),
    );
  }

  Future<void> _potvrdi(Donacija donacija) async {
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
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(donacijaListProvider.notifier).potvrdi(donacija.donacijaId);
      if (mounted) _showMessage('Donacija je potvrđena.');
    } catch (e) {
      if (mounted) _showMessage(describeApiError(e), isError: true);
    }
  }

  Future<void> _odbij(Donacija donacija) async {
    final razlog = await showDialog<String>(
      context: context,
      builder: (context) => const RazlogDialog(title: 'Odbij donaciju', label: 'Razlog odbijanja'),
    );
    if (razlog == null || !mounted) return;

    try {
      await ref.read(donacijaListProvider.notifier).odbij(donacija.donacijaId, razlog);
      if (mounted) _showMessage('Donacija je odbijena.');
    } catch (e) {
      if (mounted) _showMessage(describeApiError(e), isError: true);
    }
  }

  Future<void> _refund(Donacija donacija) async {
    final razlog = await showDialog<String>(
      context: context,
      builder: (context) => const RazlogDialog(title: 'Vrati donaciju', label: 'Razlog vraćanja'),
    );
    if (razlog == null || !mounted) return;

    try {
      await ref.read(donacijaListProvider.notifier).refund(donacija.donacijaId, razlog);
      if (mounted) _showMessage('Donacija je vraćena.');
    } catch (e) {
      if (mounted) _showMessage(describeApiError(e), isError: true);
    }
  }

  void _showDetail(Donacija donacija) {
    context.go('/donacije/${donacija.donacijaId}');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(donacijaListProvider);
    final tipOptionsAsync = ref.watch(tipDonacijeOptionsProvider);
    final statusOptionsAsync = ref.watch(statusDonacijeOptionsProvider);
    final notifier = ref.read(donacijaListProvider.notifier);

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
                  width: 180,
                  child: tipOptionsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => const SizedBox.shrink(),
                    data: (options) => DropdownButtonFormField<int?>(
                      initialValue: state.filters.tipDonacijeId,
                      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, hintText: 'Tip'),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Svi tipovi')),
                        for (final tip in options) DropdownMenuItem<int?>(value: tip.id, child: Text(tip.naziv)),
                      ],
                      onChanged: (value) => notifier.applyFilters(
                        state.filters.copyWith(tipDonacijeId: value, clearTipDonacijeId: value == null),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 200,
                  child: statusOptionsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => const SizedBox.shrink(),
                    data: (options) => DropdownButtonFormField<int?>(
                      initialValue: state.filters.statusDonacijeId,
                      decoration:
                          const InputDecoration(border: OutlineInputBorder(), isDense: true, hintText: 'Status'),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Svi statusi')),
                        for (final status in options) DropdownMenuItem<int?>(value: status.id, child: Text(status.naziv)),
                      ],
                      onChanged: (value) => notifier.applyFilters(
                        state.filters.copyWith(statusDonacijeId: value, clearStatusDonacijeId: value == null),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DateInputField(
                    value: state.filters.datumOd,
                    hintText: 'Datum od',
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: state.filters.datumOd ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        notifier.applyFilters(state.filters.copyWith(datumOd: picked));
                      }
                    },
                    onClear: state.filters.datumOd == null
                        ? null
                        : () => notifier.applyFilters(state.filters.copyWith(clearDatumOd: true)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DateInputField(
                    value: state.filters.datumDo,
                    hintText: 'Datum do',
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: state.filters.datumDo ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        notifier.applyFilters(state.filters.copyWith(datumDo: picked));
                      }
                    },
                    onClear: state.filters.datumDo == null
                        ? null
                        : () => notifier.applyFilters(state.filters.copyWith(clearDatumDo: true)),
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
                    ? Center(child: Text(describeApiError(state.error!)))
                    : state.items.isEmpty
                        ? const Center(child: Text('Nema donacija koje odgovaraju filterima.'))
                        : Card(
                            margin: EdgeInsets.zero,
                            child: ListView.separated(
                              itemCount: state.items.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final donacija = state.items[index];
                                final colors = donacijaStatusColors(donacija.statusDonacijeNaziv ?? '');
                                final naziv = donacija.statusDonacijeNaziv;
                                final isNovcana = donacija.isNovcana;
                                final canPotvrdiOdbij = !isNovcana && naziv == _naCekanju;
                                final canRefund = isNovcana && naziv == _uspjesna;
                                return ListTile(
                                  onTap: () => _showDetail(donacija),
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                                    child: Icon(isNovcana ? Icons.payments_outlined : Icons.inventory_2_outlined),
                                  ),
                                  title: Text('${donacija.korisnikIme} ${donacija.korisnikPrezime}'),
                                  subtitle: Text(
                                    '${isNovcana ? '${donacija.iznos?.toStringAsFixed(2) ?? '-'} BAM' : donacija.prikazNazivStavke ?? '-'} · '
                                    '${formatDate(donacija.datumDonacije)}',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      StatusPill(
                                        label: naziv ?? '-',
                                        color: colors.background,
                                        foregroundColor: colors.foreground,
                                        borderRadius: statusPillRadius,
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.check_circle_outline),
                                        tooltip: canPotvrdiOdbij
                                            ? 'Potvrdi'
                                            : isNovcana
                                                ? 'Novčane donacije se potvrđuju automatski putem Stripe-a.'
                                                : 'Donacija je već obrađena (status: $naziv) i ne može se ponovo potvrditi.',
                                        onPressed: canPotvrdiOdbij ? () => _potvrdi(donacija) : null,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.cancel_outlined),
                                        tooltip: canPotvrdiOdbij
                                            ? 'Odbij'
                                            : isNovcana
                                                ? 'Novčane donacije se ne odbijaju ručno.'
                                                : 'Donacija je već obrađena (status: $naziv) i ne može se odbiti.',
                                        onPressed: canPotvrdiOdbij ? () => _odbij(donacija) : null,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.replay_outlined),
                                        tooltip: canRefund
                                            ? 'Vrati sredstva'
                                            : isNovcana
                                                ? 'Vraćanje je moguće samo za uspješno naplaćene donacije.'
                                                : 'Vraćanje sredstava se odnosi samo na novčane donacije.',
                                        onPressed: canRefund ? () => _refund(donacija) : null,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.visibility_outlined),
                                        tooltip: 'Detalji',
                                        onPressed: () => _showDetail(donacija),
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
              onPageChanged: (page) => notifier.goToPage(page),
            ),
          ],
        ],
      ),
    );
  }
}
