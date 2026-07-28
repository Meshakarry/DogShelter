import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/date_format.dart';
import '../../../core/image_url.dart';
import '../../../widgets/error_banner.dart';
import '../application/visits_providers.dart';
import '../domain/posjeta.dart';
import 'book_visit_sheet.dart';
import 'posjeta_status_style.dart';

// Real StatusPosjete.Naziv values double as tab labels directly (unlike Zahtjev's tabs, these
// are already display-ready adjectives) - "Svi" has no backing row (null filter).
const _tabs = ['Svi', 'Na čekanju', 'Potvrđena', 'Otkazana', 'Završena'];

class VisitsListScreen extends ConsumerStatefulWidget {
  const VisitsListScreen({super.key});

  @override
  ConsumerState<VisitsListScreen> createState() => _VisitsListScreenState();
}

class _VisitsListScreenState extends ConsumerState<VisitsListScreen> {
  final _scrollController = ScrollController();
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // posjetaListProvider outlives this screen (survives navigating away and back, or a
    // logout/login) - reset the filter on every mount so the tab indicator never desyncs from
    // the notifier's actual filter, same fix applied to AdoptionRequestsListScreen.
    Future.microtask(() => ref.read(posjetaListProvider.notifier).applyStatusFilter(null));
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(posjetaListProvider.notifier).loadMore();
    }
  }

  void _onTabTap(int index) {
    setState(() => _selectedTabIndex = index);
    final tab = _tabs[index];
    if (tab == 'Svi') {
      ref.read(posjetaListProvider.notifier).applyStatusFilter(null);
      return;
    }
    final lookups = ref.read(statusPosjeteLookupProvider).valueOrNull;
    final match = lookups?.where((s) => s.naziv == tab).firstOrNull;
    ref.read(posjetaListProvider.notifier).applyStatusFilter(match?.statusPosjeteId);
  }

  Future<void> _bookGeneralVisit() async {
    final booked = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(),
      builder: (_) => const BookVisitSheet(),
    );
    if (booked == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Posjeta je zakazana.')));
      ref.read(posjetaListProvider.notifier).loadFirstPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(statusPosjeteLookupProvider);
    final state = ref.watch(posjetaListProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _bookGeneralVisit,
        icon: const Icon(Icons.add),
        label: const Text('Zakaži posjetu'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text('Moje posjete', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
                              fontSize: 12,
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
              onRefresh: () => ref.read(posjetaListProvider.notifier).loadFirstPage(),
              child: state.items.isEmpty && !state.isLoading
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text('Nema posjeta u ovoj kategoriji.')),
                      ],
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: state.items.length + (state.hasMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index >= state.items.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return _PosjetaListTile(posjeta: state.items[index]);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PosjetaListTile extends StatelessWidget {
  const _PosjetaListTile({required this.posjeta});

  final Posjeta posjeta;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveImageUrl(posjeta.pasSlikaNaslovna);
    final greyText = Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/posjete/${posjeta.posjetaId}'),
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
                      ? const ColoredBox(color: Color(0xFFE0E0E0), child: Icon(Icons.home_work_outlined))
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
                      posjeta.pasNaziv ?? 'Opća posjeta',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Termin:', style: greyText),
                        const SizedBox(width: 8),
                        Text(
                          formatDateTime(posjeta.datumVrijeme),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Status:', style: greyText),
                        PosjetaStatusBadge(naziv: posjeta.statusPosjeteNaziv),
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
