import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:dogshelter_shared/core/date_format.dart';
import 'package:dogshelter_shared/widgets/error_banner.dart';
import 'package:dogshelter_shared/donacija/domain/donacija.dart';
import '../../../widgets/detail_row.dart';
import '../application/donations_providers.dart';
import 'donation_status_style.dart';

class DonationDetailScreen extends ConsumerWidget {
  const DonationDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donacijaAsync = ref.watch(donacijaDetailProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalji donacije')),
      body: donacijaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: ErrorBanner(error: e)),
        data: (donacija) => _DonationDetailBody(donacija: donacija),
      ),
    );
  }
}

class _DonationDetailBody extends ConsumerStatefulWidget {
  const _DonationDetailBody({required this.donacija});

  final Donacija donacija;

  @override
  ConsumerState<_DonationDetailBody> createState() => _DonationDetailBodyState();
}

class _DonationDetailBodyState extends ConsumerState<_DonationDetailBody> {
  bool _isRetrying = false;
  Object? _retryError;

  bool get _canRetry {
    final naziv = widget.donacija.statusDonacijeNaziv;
    return widget.donacija.isNovcana && (naziv == 'Na čekanju' || naziv == 'Neuspješna');
  }

  Future<void> _retry() async {
    setState(() {
      _isRetrying = true;
      _retryError = null;
    });
    try {
      final response = await ref.read(donationsApiProvider).retryPlacanje(widget.donacija.donacijaId);
      // A null clientSecret means the backend found the payment already succeeded remotely and
      // reconciled the donation to Uspješna itself - there's nothing left to pay, so opening a
      // payment sheet here would either crash (null secret) or be redundant.
      final alreadyPaid = response.clientSecret == null;
      if (!alreadyPaid) {
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: response.clientSecret!,
            merchantDisplayName: 'DogShelter',
          ),
        );
        await Stripe.instance.presentPaymentSheet();
      }
      ref.invalidate(donacijaDetailProvider(widget.donacija.donacijaId));
      // Refresh the list too so navigating back doesn't show the pre-retry "Na čekanju" status.
      unawaited(ref.read(donacijaListProvider.notifier).loadFirstPage());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(alreadyPaid ? 'Donacija je već uspješno plaćena.' : 'Plaćanje se obrađuje.'),
          ),
        );
      }
    } on StripeException catch (e) {
      setState(() => _retryError = e.error.localizedMessage ?? e.error.message ?? 'Plaćanje nije uspjelo.');
    } catch (e) {
      setState(() => _retryError = e);
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final donacija = widget.donacija;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                donacija.isNovcana ? Icons.payments_outlined : Icons.card_giftcard_outlined,
                size: 32,
                color: const Color(0xFF008554),
              ),
              const SizedBox(width: 12),
              Text(
                donacija.tipDonacijeNaziv ?? 'Donacija',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Status:', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(width: 8),
              DonacijaStatusBadge(naziv: donacija.statusDonacijeNaziv),
            ],
          ),
          const SizedBox(height: 16),
          if (donacija.iznos != null) DetailRow(label: 'Iznos', value: '${donacija.iznos!.toStringAsFixed(2)} KM'),
          if (donacija.prikazNazivStavke != null) DetailRow(label: 'Kategorija', value: donacija.prikazNazivStavke!),
          if (donacija.kolicina != null)
            DetailRow(
              label: 'Količina',
              value: '${donacija.kolicina!.toStringAsFixed(donacija.kolicina! % 1 == 0 ? 0 : 2)} ${donacija.jedinicaMjereNaziv ?? ''}',
            ),
          if (!donacija.isNovcana)
            DetailRow(
              label: 'Dostava',
              value: donacija.trebaPreuzimanje ? 'Azil preuzima donaciju' : 'Donator dostavlja lično',
            ),
          if (donacija.trebaPreuzimanje && donacija.adresaPreuzimanja != null)
            DetailRow(label: 'Adresa preuzimanja', value: donacija.adresaPreuzimanja!),
          if (donacija.trebaPreuzimanje && donacija.telefonPreuzimanja != null)
            DetailRow(label: 'Telefon', value: donacija.telefonPreuzimanja!),
          if (donacija.datumPreuzimanja != null)
            DetailRow(label: 'Termin preuzimanja', value: formatDateTime(donacija.datumPreuzimanja!)),
          if (donacija.zeljeniDatumDostave != null)
            DetailRow(label: 'Željeni datum dostave', value: formatDate(donacija.zeljeniDatumDostave!)),
          DetailRow(label: 'Datum donacije', value: formatDateTime(donacija.datumDonacije)),
          if (donacija.datumObrade != null)
            DetailRow(label: 'Datum obrade', value: formatDateTime(donacija.datumObrade!)),
          if (donacija.napomena != null && donacija.napomena!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Napomena', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(donacija.napomena!),
          ],
          if (donacija.razlogOdbijanja != null && donacija.razlogOdbijanja!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ReasonBox(title: 'Razlog odbijanja', text: donacija.razlogOdbijanja!),
          ],
          if (donacija.razlogVracanja != null && donacija.razlogVracanja!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ReasonBox(title: 'Razlog vraćanja', text: donacija.razlogVracanja!),
          ],
          if (_canRetry) ...[
            const SizedBox(height: 24),
            ErrorBanner(error: _retryError),
            FilledButton.icon(
              onPressed: _isRetrying ? null : _retry,
              icon: _isRetrying
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh),
              label: const Text('Pokušaj plaćanje ponovo'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReasonBox extends StatelessWidget {
  const _ReasonBox({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onErrorContainer),
          ),
          const SizedBox(height: 4),
          Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
        ],
      ),
    );
  }
}
