import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_theme.dart';

class _PostavkeEntry {
  const _PostavkeEntry({required this.path, required this.icon, required this.label});

  final String path;
  final IconData icon;
  final String label;
}

/// Hub for every reference/lookup table's CRUD screens.
class PostavkeScreen extends StatelessWidget {
  const PostavkeScreen({super.key});

  static const _entries = [
    _PostavkeEntry(path: '/postavke/gradovi', icon: Icons.location_city_outlined, label: 'Gradovi'),
    _PostavkeEntry(path: '/postavke/rase', icon: Icons.pets_outlined, label: 'Rase pasa'),
    _PostavkeEntry(path: '/postavke/status-psa', icon: Icons.health_and_safety_outlined, label: 'Status psa'),
    _PostavkeEntry(path: '/postavke/velicina-psa', icon: Icons.straighten_outlined, label: 'Veličina psa'),
    _PostavkeEntry(path: '/postavke/tip-donacije', icon: Icons.category_outlined, label: 'Tip donacije'),
    _PostavkeEntry(
      path: '/postavke/kategorija-donacije',
      icon: Icons.widgets_outlined,
      label: 'Kategorije materijalnih donacija',
    ),
    _PostavkeEntry(path: '/postavke/jedinica-mjere', icon: Icons.scale_outlined, label: 'Jedinice mjere'),
    _PostavkeEntry(path: '/postavke/tip-aktivnosti', icon: Icons.task_outlined, label: 'Tip aktivnosti volontera'),
    _PostavkeEntry(path: '/postavke/prioritet-potrebe', icon: Icons.priority_high_outlined, label: 'Prioritet potrebe'),
    _PostavkeEntry(path: '/postavke/potreba-azila', icon: Icons.inventory_2_outlined, label: 'Potrebe azila'),
    _PostavkeEntry(path: '/postavke/status-zahtjeva', icon: Icons.assignment_turned_in_outlined, label: 'Status zahtjeva za udomljavanje'),
    _PostavkeEntry(path: '/postavke/status-posjete', icon: Icons.event_available_outlined, label: 'Status posjete'),
    _PostavkeEntry(path: '/postavke/status-donacije', icon: Icons.receipt_long_outlined, label: 'Status donacije'),
    _PostavkeEntry(path: '/postavke/uloge', icon: Icons.admin_panel_settings_outlined, label: 'Uloge korisnika'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.4,
        ),
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          final entry = _entries[index];
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              onTap: () => context.go(entry.path),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(entry.icon, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(entry.label, style: Theme.of(context).textTheme.titleSmall)),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
