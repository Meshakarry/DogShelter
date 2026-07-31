import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/core/image_url.dart';
import '../../../environment.dart';
import 'package:dogshelter_shared/core/text_normalize.dart';
import 'package:dogshelter_shared/widgets/error_banner.dart';
import 'package:dogshelter_shared/pas/domain/pas_list_item.dart';
import '../application/dogs_providers.dart';
import 'dog_filter_sheet.dart';
import 'dog_status_style.dart';

const _fieldRadius = BorderRadius.all(Radius.circular(6));
final _fieldShape = RoundedRectangleBorder(borderRadius: _fieldRadius);

class DogListScreen extends ConsumerStatefulWidget {
  const DogListScreen({super.key});

  @override
  ConsumerState<DogListScreen> createState() => _DogListScreenState();
}

class _DogListScreenState extends ConsumerState<DogListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Warm the breed/status/size lookups now, not lazily when Filteri opens - otherwise the very
    // first breed search (before Filteri is ever opened) has nothing to match against yet.
    ref.read(dogLookupsProvider);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(dogsListProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final query = value.trim();
      // Breed filtering stays dropdown-driven since rasaId is a foreign key, not free text;
      // this just recognizes when typed text matches (partially, diacritic-insensitively) a
      // known breed and applies the same rasaId filter the dropdown would, as a convenience
      // on top of it.
      final lookups = ref.read(dogLookupsProvider).valueOrNull;
      final normalizedQuery = normalizeForSearch(query);
      final matchedRasa = query.isEmpty
          ? null
          : lookups?.rase
              .where((r) => normalizeForSearch(r.naziv).contains(normalizedQuery))
              .firstOrNull;

      final notifier = ref.read(dogsListProvider.notifier);
      final currentFilters = ref.read(dogsListProvider).filters;
      if (matchedRasa != null) {
        notifier.applyFilters(currentFilters.copyWith(rasaId: matchedRasa.rasaId, clearNaziv: true));
      } else {
        notifier.applyFilters(
          currentFilters.copyWith(naziv: query, clearNaziv: query.isEmpty, clearRasaId: true),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dogsListProvider);
    final hasActiveFilters = !state.filters.isEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Pretraži po imenu i rasi',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(borderRadius: _fieldRadius),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(shape: _fieldShape),
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const DogFilterSheet(),
                  ),
                  icon: Icon(hasActiveFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
                  label: const Text('Filteri'),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              state.totalCount != null
                  ? 'Prikazano ${state.items.length} od ${state.totalCount} pasa'
                  : 'Trenutno je prikazano ${state.items.length} pasa',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ErrorBanner(error: state.error),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(dogsListProvider.notifier).loadFirstPage(),
            child: state.items.isEmpty && !state.isLoading
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: const [
                      SizedBox(height: 80),
                      Center(child: Text('Nema pronađenih pasa.')),
                    ],
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.items.length + (state.hasMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index >= state.items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _DogListTile(dog: state.items[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _DogListTile extends StatelessWidget {
  const _DogListTile({required this.dog});

  final PasListItem dog;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveImageUrl(dog.slikaNaslovna, Environment.apiBaseUrl);
    final greyText = Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/dogs/${dog.pasId}'),
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
                      dog.naziv,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (dog.rasaNaziv != null) ...[
                      const SizedBox(height: 2),
                      Text(dog.rasaNaziv!, style: greyText),
                    ],
                    if (dog.ageLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(dog.ageLabel!, style: greyText),
                    ],
                    if (dog.statusNaziv != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        dog.statusNaziv!,
                        style: TextStyle(fontWeight: FontWeight.bold, color: dogStatusColor(dog.statusNaziv)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
