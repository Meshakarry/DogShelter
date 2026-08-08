import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/core/api_exception.dart';
import 'package:dogshelter_shared/core/date_format.dart';
import 'package:dogshelter_shared/core/image_url.dart';
import '../../../environment.dart';
import 'package:dogshelter_shared/widgets/error_banner.dart';
import '../../../widgets/cancel_reason_dialog.dart';
import '../../../widgets/detail_row.dart';
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

class _ZahtjevDetailBody extends ConsumerStatefulWidget {
  const _ZahtjevDetailBody({required this.zahtjev});

  final ZahtjevZaUdomljavanje zahtjev;

  @override
  ConsumerState<_ZahtjevDetailBody> createState() => _ZahtjevDetailBodyState();
}

class _ZahtjevDetailBodyState extends ConsumerState<_ZahtjevDetailBody> {
  bool _isCancelling = false;

  bool get _canCancel => widget.zahtjev.statusZahtjevaNaziv?.toLowerCase() == 'na čekanju';

  Future<void> _cancel() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const CancelReasonDialog(title: 'Otkaži zahtjev'),
    );
    if (reason == null || !mounted) return;

    setState(() => _isCancelling = true);
    try {
      await ref.read(zahtjevApiProvider).otkazi(widget.zahtjev.zahtjevZaUdomljavanjeId, razlogOtkazivanja: reason);
      ref.invalidate(zahtjevDetailProvider(widget.zahtjev.zahtjevZaUdomljavanjeId));
      ref.read(zahtjevListProvider.notifier).loadFirstPage();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Zahtjev je otkazan.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(describeApiError(e)), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final zahtjev = widget.zahtjev;
    final imageUrl = resolveImageUrl(zahtjev.pasSlikaNaslovna, Environment.apiBaseUrl);
    final isOdbijen = zahtjev.statusZahtjevaNaziv?.toLowerCase() == 'odbijen';
    final isOtkazan = zahtjev.statusZahtjevaNaziv?.toLowerCase() == 'otkazan';

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
          DetailRow(label: 'Datum podnošenja', value: formatDate(zahtjev.datumPodnosenja)),
          if (zahtjev.datumObrade != null)
            DetailRow(label: 'Datum obrade', value: formatDate(zahtjev.datumObrade!)),
          if (zahtjev.napomena != null && zahtjev.napomena!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Napomena', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(zahtjev.napomena!),
          ],
          if ((isOdbijen || isOtkazan) && zahtjev.razlogOdbijanja != null && zahtjev.razlogOdbijanja!.isNotEmpty) ...[
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
                    isOtkazan ? 'Razlog otkazivanja' : 'Razlog odbijanja',
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
          if (_canCancel) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _isCancelling ? null : _cancel,
              style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              icon: _isCancelling
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cancel_outlined),
              label: const Text('Otkaži zahtjev'),
            ),
          ],
        ],
      ),
    );
  }
}

