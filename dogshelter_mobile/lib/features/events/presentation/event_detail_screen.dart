import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/date_format.dart';
import '../../../core/image_url.dart';
import '../../../core/pluralize.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/status_pill.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/events_providers.dart';
import '../domain/dogadjaj.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.dogadjajId});

  final int dogadjajId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dogadjajAsync = ref.watch(eventDetailProvider(dogadjajId));

    return Scaffold(
      appBar: AppBar(title: const Text('Događaj')),
      body: dogadjajAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: ErrorBanner(error: e)),
        data: (dogadjaj) => _EventDetailBody(dogadjaj: dogadjaj),
      ),
    );
  }
}

class _EventDetailBody extends ConsumerWidget {
  const _EventDetailBody({required this.dogadjaj});

  final Dogadjaj dogadjaj;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = resolveImageUrl(dogadjaj.slikaPutanja);
    // Only volunteers can ever be "zadužen" for an event, and GET /api/DogadjajVolonter is
    // Admin+Volonter only - skip the call entirely for a plain Korisnik rather than firing a
    // request that would just 403.
    final isVolonter = ref.watch(authNotifierProvider).korisnik?.hasRole('Volonter') ?? false;
    final isZaduzen = isVolonter && (ref.watch(isZaduzenProvider(dogadjaj.dogadjajId)).valueOrNull ?? false);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: imageUrl == null
                    ? const ColoredBox(color: Color(0xFFE0E0E0), child: Icon(Icons.event, size: 48))
                    : CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dogadjaj.naziv,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (isZaduzen) const StatusPill(label: 'Zaduženi ste', color: Color(0xFFDCFCE7)),
                    StatusPill(
                      label: pluralize(
                        dogadjaj.brojZaduzenihVolontera,
                        one: 'zadužen volonter',
                        few: 'zadužena volontera',
                        many: 'zaduženih volontera',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailRow(icon: Icons.calendar_today, label: 'Termin', value: formatDateTime(dogadjaj.datum)),
                _DetailRow(icon: Icons.location_on_outlined, label: 'Lokacija', value: dogadjaj.lokacija),
                if (dogadjaj.opis != null && dogadjaj.opis!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Opis', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(dogadjaj.opis!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6B7280)),
          const SizedBox(width: 8),
          SizedBox(width: 96, child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
