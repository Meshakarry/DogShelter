import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import 'package:dogshelter_shared/core/date_format.dart';
import 'package:dogshelter_shared/widgets/error_banner.dart';
import 'package:dogshelter_shared/widgets/labeled_field.dart';
import 'package:dogshelter_shared/widgets/status_pill.dart';
import '../../../widgets/monthly_bar_chart.dart';
import '../../../widgets/status_colors.dart';
import '../../../widgets/udomljavanje_report_content.dart';
import '../application/izvjestaji_providers.dart';
import '../data/izvjestaj_pdf_builder.dart';
import '../domain/report_models.dart';

const _cardBorderColor = Color(0xFFE5E7EB);

class IzvjestajiScreen extends ConsumerWidget {
  const IzvjestajiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          _FilterBar(),
          SizedBox(height: 20),
          _UdomljavanjeReportCard(),
          SizedBox(height: 20),
          _DonacijaReportCard(),
          SizedBox(height: 20),
          _AktivnostVolonteraReportCard(),
        ],
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(izvjestajFilterProvider);

    Future<void> pickDatumOd() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: filter.datumOd ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      );
      if (picked != null) {
        ref.read(izvjestajFilterProvider.notifier).state = filter.copyWith(datumOd: picked);
      }
    }

    Future<void> pickDatumDo() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: filter.datumDo ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      );
      if (picked != null) {
        ref.read(izvjestajFilterProvider.notifier).state = filter.copyWith(datumDo: picked);
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: LabeledField(
                label: 'Datum od',
                required: false,
                child: _DateField(
                  value: filter.datumOd,
                  hintText: 'Od početka',
                  onTap: pickDatumOd,
                  onClear: filter.datumOd == null
                      ? null
                      : () => ref.read(izvjestajFilterProvider.notifier).state = filter.copyWith(clearDatumOd: true),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: LabeledField(
                label: 'Datum do',
                required: false,
                child: _DateField(
                  value: filter.datumDo,
                  hintText: 'Do danas',
                  onTap: pickDatumDo,
                  onClear: filter.datumDo == null
                      ? null
                      : () => ref.read(izvjestajFilterProvider.notifier).state = filter.copyWith(clearDatumDo: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.hintText, required this.onTap, this.onClear});

  final DateTime? value;
  final String hintText;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          suffixIcon: onClear != null
              ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onClear)
              : const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          value == null ? hintText : formatDate(value!),
          style: value == null ? TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant) : null,
        ),
      ),
    );
  }
}

/// Shared card chrome + "Izvezi PDF"/"Ispis" toolbar for a single report section.
class _ReportCard extends StatefulWidget {
  const _ReportCard({
    required this.title,
    required this.subtitle,
    required this.buildPdfSections,
    required this.summaryLine,
    required this.pdfFileSlug,
    required this.child,
  });

  final String title;
  final String subtitle;
  final List<PdfReportSection> Function() buildPdfSections;
  final String Function() summaryLine;
  final String pdfFileSlug;
  final Widget child;

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _exporting = false;
  bool _printing = false;

  Future<Uint8List> _buildBytes(WidgetRef ref) {
    final filter = ref.read(izvjestajFilterProvider);
    return IzvjestajPdfBuilder.buildReportPdf(
      title: widget.title,
      datumOd: filter.datumOd,
      datumDo: filter.datumDo,
      sections: widget.buildPdfSections(),
      summaryLine: widget.summaryLine(),
    );
  }

