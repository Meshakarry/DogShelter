import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/error_banner.dart';
import '../../visits/presentation/inline_calendar.dart';
import '../application/donations_providers.dart';
import '../domain/kategorija_donacije.dart';
import '../domain/tip_donacije.dart';
import 'donation_icons.dart';
import 'shelter_needs_section.dart';

const _amountPresets = [10.0, 20.0, 50.0, 100.0];

// Assumed shelter pickup/visiting hours (09:00-16:00, hourly) - not modeled on the backend
// (Posjeta/Donacija have no time-of-day restriction of their own), so this is a mobile-only UX
// choice matching the same slot list already used for Posjeta bookings.
const _timeSlots = ['09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00'];

/// Full-screen "new donation" form (not a bottom sheet, per the design mockup) - Novčana
/// (monetary) donations continue into a real Stripe PaymentSheet; Materijalna (in-kind)
/// donations are logged with structured category/quantity/delivery details for an admin to
/// review, no payment step.
class NewDonationScreen extends ConsumerStatefulWidget {
  const NewDonationScreen({super.key});

  @override
  ConsumerState<NewDonationScreen> createState() => _NewDonationScreenState();
}

class _NewDonationScreenState extends ConsumerState<NewDonationScreen> {
  final _napomenaController = TextEditingController();
  final _customAmountController = TextEditingController();
  final _prilagodjenNazivController = TextEditingController();
  final _kolicinaController = TextEditingController();
  final _adresaController = TextEditingController();
  final _telefonController = TextEditingController();
  final _scrollController = ScrollController();

  int? _tipDonacijeId;
  double? _selectedPreset;
  bool _customAmountSelected = false;

  int? _kategorijaDonacijeId;
  int? _jedinicaMjereId;
  bool _trebaPreuzimanje = false;
  DateTime? _pickupDate;
  String? _pickupTimeSlot;
  DateTime? _zeljeniDatumDostave;

  late final DateTime _firstDate;
  late final DateTime _lastDate;

