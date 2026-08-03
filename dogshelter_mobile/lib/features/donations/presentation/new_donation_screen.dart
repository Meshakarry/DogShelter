import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/widgets/error_banner.dart';
import 'package:dogshelter_shared/widgets/form_error_scroller.dart';
import 'package:dogshelter_shared/widgets/inline_calendar.dart';
import 'package:dogshelter_shared/widgets/labeled_field.dart';
import 'package:dogshelter_shared/donacija/domain/jedinica_mjere.dart';
import 'package:dogshelter_shared/donacija/domain/kategorija_donacije.dart';
import 'package:dogshelter_shared/donacija/domain/tip_donacije.dart';
import '../application/donations_providers.dart';
import 'chip_button.dart';
import 'donation_icons.dart';
import 'quantity_stepper.dart';
import 'shelter_needs_section.dart';
import 'unit_picker.dart';

const _amountPresets = [10.0, 20.0, 50.0, 100.0];

// Assumed shelter pickup/visiting hours (09:00-16:00, hourly)
const _timeSlots = ['09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00'];

/// Full-screen "new donation" form. Novčana (monetary) donations continue into a Stripe
/// PaymentSheet; Materijalna (in-kind) donations are logged with structured category/quantity/
/// delivery details for an admin to review, no payment step.
class NewDonationScreen extends ConsumerStatefulWidget {
  const NewDonationScreen({super.key});

  @override
  ConsumerState<NewDonationScreen> createState() => _NewDonationScreenState();
}

class _NewDonationScreenState extends ConsumerState<NewDonationScreen> with FormErrorScroller<NewDonationScreen> {
  final _napomenaController = TextEditingController();
  final _customAmountController = TextEditingController();
  final _prilagodjenNazivController = TextEditingController();
  final _adresaController = TextEditingController();
  final _telefonController = TextEditingController();
  final _scrollController = ScrollController();

  int? _tipDonacijeId;
  double? _selectedPreset;
  bool _customAmountSelected = false;

  int? _kategorijaDonacijeId;
  double? _kolicina;
  int? _jedinicaMjereId;
  bool _trebaPreuzimanje = false;
  DateTime? _pickupDate;
  String? _pickupTimeSlot;
  DateTime? _zeljeniDatumDostave;

  late final DateTime _firstDate;
  late final DateTime _lastDate;

  bool _isSubmitting = false;
  Object? _apiError;

  // Field order determines scroll-to-first-error priority. Jumping to the top of the form on
  // every failed submit would be disorienting for errors near the bottom (e.g. pickup fields),
  // forcing the user to scroll back past fields already filled in correctly.
  @override
  List<String> get fieldOrder => const [
    'tip',
    'iznos',
    'kategorija',
    'prilagodjenNaziv',
    'kolicina',
    'jedinica',
    'adresa',
    'telefon',
    'pickupDatum',
    'pickupVrijeme',
  ];

