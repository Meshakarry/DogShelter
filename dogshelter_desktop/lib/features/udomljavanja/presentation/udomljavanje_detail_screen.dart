import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/core/date_format.dart';
import 'package:dogshelter_shared/core/image_url.dart';
import 'package:dogshelter_shared/widgets/error_banner.dart';
import '../../../environment.dart';
import '../../../widgets/detail_row.dart';
import '../application/udomljavanja_providers.dart';

/// Dedicated /udomljavanja/:id page - read-only: Udomljavanje has no write endpoints, since it
/// only ever comes into being as a side effect of Zahtjev.Odobri.
class UdomljavanjeDetailScreen extends ConsumerWidget {
  const UdomljavanjeDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(udomljavanjeDetailProvider(id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 24, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Nazad',
                onPressed: () => context.go('/udomljavanja'),
              ),
              Text('Detalji udomljavanja', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
        Expanded(
          child: detailAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: ErrorBanner(error: error)),
            data: (udomljavanje) {
              final imageUrl = resolveImageUrl(udomljavanje.pasSlikaNaslovna, Environment.apiBaseUrl);

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 84,
                                    height: 84,
                                    child: imageUrl == null
                                        ? Container(
                                            color: Theme.of(context).colorScheme.secondaryContainer,
                                            child: const Icon(Icons.pets, size: 32),
                                          )
                                        : Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: Theme.of(context).colorScheme.secondaryContainer,
                                              child: const Icon(Icons.pets, size: 32),
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        udomljavanje.pasNaziv ?? '-',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${udomljavanje.korisnikIme} ${udomljavanje.korisnikPrezime}',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            DetailRow(label: 'Datum udomljenja', value: formatDate(udomljavanje.datumUdomljavanja)),
                            DetailRow(label: 'Napomena', value: udomljavanje.napomena ?? '-'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

