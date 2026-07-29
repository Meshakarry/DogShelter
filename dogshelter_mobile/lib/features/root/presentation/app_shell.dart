import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/app_title.dart';
import '../../notifications/application/notifications_providers.dart';
import 'app_drawer.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    (path: '/pocetna', icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Početna'),
    (path: '/dogs', icon: Icons.pets_outlined, selectedIcon: Icons.pets, label: 'Psi'),
    (path: '/zahtjevi', icon: Icons.assignment_outlined, selectedIcon: Icons.assignment, label: 'Zahtjevi'),
    (path: '/profil', icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profil'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = _tabs.indexWhere((tab) => location.startsWith(tab.path));
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = _currentIndex(context);
    final unreadCount = ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: AppTitle(onTap: () => context.go('/pocetna')),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
            tooltip: 'Notifikacije',
            onPressed: () => context.go('/notifikacije'),
          ),
          Builder(
            builder: (innerContext) => IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Meni',
              onPressed: () => Scaffold.of(innerContext).openDrawer(),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => context.go(_tabs[index].path),
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(icon: Icon(tab.icon), selectedIcon: Icon(tab.selectedIcon), label: tab.label),
        ],
      ),
    );
  }
}
