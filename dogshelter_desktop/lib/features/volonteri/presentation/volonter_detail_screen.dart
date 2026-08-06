import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/aktivnost_volontera/domain/aktivnost_volontera.dart';
import 'package:dogshelter_shared/core/api_exception.dart';
import 'package:dogshelter_shared/core/date_format.dart';
import 'package:dogshelter_shared/volonter/domain/volonter.dart';
import 'package:dogshelter_shared/widgets/error_banner.dart';
import 'package:dogshelter_shared/widgets/labeled_field.dart';
import 'package:dogshelter_shared/widgets/status_pill.dart';
import '../../../widgets/detail_row.dart';
import '../../../widgets/page_footer.dart';
import '../../../widgets/status_colors.dart';
import '../application/volonteri_providers.dart';


/// Dedicated /volonteri/:id page - profile header, activity logging + list, and a read-only
/// roster of assigned events (assignment itself only happens from the Događaji side).
class VolonterDetailScreen extends ConsumerWidget {
  const VolonterDetailScreen({super.key, required this.id});

  final int id;

  void _showMessage(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Theme.of(context).colorScheme.error : null),
    );
  }

  Future<void> _logAktivnost(BuildContext context, WidgetRef ref) async {
    final data = await showDialog<_LogAktivnostResult>(
      context: context,
      builder: (context) => const _LogAktivnostDialog(),
    );
    if (data == null) return;

    try {
      await ref.read(volonterAktivnostiProvider(id).notifier).log(
            tipAktivnostiId: data.tipAktivnostiId,
            datumAktivnosti: data.datumAktivnosti,
            brojSati: data.brojSati,
            opis: data.opis,
          );
      ref.invalidate(volonterDetailProvider(id));
      if (context.mounted) _showMessage(context, 'Aktivnost je zabilježena.');
    } catch (e) {
      if (context.mounted) _showMessage(context, describeApiError(e), isError: true);
    }
  }

  Future<void> _removeAktivnost(BuildContext context, WidgetRef ref, AktivnostVolontera aktivnost) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content: const Text('Da li želite obrisati ovu aktivnost?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Obriši')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(volonterAktivnostiProvider(id).notifier).remove(aktivnost.aktivnostVolonteraId);
      ref.invalidate(volonterDetailProvider(id));
      if (context.mounted) _showMessage(context, 'Aktivnost je obrisana.');
    } catch (e) {
      if (context.mounted) _showMessage(context, describeApiError(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(volonterDetailProvider(id));

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
                onPressed: () => context.go('/volonteri'),
              ),
              Text('Profil volontera', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
        Expanded(
          child: detailAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: ErrorBanner(error: error)),
            data: (volonter) => SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProfileCard(volonter: volonter),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Text('Aktivnosti', style: Theme.of(context).textTheme.titleMedium),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: () => _logAktivnost(context, ref),
                            icon: const Icon(Icons.add),
                            label: const Text('Zabilježi aktivnost'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _AktivnostiSection(
                        volonterId: id,
                        onRemove: (aktivnost) => _removeAktivnost(context, ref, aktivnost),
                      ),
                      const SizedBox(height: 24),
                      Text('Dodijeljeni događaji', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _DodijeljeniDogadjajiSection(volonterId: id),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.volonter});

  final Volonter volonter;

  @override
  Widget build(BuildContext context) {
    final colors = volonterStatusColors(volonter.aktivan);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${volonter.korisnikIme ?? ''} ${volonter.korisnikPrezime ?? ''}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                StatusPill(
                  label: volonter.aktivan ? 'Aktivan' : 'Neaktivan',
                  color: colors.background,
                  foregroundColor: colors.foreground,
                ),
              ],
            ),
            const SizedBox(height: 16),
            DetailRow(label: 'Email', value: volonter.korisnikEmail ?? '-', labelWidth: 170),
            DetailRow(label: 'Telefon', value: volonter.korisnikTelefon ?? '-', labelWidth: 170),
            DetailRow(label: 'Datum pridruživanja', value: formatDate(volonter.datumPridruzivanja), labelWidth: 170),
            DetailRow(label: 'Ukupno sati', value: volonter.ukupnoSati.toStringAsFixed(1), labelWidth: 170),
            if (volonter.napomena != null && volonter.napomena!.isNotEmpty)
              DetailRow(label: 'Napomena', value: volonter.napomena!, labelWidth: 170),
          ],
        ),
      ),
    );
  }
}


class _AktivnostiSection extends ConsumerWidget {
  const _AktivnostiSection({required this.volonterId, required this.onRemove});

