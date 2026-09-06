import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/core/image_url.dart';
import '../../../environment.dart';
import 'package:dogshelter_shared/favorit/application/favorit_providers.dart';
import 'package:dogshelter_shared/favorit/domain/favorit.dart';
import 'package:dogshelter_shared/widgets/error_banner.dart';
import 'package:dogshelter_shared/widgets/status_pill.dart';
import 'dog_status_style.dart';

class FavoritiListScreen extends ConsumerWidget {
  const FavoritiListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritiAsync = ref.watch(favoritListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Moji favoriti')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(favoritListProvider.notifier).refresh(),
        child: favoritiAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [ErrorBanner(error: e)],
          ),
          data: (favoriti) => favoriti.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(24),
                  children: const [
                    SizedBox(height: 80),
                    Center(child: Text('Još niste dodali nijednog psa u favorite.')),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: favoriti.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _FavoritTile(favorit: favoriti[index]),
                ),
        ),
      ),
    );
  }
}

class _FavoritTile extends ConsumerWidget {
  const _FavoritTile({required this.favorit});

  final Favorit favorit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = resolveImageUrl(favorit.slikaNaslovna, Environment.apiBaseUrl);
    final greyText = Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/dogs/${favorit.pasId}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: imageUrl == null
                      ? const ColoredBox(color: Color(0xFFE0E0E0), child: Icon(Icons.pets))
                      : CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) =>
                              const ColoredBox(color: Color(0xFFE0E0E0), child: Icon(Icons.pets)),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      favorit.pasNaziv,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (favorit.rasaNaziv != null) ...[
                      const SizedBox(height: 2),
                      Text(favorit.rasaNaziv!, style: greyText),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (favorit.statusNaziv != null)
                          Text(
                            favorit.statusNaziv!,
                            style: TextStyle(fontWeight: FontWeight.bold, color: dogStatusColor(favorit.statusNaziv)),
                          ),
                        if (!favorit.pasAktivan) const StatusPill(label: 'Neaktivan'),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.favorite, color: Color(0xFFE53935)),
                tooltip: 'Ukloni iz favorita',
                onPressed: () => ref.read(favoritListProvider.notifier).toggle(favorit.pasId),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
