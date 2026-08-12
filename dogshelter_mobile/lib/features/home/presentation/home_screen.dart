import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/core/image_url.dart';
import '../../../environment.dart';
import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import 'package:dogshelter_shared/obavijest/domain/obavijest_list_item.dart';
import 'package:dogshelter_shared/preporuke/application/preporuke_providers.dart';
import 'package:dogshelter_shared/preporuke/domain/preporuceni_pas.dart';
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
      (icon: Icons.volunteer_activism, label: 'Donacije', route: '/donacije', color: const Color(0xFFDB2777)),
      (icon: Icons.campaign, label: 'Obavijesti', route: '/obavijesti', color: const Color(0xFFD97706)),
      (icon: Icons.notifications, label: 'Notifikacije', route: '/notifikacije', color: const Color(0xFF0891B2)),
      (icon: Icons.event, label: 'Događaji', route: '/dogadjaji', color: const Color(0xFF65A30D)),
      if (isVolonter)
        (icon: Icons.timer, label: 'Moje aktivnosti', route: '/aktivnosti', color: const Color(0xFF7C3AED))
      else
        (icon: Icons.event_available, label: 'Moje posjete', route: '/posjete', color: const Color(0xFF9333EA)),
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
    final dogsAsync = ref.watch(preporuceniPsiProvider);
    final obavijestiAsync = ref.watch(latestObavijestiProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dogsAsync.when(
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(title: 'Preporučeno za vas'),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
          error: (_, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(title: 'Preporučeno za vas'),
              const SizedBox(height: 8),
              const Text('Greška pri učitavanju.'),
            ],
          ),
          data: (dogs) => dogs.isEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(title: 'Preporučeno za vas'),
                    const SizedBox(height: 8),
                    const Text('Trenutno nema pasa za prikaz.'),
                  ],
                )
              : _RecommendedCarousel(dogs: dogs),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold));
  }
}

/// Horizontally scrollable recommendation carousel with prev/next arrows on the header row.
class _RecommendedCarousel extends StatefulWidget {
  const _RecommendedCarousel({required this.dogs});

  final List<PreporuceniPas> dogs;

  @override
  State<_RecommendedCarousel> createState() => _RecommendedCarouselState();
}

class _RecommendedCarouselState extends State<_RecommendedCarousel> {
  final _scrollController = ScrollController();
  static const _cardWidth = 200.0;
  static const _cardSpacing = 12.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollBy(double direction) {
    if (!_scrollController.hasClients) return;
    final target = (_scrollController.offset + direction * (_cardWidth + _cardSpacing) * 1.5)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(target, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final arrowColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionTitle(title: 'Preporučeno za vas'),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  color: arrowColor,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _scrollBy(-1),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  color: arrowColor,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _scrollBy(1),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < widget.dogs.length; i++) ...[
                  if (i > 0) const SizedBox(width: _cardSpacing),
                  _RecommendedDogCard(dog: widget.dogs[i]),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RecommendedDogCard extends StatelessWidget {
  const _RecommendedDogCard({required this.dog});

  final PreporuceniPas dog;

  /// Splits the backend's joined "Clause one; clause two." razlog into separate,
  /// fully-visible bullet lines instead of truncating it to fit a fixed height.
  List<String> get _razlogClauses {
    var text = dog.razlog.trim();
    if (text.endsWith('.')) text = text.substring(0, text.length - 1);
    return text.split('; ').where((c) => c.isNotEmpty).map((c) => c[0].toUpperCase() + c.substring(1)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveImageUrl(dog.slikaNaslovna, Environment.apiBaseUrl);

    return SizedBox(
      width: 200,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/dogs/${dog.pasId}'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 90,
                    width: double.infinity,
                    child: imageUrl == null
                        ? const ColoredBox(color: Color(0xFFE0E0E0), child: Icon(Icons.pets))
                        : CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
                  ),
                  if (!dog.personalizovano)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Popularno', style: TextStyle(fontSize: 10, color: Colors.white)),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dog.naziv, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    Text(
                      '${dog.rasaNaziv} · ${dog.velicinaNaziv}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    for (final clause in _razlogClauses)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 4, right: 4),
                              child: Icon(Icons.circle, size: 4, color: Color(0xFF6B7280)),
                            ),
                            Expanded(
                              child: Text(
                                clause,
                                style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                              ),
                            ),
                          ],
                        ),
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