  final int volonterId;
  final ValueChanged<AktivnostVolontera> onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(volonterAktivnostiProvider(volonterId));
    final notifier = ref.read(volonterAktivnostiProvider(volonterId).notifier);

    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorBanner(error: error),
      data: (result) {
        if (result.items.isEmpty) return const Text('Nema zabilježenih aktivnosti.');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: result.items.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final aktivnost = result.items[index];
                  return ListTile(
                    title: Text(aktivnost.tipAktivnostiNaziv ?? '-'),
                    subtitle: Text(
                      '${formatDate(aktivnost.datumAktivnosti)}'
                      '${aktivnost.opis != null && aktivnost.opis!.isNotEmpty ? ' · ${aktivnost.opis}' : ''}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatusPill(label: '${aktivnost.brojSati.toStringAsFixed(1)} h'),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Obriši',
                          onPressed: () => onRemove(aktivnost),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (result.totalCount > 0) ...[
              const SizedBox(height: 12),
              PageFooter(
                page: result.page,
                totalPages: result.totalPages,
                totalCount: result.totalCount,
                onPageChanged: (page) => notifier.goToPage(page),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _DodijeljeniDogadjajiSection extends ConsumerWidget {
  const _DodijeljeniDogadjajiSection({required this.volonterId});

  final int volonterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(volonterDodijeljeniDogadjajiProvider(volonterId));

    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorBanner(error: error),
      data: (items) {
        if (items.isEmpty) return const Text('Volonter trenutno nije dodijeljen ni jednom događaju.');
        return Card(
          margin: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final zaduzenje = items[index];
              return ListTile(
                leading: const Icon(Icons.event_outlined),
                title: Text(zaduzenje.dogadjajNaziv ?? '-'),
                subtitle: Text(
                  '${zaduzenje.dogadjajDatum != null ? formatDateTime(zaduzenje.dogadjajDatum!) : '-'}'
                  '${zaduzenje.dogadjajLokacija != null ? ' · ${zaduzenje.dogadjajLokacija}' : ''}',
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _LogAktivnostResult {
  const _LogAktivnostResult({
    required this.tipAktivnostiId,
    required this.datumAktivnosti,
    required this.brojSati,
    this.opis,
  });

  final int tipAktivnostiId;
  final DateTime datumAktivnosti;
  final double brojSati;
  final String? opis;
}

class _LogAktivnostDialog extends ConsumerStatefulWidget {
  const _LogAktivnostDialog();

  @override
  ConsumerState<_LogAktivnostDialog> createState() => _LogAktivnostDialogState();
}

class _LogAktivnostDialogState extends ConsumerState<_LogAktivnostDialog> {
  final _satiController = TextEditingController();
  final _opisController = TextEditingController();
  int? _tipAktivnostiId;
  DateTime _datumAktivnosti = DateTime.now();
  final Map<String, String> _errors = {};

  @override
  void dispose() {
    _satiController.dispose();
    _opisController.dispose();
    super.dispose();
  }

  Future<void> _pickDatum() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _datumAktivnosti,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _datumAktivnosti = picked);
  }

  void _submit() {
    final errors = <String, String>{};
    if (_tipAktivnostiId == null) errors['tip'] = 'Odaberite tip aktivnosti.';
    final sati = double.tryParse(_satiController.text.replaceAll(',', '.'));
    if (sati == null || sati < 0.1 || sati > 24) errors['sati'] = 'Unesite broj sati između 0.1 i 24.';

    if (errors.isNotEmpty) {
      setState(() => _errors
        ..clear()
        ..addAll(errors));
      return;
    }

    Navigator.of(context).pop(_LogAktivnostResult(
      tipAktivnostiId: _tipAktivnostiId!,
      datumAktivnosti: _datumAktivnosti,
      brojSati: sati!,
      opis: _opisController.text.trim().isEmpty ? null : _opisController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tipoviAsync = ref.watch(tipoviAktivnostiProvider);

    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('Zabilježi aktivnost')),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop(), tooltip: 'Zatvori'),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LabeledField(
                label: 'Tip aktivnosti',
                errorText: _errors['tip'],
                child: tipoviAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => ErrorBanner(error: e),
                  data: (tipovi) => DropdownButtonFormField<int>(
                    initialValue: _tipAktivnostiId,
                    isExpanded: true,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: [
                      for (final tip in tipovi) DropdownMenuItem(value: tip.tipAktivnostiId, child: Text(tip.naziv)),
                    ],
                    onChanged: (value) => setState(() => _tipAktivnostiId = value),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              LabeledField(
                label: 'Datum aktivnosti',
                child: InkWell(
                  onTap: _pickDatum,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                    ),
                    child: Text(formatDate(_datumAktivnosti)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              LabeledField(
                label: 'Broj sati',
                errorText: _errors['sati'],
                child: TextField(
                  controller: _satiController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'npr. 2.5'),
                ),
              ),
              const SizedBox(height: 12),
              LabeledField(
                label: 'Opis',
                required: false,
                child: TextField(
                  controller: _opisController,
                  maxLines: 3,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Odustani')),
        FilledButton(onPressed: _submit, child: const Text('Sačuvaj')),
      ],
    );
  }
}
