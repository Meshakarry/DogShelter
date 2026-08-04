import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/core/date_format.dart';
import 'package:dogshelter_shared/widgets/error_banner.dart';
import 'package:dogshelter_shared/widgets/status_pill.dart';
import '../../../core/app_theme.dart';
import '../../../widgets/status_colors.dart';
import '../../../widgets/udomljavanje_report_content.dart';
import '../../izvjestaji/domain/report_models.dart';
import '../application/pocetna_providers.dart';
import '../domain/pocetna_dashboard_data.dart';

class PocetnaScreen extends ConsumerWidget {
  const PocetnaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(pocetnaDashboardProvider);

    return dashboardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: ErrorBanner(error: error)),
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _StatCard(icon: Icons.pets_outlined, label: 'Ukupno pasa', value: data.ukupnoPasa),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child:
                        _StatCard(icon: Icons.favorite_outline, label: 'Dostupnih pasa', value: data.dostupnihPasa),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.assignment_late_outlined,
                      label: 'Zahtjeva na čekanju',
                      value: data.zahtjevaNaCekanju,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.event_available_outlined,
                      label: 'Današnje posjete',
                      value: data.danasnjePosjete,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _RecentZahtjeviCard(zahtjevi: data.nedavniZahtjevi)),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _UdomljavanjeChartCard(izvjestaj: data.udomljavanjeIzvjestaj),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.seedColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.seedColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(label, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentZahtjeviCard extends StatelessWidget {
  const _RecentZahtjeviCard({required this.zahtjevi});

  final List<ZahtjevSummary> zahtjevi;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nedavni zahtjevi za udomljavanje',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (zahtjevi.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('Nema podataka.')))
            else
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(1.5),
                  2: FlexColumnWidth(1.5),
                  3: FlexColumnWidth(1.5),
                },
                children: [
                  TableRow(
                    children: [
                      _headerCell('Korisnik'),
                      _headerCell('Pas'),
                      _headerCell('Datum'),
                      _headerCell('Status'),
                    ],
                  ),
                  for (final zahtjev in zahtjevi)
                    TableRow(
                      children: [
                        _bodyCell('${zahtjev.korisnikIme} ${zahtjev.korisnikPrezime}'),
                        _bodyCell(zahtjev.pasNaziv),
                        _bodyCell(formatDate(zahtjev.datumPodnosenja)),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Builder(builder: (context) {
                              final colors = zahtjevStatusColors(zahtjev.statusZahtjevaNaziv);
                              return StatusPill(
                                label: zahtjev.statusZahtjevaNaziv,
                                color: colors.background,
                                foregroundColor: colors.foreground,
                                borderRadius: statusPillRadius,
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      );

  Widget _bodyCell(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, overflow: TextOverflow.ellipsis),
      );
}

const _chartCardBorderColor = Color(0xFFE5E7EB);

class _UdomljavanjeChartCard extends StatelessWidget {
  const _UdomljavanjeChartCard({required this.izvjestaj});

  final UdomljavanjeIzvjestaj izvjestaj;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _chartCardBorderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Grafički pregled udomljavanja',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Udomljenja po mjesecima i najčešće rase',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 20),
            UdomljavanjeReportContent(data: izvjestaj),
          ],
        ),
      ),
    );
  }
}
