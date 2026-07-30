import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/widgets/error_banner.dart';
import '../application/donations_providers.dart';
import '../domain/potreba_azila.dart';
import 'donation_icons.dart';
import 'potreba_azila_style.dart';

/// Admin-curated "what the shelter currently needs" board - purely informational, never
/// editable by donors, shown above the Materijalna donation form to nudge donors toward items
/// the shelter actually needs right now.
class ShelterNeedsSection extends ConsumerWidget {
  const ShelterNeedsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final potrebeAsync = ref.watch(potrebeAzilaProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Šta azilu trenutno treba', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Ovo su trenutne potrebe azila - vaša donacija najviše pomaže ako odgovara nečemu sa ove liste.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
        ),
        const SizedBox(height: 12),
        potrebeAsync.when(
          loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => ErrorBanner(error: e),
          data: (potrebe) {
            if (potrebe.isEmpty) {
              return const Text('Azil trenutno nema posebno istaknutih potreba.');
            }
            return SizedBox(
              height: 148,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: potrebe.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) => _NeedCard(potreba: potrebe[index]),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _NeedCard extends StatelessWidget {
  const _NeedCard({required this.potreba});

  final PotrebaAzila potreba;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(donationIconFor(potreba.ikonaKljuc), color: const Color(0xFF008554)),
              PrioritetBadge(naziv: potreba.prioritetPotrebeNaziv),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            potreba.naziv,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              potreba.opis,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
