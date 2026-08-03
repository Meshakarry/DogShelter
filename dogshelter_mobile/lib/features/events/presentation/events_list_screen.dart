import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/core/date_format.dart';
import 'package:dogshelter_shared/core/image_url.dart';
import '../../../environment.dart';
import 'package:dogshelter_shared/core/pluralize.dart';
import 'package:dogshelter_shared/widgets/error_banner.dart';
import 'package:dogshelter_shared/dogadjaj/domain/dogadjaj.dart';
import '../application/events_providers.dart';

const _tabs = [(label: 'Nadolazeći', tab: EventsTab.nadolazeci), (label: 'Prošli', tab: EventsTab.prosli)];

class EventsListScreen extends ConsumerStatefulWidget {
  const EventsListScreen({super.key});

  @override
  ConsumerState<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends ConsumerState<EventsListScreen> {
  final _scrollController = ScrollController();
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // eventsListProvider outlives this screen - reset the tab on every mount so the tab
    // indicator never desyncs from the notifier's actual tab.
    Future.microtask(() => ref.read(eventsListProvider.notifier).applyTab(EventsTab.nadolazeci));
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(eventsListProvider.notifier).loadMore();
    }
  }

  void _onTabTap(int index) {
    setState(() => _selectedTabIndex = index);
    ref.read(eventsListProvider.notifier).applyTab(_tabs[index].tab);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventsListProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 1)),
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
                          _tabs[i].label,
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
            onRefresh: () => ref.read(eventsListProvider.notifier).loadFirstPage(),
            child: state.items.isEmpty && !state.isLoading
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 80),
                      Center(
                        child: Text(
                          state.tab == EventsTab.nadolazeci
                              ? 'Trenutno nema predstojećih događaja.'
                              : 'Nema prošlih događaja.',
                        ),
                      ),
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
                      return _DogadjajListTile(dogadjaj: state.items[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _DogadjajListTile extends StatelessWidget {
  const _DogadjajListTile({required this.dogadjaj});

  final Dogadjaj dogadjaj;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveImageUrl(dogadjaj.slikaPutanja, Environment.apiBaseUrl);
    final greyText = Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/dogadjaji/${dogadjaj.dogadjajId}'),
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
                      ? const ColoredBox(color: Color(0xFFE0E0E0), child: Icon(Icons.event))
                      : CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) =>
                              const ColoredBox(color: Color(0xFFE0E0E0), child: Icon(Icons.event)),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dogadjaj.naziv,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Color(0xFF6B7280)),
                        const SizedBox(width: 4),
                        Text(formatDateTime(dogadjaj.datum), style: greyText),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF6B7280)),
                        const SizedBox(width: 4),
                        Expanded(child: Text(dogadjaj.lokacija, style: greyText, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pluralize(
                        dogadjaj.brojZaduzenihVolontera,
                        one: 'zadužen volonter',
                        few: 'zadužena volontera',
                        many: 'zaduženih volontera',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF65A30D)),
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
