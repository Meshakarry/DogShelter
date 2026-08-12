import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/core/image_url.dart';
import '../../../environment.dart';
import 'package:dogshelter_shared/auth/application/auth_notifier.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final korisnik = ref.watch(authNotifierProvider).korisnik;
    final isVolonter = korisnik?.hasRole('Volonter') ?? false;
    final avatarUrl = resolveImageUrl(korisnik?.slikaPutanja, Environment.apiBaseUrl);
    final authToken = ref.watch(authTokenHolderProvider).token;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration:
                        BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHigh),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFFE0E0E0),
                          backgroundImage: avatarUrl == null
                              ? null
                              : CachedNetworkImageProvider(
                                  avatarUrl,
                                  headers: authToken == null ? null : {'Authorization': 'Bearer $authToken'},
                                ),
                          child: avatarUrl == null ? const Icon(Icons.person) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${korisnik?.ime ?? ''} ${korisnik?.prezime ?? ''}'.trim(),
                                style: Theme.of(context).textTheme.titleMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                korisnik?.email ?? '',
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _DrawerItem(icon: Icons.home_outlined, label: 'Početna', route: '/pocetna'),
                  _DrawerItem(icon: Icons.pets_outlined, label: 'Psi', route: '/dogs'),
                  _DrawerItem(
                      icon: Icons.assignment_outlined, label: 'Moji zahtjevi', route: '/zahtjevi'),
                  if (!isVolonter)
                    _DrawerItem(
                        icon: Icons.event_available_outlined,
                        label: 'Moje posjete',
                        route: '/posjete'),
                  _DrawerItem(
                      icon: Icons.volunteer_activism_outlined,
                      label: 'Donacije',
                      route: '/donacije'),
                  _DrawerItem(
                      icon: Icons.campaign_outlined, label: 'Obavijesti', route: '/obavijesti'),
                  _DrawerItem(
                      icon: Icons.notifications_outlined,
                      label: 'Notifikacije',
                      route: '/notifikacije'),
                  _DrawerItem(icon: Icons.event_outlined, label: 'Događaji', route: '/dogadjaji'),
                  if (isVolonter) ...[
                    const Divider(),
                    _DrawerItem(
                        icon: Icons.timer_outlined,
                        label: 'Moje aktivnosti',
                        route: '/aktivnosti'),
                  ],
                  const Divider(),
                  _DrawerItem(icon: Icons.person_outline, label: 'Profil', route: '/profil'),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(color: Theme.of(context).colorScheme.error),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    ref.read(authNotifierProvider.notifier).logout();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Odjava'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({required this.icon, required this.label, required this.route});

  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.of(context).pop();
        context.go(route);
      },
    );
  }
}
