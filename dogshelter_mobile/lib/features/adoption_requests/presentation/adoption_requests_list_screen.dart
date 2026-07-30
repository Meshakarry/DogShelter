import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/core/date_format.dart';
import 'package:dogshelter_shared/core/image_url.dart';
import '../../../environment.dart';
import 'package:dogshelter_shared/widgets/error_banner.dart';
import '../application/adoption_requests_providers.dart';
import '../domain/zahtjev_za_udomljavanje.dart';
import 'zahtjev_status_style.dart';

// UI tab labels. "Svi" has no backing StatusZahtjeva row (null filter); the other three map to
// backend StatusZahtjeva.Naziv values below. Tab copy uses a friendlier adjective form while
// the card always shows the server's real Naziv text.
const _tabs = ['Svi', 'Na čekanju', 'Odobreno', 'Odbijeno'];

String? _realNazivFor(String tab) => switch (tab) {
      'Na čekanju' => 'Na čekanju',
      'Odobreno' => 'Odobren',
      'Odbijeno' => 'Odbijen',
      _ => null,
    };

class AdoptionRequestsListScreen extends ConsumerStatefulWidget {
  const AdoptionRequestsListScreen({super.key});

  @override
  ConsumerState<AdoptionRequestsListScreen> createState() => _AdoptionRequestsListScreenState();
}

class _AdoptionRequestsListScreenState extends ConsumerState<AdoptionRequestsListScreen> {
  final _scrollController = ScrollController();
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // zahtjevListProvider outlives this screen (survives navigating away and back, or a
    // logout/login), but _selectedTabIndex is fresh widget state that always starts at "Svi" -
    // without this reset the tab indicator could show "Svi" while the list is still silently
    // filtered by whatever tab was last selected in a previous visit.
    Future.microtask(() => ref.read(zahtjevListProvider.notifier).applyStatusFilter(null));
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(zahtjevListProvider.notifier).loadMore();
    }
  }

  void _onTabTap(int index) {
    setState(() => _selectedTabIndex = index);
    final tab = _tabs[index];
    final realNaziv = _realNazivFor(tab);
    if (realNaziv == null) {
      ref.read(zahtjevListProvider.notifier).applyStatusFilter(null);
      return;
    }
    final lookups = ref.read(statusZahtjevaLookupProvider).valueOrNull;
    final match = lookups?.where((s) => s.naziv == realNaziv).firstOrNull;
    ref.read(zahtjevListProvider.notifier).applyStatusFilter(match?.statusZahtjevaId);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(statusZahtjevaLookupProvider);
    final state = ref.watch(zahtjevListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text('Moji zahtjevi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onTabTap(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: i == _selectedTabIndex ? const Color(0xFFE5E7EB) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _tabs[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: i == _selectedTabIndex ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                            color: i == _selectedTabIndex ? Colors.black : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: ErrorBanner(error: state.error),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(zahtjevListProvider.notifier).loadFirstPage(),
            child: state.items.isEmpty && !state.isLoading
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: const [
                      SizedBox(height: 80),
                      Center(child: Text('Nema zahtjeva u ovoj kategoriji.')),
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
                      return _ZahtjevListTile(zahtjev: state.items[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _ZahtjevListTile extends StatelessWidget {
  const _ZahtjevListTile({required this.zahtjev});

  final ZahtjevZaUdomljavanje zahtjev;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveImageUrl(zahtjev.pasSlikaNaslovna, Environment.apiBaseUrl);
    final greyText = Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/zahtjevi/${zahtjev.zahtjevZaUdomljavanjeId}'),
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
                      zahtjev.pasNaziv ?? 'Nepoznat pas',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Datum:', style: greyText),
                        const SizedBox(width: 8),
                        Text(
                          formatDate(zahtjev.datumPodnosenja),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Status:', style: greyText),
                        ZahtjevStatusBadge(naziv: zahtjev.statusZahtjevaNaziv),
                      ],
                    ),
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
