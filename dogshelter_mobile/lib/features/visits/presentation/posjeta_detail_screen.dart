import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/core/api_exception.dart';
import 'package:dogshelter_shared/core/date_format.dart';
import 'package:dogshelter_shared/core/image_url.dart';
import '../../../environment.dart';
import 'package:dogshelter_shared/widgets/error_banner.dart';
import 'package:dogshelter_shared/widgets/labeled_field.dart';
import '../application/visits_providers.dart';
import 'package:dogshelter_shared/posjeta/domain/posjeta.dart';
import 'posjeta_status_style.dart';

class PosjetaDetailScreen extends ConsumerWidget {
  const PosjetaDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posjetaAsync = ref.watch(posjetaDetailProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalji posjete')),
      body: posjetaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: ErrorBanner(error: e)),
        data: (posjeta) => _PosjetaDetailBody(posjeta: posjeta),
      ),
    );
  }
}

class _PosjetaDetailBody extends ConsumerStatefulWidget {
  const _PosjetaDetailBody({required this.posjeta});

  final Posjeta posjeta;

  @override
  ConsumerState<_PosjetaDetailBody> createState() => _PosjetaDetailBodyState();
}

class _PosjetaDetailBodyState extends ConsumerState<_PosjetaDetailBody> {
  bool _isCancelling = false;

  bool get _canCancel {
    final naziv = widget.posjeta.statusPosjeteNaziv?.toLowerCase();
    return naziv == 'na čekanju' || naziv == 'potvrđena';
  }

  Future<void> _cancel() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _CancelReasonDialog(),
    );
    if (reason == null || !mounted) return;

    setState(() => _isCancelling = true);
    try {
      await ref.read(visitsApiProvider).otkaziPosjetu(widget.posjeta.posjetaId, razlogOtkazivanja: reason);
      ref.invalidate(posjetaDetailProvider(widget.posjeta.posjetaId));
      ref.read(posjetaListProvider.notifier).loadFirstPage();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Posjeta je otkazana.')));
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
    final posjeta = widget.posjeta;
    final imageUrl = resolveImageUrl(posjeta.pasSlikaNaslovna, Environment.apiBaseUrl);
    final isOtkazana = posjeta.statusPosjeteNaziv?.toLowerCase() == 'otkazana';

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (posjeta.pasId != null)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.push('/dogs/${posjeta.pasId}'),
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
                            posjeta.pasNaziv ?? 'Nepoznat pas',
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
              )
            else
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: const SizedBox(
                      width: 72,
                      height: 72,
                      child: ColoredBox(
                        color: Color(0xFFE0E0E0),
                        child: Icon(Icons.home_work_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Opća posjeta azilu',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Status:', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(width: 8),
                PosjetaStatusBadge(naziv: posjeta.statusPosjeteNaziv),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow(label: 'Termin', value: formatDateTime(posjeta.datumVrijeme)),
            _DetailRow(label: 'Datum kreiranja', value: formatDateTime(posjeta.datumKreiranja)),
            if (posjeta.datumObrade != null)
              _DetailRow(label: 'Datum obrade', value: formatDateTime(posjeta.datumObrade!)),
            if (posjeta.napomena != null && posjeta.napomena!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Napomena', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(posjeta.napomena!),
            ],
            if (isOtkazana && posjeta.razlogOtkazivanja != null && posjeta.razlogOtkazivanja!.isNotEmpty) ...[
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
                      'Razlog otkazivanja',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      posjeta.razlogOtkazivanja!,
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
                label: const Text('Otkaži posjetu'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Confirmation dialog for cancelling a Posjeta - the reason is required, so unlike a plain
/// AlertDialog this validates before closing and shows the error below the field, only popping
/// with the trimmed reason once it's non-empty.
class _CancelReasonDialog extends StatefulWidget {
  const _CancelReasonDialog();

  @override
  State<_CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<_CancelReasonDialog> {
  final _reasonController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _confirm() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = 'Razlog otkazivanja je obavezan.');
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: const Text('Otkaži posjetu'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: LabeledField(
            label: 'Razlog otkazivanja',
            child: TextField(
              controller: _reasonController,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              maxLines: 3,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: 'Unesite razlog otkazivanja',
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Odustani')),
        FilledButton(onPressed: _confirm, child: const Text('Otkaži posjetu')),
      ],
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