  bool _isSubmitting = false;
  Object? _error;

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
    _kolicinaController.dispose();
    _adresaController.dispose();
    _telefonController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  // Validation messages must be clearly visible below the controls (faculty rule) - since this
  // is a long scrollable form, an error set from a check near the bottom (or the submit button)
  // would otherwise render into the ErrorBanner at the top, off-screen and easy to miss.
  void _setError(Object message) {
    setState(() => _error = message);
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  bool _isNovcana(List<TipDonacije> tipovi) {
    final tip = tipovi.where((t) => t.tipDonacijeId == _tipDonacijeId).firstOrNull;
    return tip?.naziv == 'Novčana';
  }

  bool _isOstalo(List<KategorijaDonacije> kategorije) {
    final kat = kategorije.where((k) => k.kategorijaDonacijeId == _kategorijaDonacijeId).firstOrNull;
    return kat?.isOstalo ?? false;
  }

  double? get _iznos {
    if (_customAmountSelected) {
      return double.tryParse(_customAmountController.text.replaceAll(',', '.'));
    }
    return _selectedPreset;
  }

  DateTime? get _pickupDateTime {
    if (_pickupDate == null || _pickupTimeSlot == null) return null;
    final parts = _pickupTimeSlot!.split(':');
    return DateTime(_pickupDate!.year, _pickupDate!.month, _pickupDate!.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  Future<void> _submit(List<TipDonacije> tipovi, List<KategorijaDonacije> kategorije) async {
    if (_tipDonacijeId == null) {
      _setError('Odaberite tip donacije.');
      return;
    }
    final isNovcana = _isNovcana(tipovi);
    final isOstalo = _isOstalo(kategorije);

    if (isNovcana) {
      final iznos = _iznos;
      if (iznos == null || iznos <= 0) {
        _setError('Unesite ispravan iznos donacije.');
        return;
      }
    } else {
      if (_kategorijaDonacijeId == null) {
        _setError('Odaberite kategoriju donacije.');
        return;
      }
      if (isOstalo && _prilagodjenNazivController.text.trim().isEmpty) {
        _setError('Opišite šta biste željeli donirati.');
        return;
      }
      final kolicina = double.tryParse(_kolicinaController.text.replaceAll(',', '.'));
      if (kolicina == null || kolicina <= 0) {
        _setError('Unesite ispravnu količinu.');
        return;
      }
      if (_jedinicaMjereId == null) {
        _setError('Odaberite jedinicu mjere.');
        return;
      }
      if (_trebaPreuzimanje) {
        if (_adresaController.text.trim().isEmpty) {
          _setError('Unesite adresu za preuzimanje.');
          return;
        }
        if (_telefonController.text.trim().isEmpty) {
          _setError('Unesite kontakt telefon za preuzimanje.');
          return;
        }
        if (_pickupDateTime == null) {
          _setError('Odaberite željeni termin preuzimanja.');
          return;
        }
      }
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final response = await ref.read(donationsApiProvider).createDonacija(
            tipDonacijeId: _tipDonacijeId!,
            iznos: isNovcana ? _iznos : null,
            napomena: _napomenaController.text.trim(),
            kategorijaDonacijeId: isNovcana ? null : _kategorijaDonacijeId,
            prilagodjenNaziv: isNovcana ? null : _prilagodjenNazivController.text.trim(),
            kolicina: isNovcana ? null : double.tryParse(_kolicinaController.text.replaceAll(',', '.')),
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
      final message = e.error.localizedMessage ?? e.error.message;
      _setError(message ?? 'Plaćanje je otkazano ili nije uspjelo.');
    } catch (e) {
      _setError(e);
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
                ErrorBanner(error: _error),
                Text('Tip donacije', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _tipDonacijeId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Odaberite tip donacije',
                  ),
                  items: [
                    for (final tip in tipovi) DropdownMenuItem(value: tip.tipDonacijeId, child: Text(tip.naziv)),
                  ],
                  onChanged: (value) {
                    _clearError();
                    setState(() {
                      _tipDonacijeId = value;
                      _selectedPreset = null;
                      _customAmountSelected = false;
                      _customAmountController.clear();
                    });
                  },
                ),
                const SizedBox(height: 20),
                if (_tipDonacijeId != null) ...(isNovcana ? _buildNovcanaFields() : _buildMaterijalnaFields()),
                const SizedBox(height: 20),
                TextField(
                  controller: _napomenaController,
                  onChanged: (_) => _clearError(),
                  maxLines: 3,
                  maxLength: 1000,
                  decoration: const InputDecoration(labelText: 'Napomena (opcionalno)', alignLabelWithHint: true),
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
      Row(
        children: [
          Text('Iznos (KM)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 4),
          const Text('*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ],
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final preset in _amountPresets)
            _ChipButton(
              label: preset.toStringAsFixed(0),
              selected: !_customAmountSelected && _selectedPreset == preset,
              onTap: () {
                _clearError();
                setState(() {
                  _selectedPreset = preset;
                  _customAmountSelected = false;
                });
              },
            ),
          _ChipButton(
            label: 'Drugo',
            selected: _customAmountSelected,
            onTap: () {
              _clearError();
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
          onChanged: (_) => _clearError(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Unesite iznos (KM)', border: OutlineInputBorder()),
        ),
      ],
    ];
  }

  List<Widget> _buildMaterijalnaFields() {
    final kategorijeAsync = ref.watch(kategorijaDonacijeLookupProvider);
    final jediniceAsync = ref.watch(jedinicaMjereLookupProvider);
    final kategorije = kategorijeAsync.valueOrNull ?? const <KategorijaDonacije>[];
    final isOstalo = _isOstalo(kategorije);

    return [
      const ShelterNeedsSection(),
      const SizedBox(height: 24),
      Row(
        children: [
          Text('Kategorija donacije', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 4),
          const Text('*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ],
      ),
      const SizedBox(height: 8),
      kategorijeAsync.when(
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
                      _clearError();
                      setState(() {
                        _kategorijaDonacijeId = kat.kategorijaDonacijeId;
                        _kolicinaController.clear();
                        _jedinicaMjereId = null;
                      });
                    },
                  ),
              ],
            );
          },
        ),
      ),
      if (isOstalo) ...[
        const SizedBox(height: 16),
        TextField(
          controller: _prilagodjenNazivController,
          onChanged: (_) => _clearError(),
          decoration: const InputDecoration(
            labelText: 'Šta biste željeli donirati?',
            border: OutlineInputBorder(),
          ),
        ),
      ],
      if (_kategorijaDonacijeId != null) ...[
        const SizedBox(height: 20),
        Text('Količina', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _kolicinaController,
                onChanged: (_) => _clearError(),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Količina', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: jediniceAsync.when(
                loading: () => const SizedBox(height: 56, child: Center(child: CircularProgressIndicator())),
                error: (e, _) => ErrorBanner(error: e),
                data: (jedinice) => DropdownButtonFormField<int>(
                  initialValue: _jedinicaMjereId,
                  decoration: const InputDecoration(labelText: 'Jedinica', border: OutlineInputBorder()),
                  items: [
                    for (final j in jedinice) DropdownMenuItem(value: j.jedinicaMjereId, child: Text(j.naziv)),
                  ],
                  onChanged: (value) {
                    _clearError();
                    setState(() => _jedinicaMjereId = value);
                  },
                ),
              ),
            ),
          ],
        ),
      ],
      const SizedBox(height: 20),
      Text('Kako biste željeli dostaviti donaciju?', style: Theme.of(context).textTheme.titleMedium),
      RadioGroup<bool>(
        groupValue: _trebaPreuzimanje,
        onChanged: (value) {
          _clearError();
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

  List<Widget> _buildPickupFields() {
    return [
      const SizedBox(height: 8),
      TextField(
        controller: _adresaController,
        onChanged: (_) => _clearError(),
        decoration: const InputDecoration(labelText: 'Adresa preuzimanja', border: OutlineInputBorder()),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _telefonController,
        onChanged: (_) => _clearError(),
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(labelText: 'Broj telefona', border: OutlineInputBorder()),
      ),
      const SizedBox(height: 16),
      Text('Željeni termin preuzimanja', style: Theme.of(context).textTheme.titleMedium),
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
          selectedDate: _pickupDate,
          onDateSelected: (date) {
            _clearError();
            setState(() {
              _pickupDate = date;
              _pickupTimeSlot = null;
            });
          },
        ),
      ),
      const SizedBox(height: 12),
      if (_pickupDate != null)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final slot in _timeSlots)
              _ChipButton(
                label: slot,
                selected: slot == _pickupTimeSlot,
                onTap: () {
                  _clearError();
                  setState(() => _pickupTimeSlot = slot);
                },
              ),
          ],
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
          onDateSelected: (date) {
            _clearError();
            setState(() => _zeljeniDatumDostave = date);
          },
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

class _ChipButton extends StatelessWidget {
  const _ChipButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF008554) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? const Color(0xFF008554) : const Color(0xFFD1D5DB)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
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
