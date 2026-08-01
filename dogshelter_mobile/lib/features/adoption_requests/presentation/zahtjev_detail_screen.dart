import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/core/date_format.dart';
import 'package:dogshelter_shared/core/image_url.dart';
import '../../../environment.dart';
import 'package:dogshelter_shared/widgets/error_banner.dart';
import '../application/adoption_requests_providers.dart';
import 'package:dogshelter_shared/zahtjev_za_udomljavanje/domain/zahtjev_za_udomljavanje.dart';
import 'zahtjev_status_style.dart';

class ZahtjevDetailScreen extends ConsumerWidget {
  const ZahtjevDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zahtjevAsync = ref.watch(zahtjevDetailProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalji zahtjeva')),
      body: zahtjevAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: ErrorBanner(error: e)),
        data: (zahtjev) => _ZahtjevDetailBody(zahtjev: zahtjev),
      ),
    );
  }
}

class _ZahtjevDetailBody extends StatelessWidget {
  const _ZahtjevDetailBody({required this.zahtjev});

  final ZahtjevZaUdomljavanje zahtjev;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveImageUrl(zahtjev.pasSlikaNaslovna, Environment.apiBaseUrl);
    final isOdbijen = zahtjev.statusZahtjevaNaziv?.toLowerCase() == 'odbijen';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/dogs/${zahtjev.pasId}'),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: imageUrl == null
                        ? const ColoredBox(color: Color(0xFFE0E0E0), child: Icon(Icons.pets))
                        : CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zahtjev.pasNaziv ?? 'Nepoznat pas',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('Pogledaj profil psa', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Status:', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(width: 8),
              ZahtjevStatusBadge(naziv: zahtjev.statusZahtjevaNaziv),
            ],
          ),
          const SizedBox(height: 16),
          _DetailRow(label: 'Datum podnošenja', value: formatDate(zahtjev.datumPodnosenja)),
          if (zahtjev.datumObrade != null)
            _DetailRow(label: 'Datum obrade', value: formatDate(zahtjev.datumObrade!)),
          if (zahtjev.napomena != null && zahtjev.napomena!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Napomena', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(zahtjev.napomena!),
          ],
          if (isOdbijen && zahtjev.razlogOdbijanja != null && zahtjev.razlogOdbijanja!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
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
                    'Razlog odbijanja',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    zahtjev.razlogOdbijanja!,
                    style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 150, child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
