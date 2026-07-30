import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/core/date_format.dart';
import 'package:dogshelter_shared/widgets/error_banner.dart';
import '../application/donations_providers.dart';
import '../domain/donacija.dart';
import 'donation_status_style.dart';

// Real StatusDonacije.Naziv values double as tab labels directly. "Svi" has no backing row
// (null filter).
const _tabs = ['Svi', 'Na čekanju', 'Uspješna', 'Neuspješna', 'Vraćena'];

class DonationsListScreen extends ConsumerStatefulWidget {
  const DonationsListScreen({super.key});

  @override
  ConsumerState<DonationsListScreen> createState() => _DonationsListScreenState();
}

class _DonationsListScreenState extends ConsumerState<DonationsListScreen> {
  final _scrollController = ScrollController();
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // donacijaListProvider outlives this screen (survives navigating away and back, or a
    // logout/login) - reset the filter on every mount so the tab indicator doesn't desync
    // from a stale filter.
    Future.microtask(() => ref.read(donacijaListProvider.notifier).applyStatusFilter(null));
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(donacijaListProvider.notifier).loadMore();
    }
  }

  void _onTabTap(int index) {
    setState(() => _selectedTabIndex = index);
    final tab = _tabs[index];
    if (tab == 'Svi') {
      ref.read(donacijaListProvider.notifier).applyStatusFilter(null);
      return;
    }
    final lookups = ref.read(statusDonacijeLookupProvider).valueOrNull;
    final match = lookups?.where((s) => s.naziv == tab).firstOrNull;
    ref.read(donacijaListProvider.notifier).applyStatusFilter(match?.statusDonacijeId);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(statusDonacijeLookupProvider);
    final state = ref.watch(donacijaListProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/donacije/nova'),
        icon: const Icon(Icons.add),
        label: const Text('Nova donacija'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text('Donacije', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
              onRefresh: () => ref.read(donacijaListProvider.notifier).loadFirstPage(),
              child: state.items.isEmpty && !state.isLoading
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text('Nema donacija u ovoj kategoriji.')),
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
                        return _DonacijaListTile(donacija: state.items[index]);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonacijaListTile extends StatelessWidget {
  const _DonacijaListTile({required this.donacija});

  final Donacija donacija;

  @override
  Widget build(BuildContext context) {
    final greyText = Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/donacije/${donacija.donacijaId}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        donacija.isNovcana ? Icons.payments_outlined : Icons.card_giftcard_outlined,
                        color: const Color(0xFF008554),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        donacija.tipDonacijeNaziv ?? 'Donacija',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (donacija.iznos != null)
                    Text(
                      '${donacija.iznos!.toStringAsFixed(2)} KM',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Datum:', style: greyText),
                  const SizedBox(width: 8),
                  Text(formatDate(donacija.datumDonacije), style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Status:', style: greyText),
                  DonacijaStatusBadge(naziv: donacija.statusDonacijeNaziv),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
