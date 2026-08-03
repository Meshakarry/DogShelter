import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/core/image_url.dart';
import '../../../environment.dart';
import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import 'package:dogshelter_shared/pas/domain/pas_list_item.dart';
import '../../dogs/presentation/dog_status_style.dart';
import 'package:dogshelter_shared/obavijest/domain/obavijest_list_item.dart';
import '../application/home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final korisnik = ref.watch(authNotifierProvider).korisnik;
    final isVolonter = korisnik?.hasRole('Volonter') ?? false;

    final shortcuts = [
      (icon: Icons.pets, label: 'Pregled pasa', route: '/dogs', color: const Color(0xFF008554)),
      (icon: Icons.assignment, label: 'Moji zahtjevi', route: '/zahtjevi', color: const Color(0xFF2563EB)),
      (icon: Icons.event_available, label: 'Moje posjete', route: '/posjete', color: const Color(0xFF9333EA)),
      (icon: Icons.volunteer_activism, label: 'Donacije', route: '/donacije', color: const Color(0xFFDB2777)),
      (icon: Icons.campaign, label: 'Obavijesti', route: '/obavijesti', color: const Color(0xFFD97706)),
      (icon: Icons.notifications, label: 'Notifikacije', route: '/notifikacije', color: const Color(0xFF0891B2)),
      (icon: Icons.event, label: 'Događaji', route: '/dogadjaji', color: const Color(0xFF65A30D)),
      if (isVolonter)
        (icon: Icons.timer, label: 'Moje aktivnosti', route: '/aktivnosti', color: const Color(0xFF7C3AED)),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dobrodošli${korisnik == null ? '' : ', ${korisnik.ime}'}!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Šta biste željeli danas uraditi?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280)),
          ),
          const SizedBox(height: 20),
          if (isVolonter) const _VolonterStatsSection() else const _KorisnikPreviewSection(),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [for (final s in shortcuts) _ShortcutCard(shortcut: s)],
          ),
        ],
      ),
    );
  }
}

class _VolonterStatsSection extends ConsumerWidget {
  const _VolonterStatsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(volonterDashboardProvider);

    return dashboardAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (dashboard) {
        final profile = dashboard.profile;
        if (profile == null) return const SizedBox.shrink();

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.timer,
                label: 'Ukupno sati',
                value: profile.ukupnoSati.toStringAsFixed(1),
                color: const Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.task_alt,
                label: 'Aktivnosti',
                value: '${dashboard.activityCount}',
                color: const Color(0xFF008554),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.calendar_today,
                label: 'Volonter od',
                value: '${profile.datumPridruzivanja.year}',
                color: const Color(0xFF2563EB),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}

class _KorisnikPreviewSection extends ConsumerWidget {
  const _KorisnikPreviewSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dogsAsync = ref.watch(recommendedDogsProvider);
    final obavijestiAsync = ref.watch(latestObavijestiProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preporučeni psi', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 168,
          child: dogsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Center(child: Text('Greška pri učitavanju.')),
            data: (dogs) => dogs.isEmpty
                ? const Center(child: Text('Trenutno nema pasa za prikaz.'))
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: dogs.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => _RecommendedDogCard(dog: dogs[index]),
                  ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Najnovije obavijesti', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        obavijestiAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const Text('Greška pri učitavanju.'),
          data: (items) => items.isEmpty
              ? const Text('Trenutno nema obavijesti.')
              : Column(children: [for (final o in items) _ObavijestPreviewTile(obavijest: o)]),
        ),
      ],
    );
  }
}

class _RecommendedDogCard extends StatelessWidget {
  const _RecommendedDogCard({required this.dog});

  final PasListItem dog;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveImageUrl(dog.slikaNaslovna, Environment.apiBaseUrl);

    return SizedBox(
      width: 130,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/dogs/${dog.pasId}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 90,
                width: double.infinity,
                child: imageUrl == null
                    ? const ColoredBox(color: Color(0xFFE0E0E0), child: Icon(Icons.pets))
                    : CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dog.naziv, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    if (dog.statusNaziv != null)
                      Text(
                        dog.statusNaziv!,
                        style: TextStyle(fontSize: 12, color: dogStatusColor(dog.statusNaziv)),
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

class _ObavijestPreviewTile extends StatelessWidget {
  const _ObavijestPreviewTile({required this.obavijest});

  final ObavijestListItem obavijest;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveImageUrl(obavijest.slikaPutanja, Environment.apiBaseUrl);
    final date = obavijest.datumObjave;
    final dateLabel = '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}.';

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.push('/obavijesti/${obavijest.obavijestId}'),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: CachedNetworkImage(imageUrl: imageUrl!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(obavijest.naslov, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(dateLabel, style: TextStyle(fontSize: 12, color: const Color(0xFF6B7280))),
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

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({required this.shortcut});

  final ({IconData icon, String label, String route, Color color}) shortcut;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(shortcut.route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(shortcut.icon, color: shortcut.color, size: 32),
              Text(
                shortcut.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
