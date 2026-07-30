import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/core/date_format.dart';
import 'package:dogshelter_shared/widgets/error_banner.dart';
import 'package:dogshelter_shared/widgets/status_pill.dart';
import '../../../core/app_theme.dart';
import '../application/pocetna_providers.dart';
import '../domain/pocetna_dashboard_data.dart';

const _statusPillRadius = 6.0;

({Color background, Color foreground}) _statusColors(String naziv) {
  switch (naziv) {
    case 'Odobren':
      return (background: const Color(0xFFDFF3E6), foreground: const Color(0xFF1E7D42));
    case 'Odbijen':
      return (background: const Color(0xFFFBE1E1), foreground: const Color(0xFFB3261E));
    default:
      return (background: const Color(0xFFFDEBD0), foreground: const Color(0xFFB4690E));
  }
}

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
            SizedBox(
              height: 460,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _RecentZahtjeviCard(zahtjevi: data.nedavniZahtjevi)),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _UdomljavanjeChartCard(poMjesecima: data.udomljavanjaPoMjesecima),
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
                              final colors = _statusColors(zahtjev.statusZahtjevaNaziv);
                              return StatusPill(
                                label: zahtjev.statusZahtjevaNaziv,
                                color: colors.background,
                                foregroundColor: colors.foreground,
                                borderRadius: _statusPillRadius,
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
const _chartHeight = 250.0;
const _chartBarWidth = 20.0;

double _computeChartMaxY(int maxValue) {
  const minimum = 20;

  if (maxValue <= minimum) {
    return minimum.toDouble();
  }

  return ((maxValue / 5).ceil() * 5).toDouble();
}

class _UdomljavanjeChartCard extends StatelessWidget {
  const _UdomljavanjeChartCard({required this.poMjesecima});

  final List<MjesecBroj> poMjesecima;

  @override
  Widget build(BuildContext context) {
    final maxBroj = poMjesecima.fold<int>(0, (max, item) => item.broj > max ? item.broj : max);
    final maxY = _computeChartMaxY(maxBroj);

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
              'Udomljenja u posljednjih 7 mjeseci',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: _chartHeight,
                  child: poMjesecima.isEmpty
                      ? const Center(child: Text('Nema podataka.'))
                      : Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: maxY,
                              minY: 0,
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 5,
                                checkToShowHorizontalLine: (value) => value % 5 == 0,
                                getDrawingHorizontalLine: (value) {
                                  return const FlLine(
                                    color: Color(0xFFE5E7EB),
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              borderData: FlBorderData(show: false),
                              barTouchData: BarTouchData(enabled: false),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 5,
                                    reservedSize: 32,
                                    getTitlesWidget: (value, meta) {
                                      if (value % 5 != 0) {
                                        return const SizedBox.shrink();
                                      }

                                      return Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index < 0 || index >= poMjesecima.length) return const SizedBox.shrink();
                                      final naziv = poMjesecima[index].mjesecNaziv;
                                      final abbrev = naziv.length > 3 ? naziv.substring(0, 3) : naziv;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          abbrev,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              barGroups: [
                                for (var i = 0; i < poMjesecima.length; i++)
                                  BarChartGroupData(
                                    x: i,
                                    barRods: [
                                      BarChartRodData(
                                        toY: poMjesecima[i].broj.toDouble(),
                                        width: _chartBarWidth,
                                        color: AppTheme.seedColor,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
