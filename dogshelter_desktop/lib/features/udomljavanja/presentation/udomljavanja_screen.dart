import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/core/date_format.dart';
import 'package:dogshelter_shared/core/image_url.dart';
import 'package:dogshelter_shared/widgets/error_banner.dart';
import '../../../environment.dart';
import '../../../widgets/page_footer.dart';
import '../application/udomljavanja_providers.dart';

class UdomljavanjaScreen extends ConsumerWidget {
  const UdomljavanjaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(udomljavanjeListProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: ErrorBanner(error: error)),
              data: (result) {
                final items = result.items;
                if (items.isEmpty) return const Center(child: Text('Nema udomljavanja.'));
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final udomljavanje = items[index];
                      final imageUrl = resolveImageUrl(udomljavanje.pasSlikaNaslovna, Environment.apiBaseUrl);
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: imageUrl == null
                                ? Container(
                                    color: Theme.of(context).colorScheme.secondaryContainer,
                                    child: const Icon(Icons.pets),
                                  )
                                : Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Theme.of(context).colorScheme.secondaryContainer,
                                      child: const Icon(Icons.pets),
                                    ),
                                  ),
                          ),
                        ),
                        title: Text(
                          '${udomljavanje.pasNaziv} — ${udomljavanje.korisnikIme} ${udomljavanje.korisnikPrezime}',
                        ),
                        subtitle: Text(
                          'Udomljen: ${formatDate(udomljavanje.datumUdomljavanja)}'
                          '${udomljavanje.napomena != null ? ' · ${udomljavanje.napomena}' : ''}',
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          if (itemsAsync.valueOrNull != null && itemsAsync.value!.totalCount > 0) ...[
            const SizedBox(height: 12),
            PageFooter(
              page: itemsAsync.value!.page,
              totalPages: itemsAsync.value!.totalPages,
              totalCount: itemsAsync.value!.totalCount,
              onPageChanged: (page) => ref.read(udomljavanjeListProvider.notifier).goToPage(page),
            ),
          ],
        ],
      ),
    );
  }
}
