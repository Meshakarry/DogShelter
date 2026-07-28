import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/error_banner.dart';
import '../../visits/presentation/inline_calendar.dart';
import '../application/activities_providers.dart';

/// Bottom sheet for self-logging a real POST /api/AktivnostVolontera - pops `true` on success so
/// the caller can snackbar/reload, same contract as BookVisitSheet/_SubmitRequestSheet.
class LogActivitySheet extends ConsumerStatefulWidget {
  const LogActivitySheet({super.key});

  @override
  ConsumerState<LogActivitySheet> createState() => _LogActivitySheetState();
}

class _LogActivitySheetState extends ConsumerState<LogActivitySheet> {
  final _satiController = TextEditingController();
  final _opisController = TextEditingController();
  late final DateTime _firstDate;
  late final DateTime _lastDate;
  int? _tipAktivnostiId;
  DateTime? _datumAktivnosti;
  bool _isSubmitting = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _lastDate = DateTime(now.year, now.month, now.day);
    _firstDate = _lastDate.subtract(const Duration(days: 365));
    _datumAktivnosti = _lastDate;
  }

  @override
  void dispose() {
    _satiController.dispose();
    _opisController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  Future<void> _submit() async {
    if (_tipAktivnostiId == null) {
      setState(() => _error = 'Odaberite tip aktivnosti.');
      return;
    }
    if (_datumAktivnosti == null) {
      setState(() => _error = 'Odaberite datum aktivnosti.');
      return;
    }
    final sati = double.tryParse(_satiController.text.replaceAll(',', '.'));
    if (sati == null || sati < 0.1 || sati > 24) {
      setState(() => _error = 'Unesite broj sati između 0.1 i 24.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await ref.read(activitiesApiProvider).logAktivnost(
            tipAktivnostiId: _tipAktivnostiId!,
            datumAktivnosti: _datumAktivnosti!,
            brojSati: sati,
            opis: _opisController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tipoviAsync = ref.watch(tipoviAktivnostiProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Evidentiraj aktivnost',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Unesite podatke o volonterskoj aktivnosti koju ste obavili.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ErrorBanner(error: _error),
            tipoviAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => ErrorBanner(error: e),
              data: (tipovi) => DropdownButtonFormField<int>(
                initialValue: _tipAktivnostiId,
                decoration: const InputDecoration(labelText: 'Tip aktivnosti'),
                items: [
                  for (final tip in tipovi) DropdownMenuItem(value: tip.tipAktivnostiId, child: Text(tip.naziv)),
                ],
                onChanged: (value) {
                  _clearError();
                  setState(() => _tipAktivnostiId = value);
                },
              ),
            ),
            const SizedBox(height: 20),
            Text('Datum aktivnosti', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: InlineCalendar(
                firstDate: _firstDate,
                lastDate: _lastDate,
                selectedDate: _datumAktivnosti,
                onDateSelected: (date) {
                  _clearError();
                  setState(() => _datumAktivnosti = date);
                },
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _satiController,
              onChanged: (_) => _clearError(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Broj sati (npr. 2.5)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _opisController,
              onChanged: (_) => _clearError(),
              maxLines: 3,
              maxLength: 1000,
              decoration: const InputDecoration(labelText: 'Opis (opcionalno)', alignLabelWithHint: true),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                    child: const Text('Otkaži'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Sačuvaj'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
