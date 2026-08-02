import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/core/date_format.dart';
import 'package:dogshelter_shared/notifications/application/notifications_providers.dart';
import 'package:dogshelter_shared/notifications/domain/notifikacija.dart';
import 'package:dogshelter_shared/notifications/widgets/notification_type_style.dart';
import 'package:dogshelter_shared/widgets/error_banner.dart';

class NotifikacijeScreen extends ConsumerStatefulWidget {
  const NotifikacijeScreen({super.key});

  @override
  ConsumerState<NotifikacijeScreen> createState() => _NotifikacijeScreenState();
}

class _NotifikacijeScreenState extends ConsumerState<NotifikacijeScreen> {
  final _scrollController = ScrollController();
  bool _onlyUnread = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notifikacijaListProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FilterChip(
                label: const Text('Sve'),
                selected: !_onlyUnread,
                onSelected: (_) {
                  setState(() => _onlyUnread = false);
                  ref.read(notifikacijaListProvider.notifier).applyUnreadFilter(false);
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Nepročitane'),
                selected: _onlyUnread,
                onSelected: (_) {
                  setState(() => _onlyUnread = true);
                  ref.read(notifikacijaListProvider.notifier).applyUnreadFilter(true);
                },
              ),
              const Spacer(),
              if (unreadCount > 0)
                TextButton.icon(
                  onPressed: () => ref.read(notifikacijaListProvider.notifier).markAllAsRead(),
                  icon: const Icon(Icons.done_all),
                  label: const Text('Označi sve kao pročitano'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.error != null) ErrorBanner(error: state.error),
          Expanded(
            child: state.items.isEmpty && !state.isLoading
                ? const Center(child: Text('Nema notifikacija u ovoj kategoriji.'))
                : ListView.separated(
                    controller: _scrollController,
                    itemCount: state.items.length + (state.hasMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
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
                        onTap: () =>
                            ref.read(notifikacijaListProvider.notifier).markAsRead(notifikacija.notifikacijaId),
                      );
                    },
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
      color: isUnread ? Color.alphaBlend(color.withValues(alpha: 0.08), Theme.of(context).colorScheme.surface) : null,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          notifikacija.naslov,
          style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.w500),
        ),
        subtitle: Text('${notifikacija.tekst}\n${formatDateTime(notifikacija.datumKreiranja)}'),
        isThreeLine: true,
        trailing: isUnread
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
              )
            : null,
      ),
    );
  }
}