  @override
  ScrollController get errorScrollController => _scrollController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _firstDate = DateTime(now.year, now.month, now.day);
    _lastDate = _firstDate.add(const Duration(days: 365));
  }

  @override
  void dispose() {
    _napomenaController.dispose();
    _customAmountController.dispose();
    _prilagodjenNazivController.dispose();
    _adresaController.dispose();
    _telefonController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _clearApiError() {
    if (_apiError != null) setState(() => _apiError = null);
  }

  // API/payment failures aren't tied to one control, so a top banner is the right place for
  // them (unlike the per-field validation messages below) - still needs the scroll-into-view
  // treatment since this is a long scrollable form and submit sits near the bottom.
  void _setApiError(Object message) {
    setState(() => _apiError = message);
    scrollToTop();
  }

  bool _isNovcana(List<TipDonacije> tipovi) {
    final tip = tipovi.where((t) => t.tipDonacijeId == _tipDonacijeId).firstOrNull;
    return tip?.naziv == 'Novčana';
  }

  KategorijaDonacije? _selectedKategorija(List<KategorijaDonacije> kategorije) {
    return kategorije.where((k) => k.kategorijaDonacijeId == _kategorijaDonacijeId).firstOrNull;
  }

  DateTime? get _pickupDateTime {
    if (_pickupDate == null || _pickupTimeSlot == null) return null;
    final parts = _pickupTimeSlot!.split(':');
    return DateTime(_pickupDate!.year, _pickupDate!.month, _pickupDate!.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  double? get _iznos {
    if (_customAmountSelected) {
      return double.tryParse(_customAmountController.text.replaceAll(',', '.'));
    }
    return _selectedPreset;
  }

  Future<void> _submit(List<TipDonacije> tipovi, List<KategorijaDonacije> kategorije) async {
    final errors = <String, String>{};
    final isNovcana = _isNovcana(tipovi);
    final kategorija = _selectedKategorija(kategorije);
    final isOstalo = kategorija?.isOstalo ?? false;

    if (_tipDonacijeId == null) {
      errors['tip'] = 'Odaberite tip donacije.';
    } else if (isNovcana) {
      final iznos = _iznos;
      if (iznos == null || iznos <= 0) errors['iznos'] = 'Unesite ispravan iznos donacije.';
    } else {
      if (_kategorijaDonacijeId == null) {
        errors['kategorija'] = 'Odaberite kategoriju donacije.';
      } else {
        if (isOstalo && _prilagodjenNazivController.text.trim().isEmpty) {
          errors['prilagodjenNaziv'] = 'Opišite šta biste željeli donirati.';
        }
        if (_kolicina == null || _kolicina! <= 0) errors['kolicina'] = 'Unesite ispravnu količinu.';
        if (_jedinicaMjereId == null) errors['jedinica'] = 'Odaberite jedinicu mjere.';
      }
      if (_trebaPreuzimanje) {
        if (_adresaController.text.trim().isEmpty) errors['adresa'] = 'Unesite adresu za preuzimanje.';
        if (_telefonController.text.trim().isEmpty) errors['telefon'] = 'Unesite kontakt telefon za preuzimanje.';
        if (_pickupDate == null) errors['pickupDatum'] = 'Odaberite datum preuzimanja.';
        if (_pickupTimeSlot == null) errors['pickupVrijeme'] = 'Odaberite vrijeme preuzimanja.';
      }
    }

    if (errors.isNotEmpty) {
      applyValidationErrors(errors);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _apiError = null;
      fieldErrors.clear();
    });
    try {
      final response = await ref.read(donationsApiProvider).createDonacija(
            tipDonacijeId: _tipDonacijeId!,
            iznos: isNovcana ? _iznos : null,
            napomena: _napomenaController.text.trim(),
            kategorijaDonacijeId: isNovcana ? null : _kategorijaDonacijeId,
            prilagodjenNaziv: isNovcana ? null : _prilagodjenNazivController.text.trim(),
            kolicina: isNovcana ? null : _kolicina,
            jedinicaMjereId: isNovcana ? null : _jedinicaMjereId,
            trebaPreuzimanje: !isNovcana && _trebaPreuzimanje,
            adresaPreuzimanja: (!isNovcana && _trebaPreuzimanje) ? _adresaController.text.trim() : null,
            telefonPreuzimanja: (!isNovcana && _trebaPreuzimanje) ? _telefonController.text.trim() : null,
            datumPreuzimanja: (!isNovcana && _trebaPreuzimanje) ? _pickupDateTime : null,
            zeljeniDatumDostave: (!isNovcana && !_trebaPreuzimanje) ? _zeljeniDatumDostave : null,
          );

      if (isNovcana && response.clientSecret != null) {
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: response.clientSecret!,
            merchantDisplayName: 'DogShelter',
          ),
        );
        await Stripe.instance.presentPaymentSheet();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNovcana
                  ? 'Hvala na donaciji! Plaćanje se obrađuje.'
                  : 'Hvala na donaciji! Osoblje azila će je uskoro pregledati.',
            ),
          ),
        );
        // pushReplacement (not go) so the back stack still resolves to the Donacije list this
        // screen was pushed from, instead of go()'s full-stack-replace leaving no back target.
        context.pushReplacement('/donacije/${response.donacija.donacijaId}');
      }
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        // Stripe's own message here is a hardcoded, untranslated English string - show our
        // own Bosnian text instead of surfacing it to the user.
        _setApiError('Plaćanje je otkazano.');
      } else {
        final message = e.error.localizedMessage ?? e.error.message;
        _setApiError(message ?? 'Plaćanje nije uspjelo. Pokušajte ponovo.');
      }
    } catch (e) {
      _setApiError(e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tipoviAsync = ref.watch(tipDonacijeLookupProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Donacija')),
      body: tipoviAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: ErrorBanner(error: e)),
        data: (tipovi) {
          final isNovcana = _isNovcana(tipovi);
          return SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ErrorBanner(error: _apiError),
                LabeledField(
                  key: keyFor('tip'),
                  label: 'Tip donacije',
                  child: DropdownButtonFormField<int>(
                    initialValue: _tipDonacijeId,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: 'Odaberite tip donacije',
                      errorText: fieldErrors['tip'],
                    ),
                    items: [
                      for (final tip in tipovi) DropdownMenuItem(value: tip.tipDonacijeId, child: Text(tip.naziv)),
                    ],
                    onChanged: (value) {
                      setState(() {
                        fieldErrors.clear();
                        _apiError = null;
                        _tipDonacijeId = value;
                        _selectedPreset = null;
                        _customAmountSelected = false;
                        _customAmountController.clear();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),
                if (_tipDonacijeId != null) ...(isNovcana ? _buildNovcanaFields() : _buildMaterijalnaFields()),
                const SizedBox(height: 20),
                LabeledField(
                  label: 'Napomena (opcionalno)',
                  required: false,
                  child: TextField(
                    controller: _napomenaController,
                    maxLines: 3,
                    maxLength: 1000,
                    decoration: const InputDecoration(hintText: 'Dodatne informacije za osoblje azila'),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _isSubmitting ? null : () => _submit(tipovi, ref.read(kategorijaDonacijeLookupProvider).valueOrNull ?? const []),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(isNovcana ? 'Nastavi na plaćanje' : 'Pošalji donaciju'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildNovcanaFields() {
    return [
      LabeledField(
        key: keyFor('iznos'),
        label: 'Iznos (KM)',
        errorText: fieldErrors['iznos'],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in _amountPresets)
                  ChipButton(
                    label: preset.toStringAsFixed(0),
                    selected: !_customAmountSelected && _selectedPreset == preset,
                    onTap: () {
                      _clearApiError();
                      clearFieldError('iznos');
                      setState(() {
                        _selectedPreset = preset;
                        _customAmountSelected = false;
                      });
                    },
                  ),
                ChipButton(
                  label: 'Drugo',
                  selected: _customAmountSelected,
                  onTap: () {
                    _clearApiError();
                    clearFieldError('iznos');
                    setState(() {
                      _customAmountSelected = true;
                      _selectedPreset = null;
                    });
                  },
                ),
              ],
            ),
            if (_customAmountSelected) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customAmountController,
                onChanged: (_) => clearFieldError('iznos'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Unesite iznos u KM',
                  border: const OutlineInputBorder(),
                  errorText: fieldErrors['iznos'],
                  errorStyle: const TextStyle(height: 0, fontSize: 0),
                ),
              ),
            ],
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildMaterijalnaFields() {
    final kategorijeAsync = ref.watch(kategorijaDonacijeLookupProvider);
    final jediniceAsync = ref.watch(jedinicaMjereLookupProvider);
    final kategorije = kategorijeAsync.valueOrNull ?? const <KategorijaDonacije>[];
    final jedinice = jediniceAsync.valueOrNull ?? const <JedinicaMjere>[];
    final kategorija = _selectedKategorija(kategorije);
    final isOstalo = kategorija?.isOstalo ?? false;

    return [
      const ShelterNeedsSection(),
      const SizedBox(height: 24),
      LabeledField(
        key: keyFor('kategorija'),
        label: 'Kategorija donacije',
        errorText: fieldErrors['kategorija'],
        child: kategorijeAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => ErrorBanner(error: e),
          data: (kategorije) => LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 10.0;
              const columns = 3;
              final cardWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final kat in kategorije)
                    _CategoryCard(
                      label: kat.naziv,
                      icon: donationIconFor(kat.ikonaKljuc),
                      width: cardWidth,
                      selected: _kategorijaDonacijeId == kat.kategorijaDonacijeId,
                      onTap: () {
                        _clearApiError();
                        setState(() {
                          fieldErrors.remove('kategorija');
                          fieldErrors.remove('kolicina');
                          fieldErrors.remove('jedinica');
                          fieldErrors.remove('prilagodjenNaziv');
                          _kategorijaDonacijeId = kat.kategorijaDonacijeId;
                          _kolicina = null;
                          _jedinicaMjereId = kat.podrazumijevanaJedinicaMjereId;
                        });
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ),
      if (isOstalo) ...[
        const SizedBox(height: 16),
        LabeledField(
          key: keyFor('prilagodjenNaziv'),
          label: 'Šta biste željeli donirati?',
          child: TextField(
            controller: _prilagodjenNazivController,
            onChanged: (_) => clearFieldError('prilagodjenNaziv'),
            decoration: InputDecoration(
              hintText: 'npr. Hrana za pse, dekice, povodci',
              border: const OutlineInputBorder(),
              errorText: fieldErrors['prilagodjenNaziv'],
            ),
          ),
        ),
      ],
      if (_kategorijaDonacijeId != null) ...[
        const SizedBox(height: 20),
        LabeledField(
          key: keyFor('kolicina'),
          label: 'Količina',
          errorText: fieldErrors['kolicina'],
          child: QuantityStepper(
            value: _kolicina,
            step: _stepForSelectedUnit(jedinice),
            onChanged: (value) {
              _clearApiError();
              clearFieldError('kolicina');
              setState(() => _kolicina = value);
            },
          ),
        ),
        const SizedBox(height: 16),
        LabeledField(
          key: keyFor('jedinica'),
          label: 'Jedinica mjere',
          errorText: fieldErrors['jedinica'],
          child: UnitPicker(
            allUnits: jedinice,
            allowedUnits: kategorija?.dozvoljeneJedinice ?? const [],
            selectedId: _jedinicaMjereId,
            errorText: fieldErrors['jedinica'],
            onChanged: (value) {
              _clearApiError();
              clearFieldError('jedinica');
              setState(() => _jedinicaMjereId = value);
            },
          ),
        ),
      ],
      const SizedBox(height: 20),
      Text('Kako biste željeli dostaviti donaciju?', style: Theme.of(context).textTheme.titleMedium),
      RadioGroup<bool>(
        groupValue: _trebaPreuzimanje,
        onChanged: (value) {
          _clearApiError();
          fieldErrors.remove('adresa');
          fieldErrors.remove('telefon');
          fieldErrors.remove('pickupDatum');
          fieldErrors.remove('pickupVrijeme');
          setState(() => _trebaPreuzimanje = value!);
        },
        child: const Column(
          children: [
            RadioListTile<bool>(
              contentPadding: EdgeInsets.zero,
              value: false,
              title: Text('Sam/a ću donijeti u azil'),
            ),
            RadioListTile<bool>(
              contentPadding: EdgeInsets.zero,
              value: true,
              title: Text('Potrebno mi je da azil preuzme donaciju'),
            ),
          ],
        ),
      ),
      if (_trebaPreuzimanje) ..._buildPickupFields() else ..._buildPreferredDeliveryDateField(),
    ];
  }

  // kg is the only unit in this app's inventory where a half-unit makes practical sense (0.5 kg
  // of food); every other unit (kom/vreće/kutije/boce) only ever makes sense as a whole number.
  double _stepForSelectedUnit(List<JedinicaMjere> jedinice) {
    final naziv = jedinice.where((j) => j.jedinicaMjereId == _jedinicaMjereId).firstOrNull?.naziv;
    return naziv == 'kg' ? 0.5 : 1;
  }

  List<Widget> _buildPickupFields() {
    return [
      const SizedBox(height: 8),
      LabeledField(
        key: keyFor('adresa'),
        label: 'Adresa preuzimanja',
        child: TextField(
          controller: _adresaController,
          onChanged: (_) => clearFieldError('adresa'),
          decoration: InputDecoration(
            hintText: 'npr. Ulica i broj, grad',
            border: const OutlineInputBorder(),
            errorText: fieldErrors['adresa'],
          ),
        ),
      ),
      const SizedBox(height: 12),
      LabeledField(
        key: keyFor('telefon'),
        label: 'Broj telefona',
        child: TextField(
          controller: _telefonController,
          onChanged: (_) => clearFieldError('telefon'),
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: 'npr. 061 234 567',
            border: const OutlineInputBorder(),
            errorText: fieldErrors['telefon'],
          ),
        ),
      ),
      const SizedBox(height: 16),
      LabeledField(
        key: keyFor('pickupDatum'),
        label: 'Odaberite datum preuzimanja',
        errorText: fieldErrors['pickupDatum'],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: fieldErrors['pickupDatum'] != null ? Theme.of(context).colorScheme.error : const Color(0xFFE5E7EB)),
          ),
          child: InlineCalendar(
            firstDate: _firstDate,
            lastDate: _lastDate,
            selectedDate: _pickupDate,
            onDateSelected: (date) {
              clearFieldError('pickupDatum');
              setState(() {
                _pickupDate = date;
                _pickupTimeSlot = null;
              });
            },
          ),
        ),
      ),
      const SizedBox(height: 20),
      LabeledField(
        key: keyFor('pickupVrijeme'),
        label: 'Odaberite vrijeme preuzimanja',
        errorText: fieldErrors['pickupVrijeme'],
        child: _pickupDate == null
            ? Text(
                'Prvo odaberite datum.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final slot in _timeSlots)
                    ChipButton(
                      label: slot,
                      selected: slot == _pickupTimeSlot,
                      onTap: () {
                        clearFieldError('pickupVrijeme');
                        setState(() => _pickupTimeSlot = slot);
                      },
                    ),
                ],
              ),
      ),
    ];
  }

  List<Widget> _buildPreferredDeliveryDateField() {
    return [
      const SizedBox(height: 16),
      Text('Željeni datum dostave (opcionalno)', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 4),
      Text(
        'Kada očekujete da ćete dostaviti donaciju?',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
      ),
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
          selectedDate: _zeljeniDatumDostave,
          onDateSelected: (date) => setState(() => _zeljeniDatumDostave = date),
        ),
      ),
      if (_zeljeniDatumDostave != null)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => setState(() => _zeljeniDatumDostave = null),
            child: const Text('Ukloni datum'),
          ),
        ),
    ];
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.label,
    required this.icon,
    required this.width,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final double width;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: width,
        height: 108,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF008554) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? const Color(0xFF008554) : const Color(0xFFD1D5DB)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.white : const Color(0xFF008554), size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
