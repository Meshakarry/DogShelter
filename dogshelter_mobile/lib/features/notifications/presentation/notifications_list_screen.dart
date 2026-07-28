import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/date_format.dart';
import '../../../widgets/error_banner.dart';
import '../application/notifications_providers.dart';
import '../domain/notifikacija.dart';
import 'notification_type_style.dart';

const _tabs = ['Sve', 'Nepročitane'];

class NotificationsListScreen extends ConsumerStatefulWidget {
  const NotificationsListScreen({super.key});

  @override
  ConsumerState<NotificationsListScreen> createState() => _NotificationsListScreenState();
}

class _NotificationsListScreenState extends ConsumerState<NotificationsListScreen> {
  final _scrollController = ScrollController();
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // notifikacijaListProvider outlives this screen - reset the filter on every mount so the tab
    // indicator never desyncs from the notifier's actual filter, same fix as VisitsListScreen.
    Future.microtask(() => ref.read(notifikacijaListProvider.notifier).applyUnreadFilter(false));
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(notifikacijaListProvider.notifier).loadMore();
    }
  }

  void _onTabTap(int index) {
    setState(() => _selectedTabIndex = index);
    ref.read(notifikacijaListProvider.notifier).applyUnreadFilter(index == 1);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notifikacijaListProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Notifikacije', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                if (unreadCount > 0)
                  TextButton(
                    onPressed: () => ref.read(notifikacijaListProvider.notifier).markAllAsRead(),
                    child: const Text('Označi sve kao pročitano'),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
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
              onRefresh: () => ref.read(notifikacijaListProvider.notifier).loadFirstPage(),
              child: state.items.isEmpty && !state.isLoading
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text('Nema notifikacija u ovoj kategoriji.')),
                      ],
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: state.items.length + (state.hasMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (index >= state.items.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final notifikacija = state.items[index];
                        return _NotifikacijaTile(
                          notifikacija: notifikacija,
                          onTap: () => ref
                              .read(notifikacijaListProvider.notifier)
                              .markAsRead(notifikacija.notifikacijaId),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifikacijaTile extends StatelessWidget {
  const _NotifikacijaTile({required this.notifikacija, required this.onTap});

  final Notifikacija notifikacija;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = notificationTypeStyle(notifikacija.tip);
    final isUnread = !notifikacija.procitano;

    return Card(
      clipBehavior: Clip.antiAlias,
      // Card's default M3 background is already a tonal gray surface, so a plain semi-transparent
      // overlay muddies into an olive/mauve tone instead of a clean pastel - alphaBlend against an
      // explicit white base guarantees a crisp tint regardless of that underlying surface color.
      color: isUnread ? Color.alphaBlend(color.withValues(alpha: 0.10), Colors.white) : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notifikacija.naslov,
                            style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.w500),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8, top: 4),
                            decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(notifikacija.tekst, maxLines: 3, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(
                      formatDateTime(notifikacija.datumKreiranja),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
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
