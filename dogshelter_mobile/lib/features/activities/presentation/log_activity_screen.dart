import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/widgets/error_banner.dart';
import 'package:dogshelter_shared/widgets/form_error_scroller.dart';
import 'package:dogshelter_shared/widgets/inline_calendar.dart';
import 'package:dogshelter_shared/widgets/labeled_field.dart';
import '../application/activities_providers.dart';

class LogActivityScreen extends ConsumerStatefulWidget {
  const LogActivityScreen({super.key});

  @override
  ConsumerState<LogActivityScreen> createState() => _LogActivityScreenState();
}

class _LogActivityScreenState extends ConsumerState<LogActivityScreen> with FormErrorScroller<LogActivityScreen> {
  final _satiController = TextEditingController();
  final _opisController = TextEditingController();
  final _scrollController = ScrollController();
  late final DateTime _firstDate;
  late final DateTime _lastDate;
  int? _tipAktivnostiId;
  DateTime? _datumAktivnosti;
  bool _isSubmitting = false;
  Object? _apiError;

  @override
  List<String> get fieldOrder => const ['tip', 'datum', 'sati'];

  @override
  ScrollController get errorScrollController => _scrollController;

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
    _scrollController.dispose();
    super.dispose();
  }

  void _clearApiError() {
    if (_apiError != null) setState(() => _apiError = null);
  }

  Future<void> _submit() async {
    final errors = <String, String>{};
    if (_tipAktivnostiId == null) errors['tip'] = 'Odaberite tip aktivnosti.';
    if (_datumAktivnosti == null) errors['datum'] = 'Odaberite datum aktivnosti.';

    final sati = double.tryParse(_satiController.text.replaceAll(',', '.'));
    if (sati == null || sati < 0.1 || sati > 24) {
      errors['sati'] = 'Unesite broj sati između 0.1 i 24.';
    }

    if (errors.isNotEmpty) {
      applyValidationErrors(errors);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _apiError = null;
      clearAllFieldErrors();
    });
    try {
      await ref.read(activitiesApiProvider).logAktivnost(
            tipAktivnostiId: _tipAktivnostiId!,
            datumAktivnosti: _datumAktivnosti!,
            brojSati: sati!,
            opis: _opisController.text.trim(),
          );
      if (mounted) context.pop(true);
    } catch (e) {
      setState(() => _apiError = e);
      scrollToTop();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tipoviAsync = ref.watch(tipoviAktivnostiProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Evidentiraj aktivnost')),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Unesite podatke o volonterskoj aktivnosti koju ste obavili.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ErrorBanner(error: _apiError),
            LabeledField(
              key: keyFor('tip'),
              label: 'Tip aktivnosti',
              child: tipoviAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => ErrorBanner(error: e),
                data: (tipovi) => DropdownButtonFormField<int>(
                  initialValue: _tipAktivnostiId,
                  decoration: InputDecoration(
                    hintText: 'Odaberite tip aktivnosti',
                    border: const OutlineInputBorder(),
                    errorText: fieldErrors['tip'],
                  ),
                  items: [
                    for (final tip in tipovi) DropdownMenuItem(value: tip.tipAktivnostiId, child: Text(tip.naziv)),
                  ],
                  onChanged: (value) {
                    _clearApiError();
                    clearFieldError('tip');
                    setState(() => _tipAktivnostiId = value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            LabeledField(
              key: keyFor('datum'),
              label: 'Datum aktivnosti',
              errorText: fieldErrors['datum'],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: fieldErrors['datum'] != null ? Theme.of(context).colorScheme.error : const Color(0xFFE5E7EB)),
                ),
                child: InlineCalendar(
                  firstDate: _firstDate,
                  lastDate: _lastDate,
                  selectedDate: _datumAktivnosti,
                  onDateSelected: (date) {
                    _clearApiError();
                    clearFieldError('datum');
                    setState(() => _datumAktivnosti = date);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            LabeledField(
              key: keyFor('sati'),
              label: 'Broj sati',
              child: TextField(
                controller: _satiController,
                onChanged: (_) {
                  _clearApiError();
                  clearFieldError('sati');
                },
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'npr. 2.5',
                  border: const OutlineInputBorder(),
                  errorText: fieldErrors['sati'],
                ),
              ),
            ),
            const SizedBox(height: 12),
            LabeledField(
              label: 'Opis (opcionalno)',
              required: false,
              child: TextField(
                controller: _opisController,
                onChanged: (_) => _clearApiError(),
                maxLines: 3,
                maxLength: 1000,
                decoration: const InputDecoration(hintText: 'Kratko opišite šta ste radili', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Sačuvaj'),
            ),
          ],
        ),
      ),
    );
  }
}
