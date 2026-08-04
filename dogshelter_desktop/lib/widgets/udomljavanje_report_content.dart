import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../features/izvjestaji/domain/report_models.dart';
import 'monthly_bar_chart.dart';

/// Monthly adoption bar chart + top-breed breakdown + running total - the body shared by
/// the Izvještaji "Udomljavanja" report card (with PDF export/print) and Početna's dashboard
/// (plain, no export - just an at-a-glance summary), so both stay driven by one dataset/UI.
class UdomljavanjeReportContent extends StatelessWidget {
  const UdomljavanjeReportContent({super.key, required this.data});

  final UdomljavanjeIzvjestaj data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        MonthlyBarChart(
          labels: [for (final m in data.poMjesecima) mjesecLabel(m.mjesecNaziv)],
          values: [for (final m in data.poMjesecima) m.broj.toDouble()],
          color: AppTheme.seedColor,
        ),
        const SizedBox(height: 16),
        Text('Najčešće rase', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (data.najcescePoRasi.isEmpty)
          const Text('Nema podataka.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in data.najcescePoRasi.take(8))
                Chip(label: Text('${r.rasa} (${r.broj})'), backgroundColor: const Color(0xFFF3F4F6)),
            ],
          ),
        const SizedBox(height: 12),
        Text('Ukupno: ${data.ukupno}', style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