  Future<void> _exportPdf(WidgetRef ref) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final bytes = await _buildBytes(ref);
      if (!mounted) return;
      final now = DateTime.now();
      String two(int v) => v.toString().padLeft(2, '0');
      final ts = '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}';
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Spremi PDF izvještaj',
        fileName: 'izvjestaj_${widget.pdfFileSlug}_$ts.pdf',
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (path == null || !mounted) return;
      final outPath = path.toLowerCase().endsWith('.pdf') ? path : '$path.pdf';
      await File(outPath).writeAsBytes(bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF je spremljen.')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška pri izvozu: $e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _printPdf(WidgetRef ref) async {
    if (_printing) return;
    setState(() => _printing = true);
    try {
      final bytes = await _buildBytes(ref);
      if (!mounted) return;
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška pri ispisu: $e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return Card(
          color: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _cardBorderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(widget.subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _exporting ? null : () => _exportPdf(ref),
                      icon: _exporting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: const Text('Izvezi PDF'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _printing ? null : () => _printPdf(ref),
                      icon: _printing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.print_outlined, size: 18),
                      label: const Text('Ispis'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                widget.child,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatNumber extends StatelessWidget {
  const _StatNumber({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
      ],
    );
  }
}

class _UdomljavanjeReportCard extends ConsumerWidget {
  const _UdomljavanjeReportCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(udomljavanjeIzvjestajProvider);

    return async.when(
      loading: () => const Card(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))),
      error: (error, _) => Card(child: Padding(padding: const EdgeInsets.all(20), child: ErrorBanner(error: error))),
      data: (data) => _ReportCard(
        title: 'Udomljavanja',
        subtitle: 'Broj udomljenih pasa po mjesecima i najčešće rase',
        pdfFileSlug: 'udomljavanja',
        buildPdfSections: () => [
          PdfReportSection(
            heading: 'Po mjesecima',
            columnHeaders: const ['Mjesec', 'Broj'],
            rows: [for (final m in data.poMjesecima) ['${m.mjesecNaziv} ${m.godina}', '${m.broj}']],
          ),
          PdfReportSection(
            heading: 'Najčešće rase',
            columnHeaders: const ['Rasa', 'Broj'],
            rows: [for (final r in data.najcescePoRasi) [r.rasa, '${r.broj}']],
          ),
        ],
        summaryLine: () => 'Ukupno udomljavanja: ${data.ukupno}',
        child: UdomljavanjeReportContent(data: data),
      ),
    );
  }
}

class _DonacijaReportCard extends ConsumerWidget {
  const _DonacijaReportCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(donacijaIzvjestajProvider);

    return async.when(
      loading: () => const Card(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))),
      error: (error, _) => Card(child: Padding(padding: const EdgeInsets.all(20), child: ErrorBanner(error: error))),
      data: (data) => _ReportCard(
        title: 'Donacije',
        subtitle: 'Novčane donacije po mjesecima i status svih donacija',
        pdfFileSlug: 'donacije',
        buildPdfSections: () => [
          PdfReportSection(
            heading: 'Novčane donacije po mjesecima',
            columnHeaders: const ['Mjesec', 'Broj', 'Iznos (BAM)'],
            rows: [
              for (final m in data.novcanePoMjesecima) ['${m.mjesecNaziv} ${m.godina}', '${m.broj}', m.iznos.toStringAsFixed(2)],
            ],
          ),
          PdfReportSection(
            heading: 'Novčane donacije po statusu',
            columnHeaders: const ['Status', 'Broj'],
            rows: [for (final s in data.novcanoPoStatusu) [s.status, '${s.broj}']],
          ),
          PdfReportSection(
            heading: 'Materijalne donacije po statusu',
            columnHeaders: const ['Status', 'Broj'],
            rows: [for (final s in data.materijalnoPoStatusu) [s.status, '${s.broj}']],
          ),
        ],
        summaryLine: () =>
            'Ukupno uspješnih novčanih donacija: ${data.ukupnoBrojNovcanih} · Ukupan iznos: ${data.ukupanIznos.toStringAsFixed(2)} BAM · Ukupno svih donacija: ${data.ukupnoSvih}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MonthlyBarChart(
              labels: [for (final m in data.novcanePoMjesecima) mjesecLabel(m.mjesecNaziv)],
              values: [for (final m in data.novcanePoMjesecima) m.iznos],
              color: const Color(0xFF2E7D5B),
              emptyMessage: 'Nema uspješnih novčanih donacija za odabrani period '
                  '(donacija na čekanju: potvrđuju se automatski putem Stripe plaćanja).',
            ),
            const SizedBox(height: 16),
            Text('Novčane po statusu', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _StatusPillRow(items: data.novcanoPoStatusu),
            const SizedBox(height: 16),
            Text('Materijalne po statusu', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _StatusPillRow(items: data.materijalnoPoStatusu),
            const SizedBox(height: 12),
            Text(
              'Ukupan iznos: ${data.ukupanIznos.toStringAsFixed(2)} BAM · Ukupno svih donacija: ${data.ukupnoSvih}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPillRow extends StatelessWidget {
  const _StatusPillRow({required this.items});

  final List<StatusBroj> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Text('Nema podataka.');
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final s in items)
          Builder(builder: (context) {
            final colors = donacijaStatusColors(s.status);
            return StatusPill(
              label: '${s.status} (${s.broj})',
              color: colors.background,
              foregroundColor: colors.foreground,
              borderRadius: statusPillRadius,
            );
          }),
      ],
    );
  }
}

class _AktivnostVolonteraReportCard extends ConsumerWidget {
  const _AktivnostVolonteraReportCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(aktivnostVolonteraIzvjestajProvider);

    return async.when(
      loading: () => const Card(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))),
      error: (error, _) => Card(child: Padding(padding: const EdgeInsets.all(20), child: ErrorBanner(error: error))),
      data: (data) => _ReportCard(
        title: 'Aktivnosti volontera',
        subtitle: 'Broj aktivnosti i ostvarenih sati po mjesecima',
        pdfFileSlug: 'aktivnosti_volontera',
        buildPdfSections: () => [
          PdfReportSection(
            heading: 'Po mjesecima',
            columnHeaders: const ['Mjesec', 'Broj aktivnosti', 'Sati'],
            rows: [
              for (final m in data.poMjesecima)
                ['${m.mjesecNaziv} ${m.godina}', '${m.brojAktivnosti}', m.ukupnoSati.toStringAsFixed(1)],
            ],
          ),
        ],
        summaryLine: () =>
            'Ukupno aktivnosti: ${data.ukupnoAktivnosti} · Ukupno sati: ${data.ukupnoSati.toStringAsFixed(1)}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatNumber(label: 'Ukupno aktivnosti', value: '${data.ukupnoAktivnosti}'),
                const SizedBox(width: 32),
                _StatNumber(label: 'Ukupno sati', value: data.ukupnoSati.toStringAsFixed(1)),
              ],
            ),
            const SizedBox(height: 16),
            MonthlyBarChart(
              labels: [for (final m in data.poMjesecima) mjesecLabel(m.mjesecNaziv)],
              values: [for (final m in data.poMjesecima) m.ukupnoSati],
              color: const Color(0xFF7C4DFF),
            ),
          ],
        ),
      ),
    );
  }
}
