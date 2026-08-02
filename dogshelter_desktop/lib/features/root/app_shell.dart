import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import 'package:dogshelter_shared/auth/domain/korisnik.dart';
import 'package:dogshelter_shared/notifications/application/notifications_providers.dart';
import '../../core/app_theme.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _items = [
    (path: '/pocetna', icon: Icons.space_dashboard_outlined, label: 'Početna'),
    (path: '/psi', icon: Icons.pets_outlined, label: 'Psi'),
    (path: '/zahtjevi', icon: Icons.assignment_outlined, label: 'Zahtjevi za udomljavanje'),
    (path: '/udomljavanja', icon: Icons.home_outlined, label: 'Udomljavanja'),
    (path: '/posjete', icon: Icons.event_available_outlined, label: 'Posjete'),
    (path: '/donacije', icon: Icons.volunteer_activism_outlined, label: 'Donacije'),
    (path: '/volonteri', icon: Icons.groups_outlined, label: 'Volonteri'),
    (path: '/obavijesti', icon: Icons.campaign_outlined, label: 'Obavijesti'),
    (path: '/dogadjaji', icon: Icons.event_outlined, label: 'Događaji'),
    (path: '/izvjestaji', icon: Icons.bar_chart_outlined, label: 'Izvještaji'),
    (path: '/korisnici', icon: Icons.person_outline, label: 'Korisnici'),
    (path: '/postavke', icon: Icons.settings_outlined, label: 'Postavke'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = _items.indexWhere((item) => location.startsWith(item.path));
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = _currentIndex(context);
    final korisnik = ref.watch(authNotifierProvider).korisnik;

    return Scaffold(
      body: Row(
        children: [
          _Sidebar(currentIndex: currentIndex, items: _items),
          Expanded(
            child: Column(
              children: [
                _TopBar(title: _items[currentIndex].label, korisnik: korisnik),
                const Divider(height: 1),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.currentIndex, required this.items});

  final int currentIndex;
  final List<({String path, IconData icon, String label})> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: AppTheme.sidebarBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              children: [
                Icon(Icons.pets, color: AppTheme.sidebarForeground),
                SizedBox(width: 10),
                Text(
                  'Azil Bugojno',
                  style: TextStyle(
                    color: AppTheme.sidebarForeground,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final selected = index == currentIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: Material(
                    color: selected ? AppTheme.seedColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => context.go(item.path),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 20,
                              color: selected ? Colors.white : AppTheme.sidebarMuted,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  color: selected ? Colors.white : AppTheme.sidebarForeground,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsBell extends ConsumerWidget {
  const _NotificationsBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0;

    return IconButton(
      tooltip: 'Notifikacije',
      onPressed: () => context.go('/notifikacije'),
      icon: Badge(
        label: Text('$unreadCount'),
        isLabelVisible: unreadCount > 0,
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.title, required this.korisnik});

  final String title;
  final Korisnik? korisnik;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          _NotificationsBell(),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'odjava') {
                ref.read(authNotifierProvider.notifier).logout();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'odjava', child: Text('Odjava')),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.seedColor.withValues(alpha: 0.15),
                  child: const Icon(Icons.person, color: AppTheme.seedColor, size: 18),
                ),
                const SizedBox(width: 8),
                Text(korisnik?.ime ?? 'Admin'),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
