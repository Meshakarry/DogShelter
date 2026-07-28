import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/date_format.dart';
import '../../../core/image_url.dart';
import '../../../widgets/error_banner.dart';
import '../application/news_providers.dart';
import '../domain/obavijest.dart';

class NewsDetailScreen extends ConsumerWidget {
  const NewsDetailScreen({super.key, required this.obavijestId});

  final int obavijestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final obavijestAsync = ref.watch(obavijestDetailProvider(obavijestId));

    return Scaffold(
      appBar: AppBar(title: const Text('Obavijest')),
      body: obavijestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: ErrorBanner(error: e)),
        data: (obavijest) => _NewsDetailBody(obavijest: obavijest),
      ),
    );
  }
}

class _NewsDetailBody extends StatelessWidget {
  const _NewsDetailBody({required this.obavijest});

  final Obavijest obavijest;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveImageUrl(obavijest.slikaPutanja);
    final autor = [obavijest.autorIme, obavijest.autorPrezime].where((s) => s != null && s.isNotEmpty).join(' ');

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
                    ? const ColoredBox(color: Color(0xFFE0E0E0), child: Icon(Icons.campaign, size: 48))
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
                  obavijest.naslov,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Text(
                      formatDate(obavijest.datumObjave),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
                    ),
                    if (autor.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      const Icon(Icons.person, size: 16, color: Color(0xFF6B7280)),
                      const SizedBox(width: 6),
                      Text(autor, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280))),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Text(obavijest.sadrzaj, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
