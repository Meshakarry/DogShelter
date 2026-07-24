import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/error_banner.dart';
import '../application/dogs_providers.dart';

class DogFilterSheet extends ConsumerStatefulWidget {
  const DogFilterSheet({super.key});

  @override
  ConsumerState<DogFilterSheet> createState() => _DogFilterSheetState();
}

class _DogFilterSheetState extends ConsumerState<DogFilterSheet> {
  int? _rasaId;
  int? _statusPsaId;
  int? _velicinaPsaId;

  @override
  void initState() {
    super.initState();
    final current = ref.read(dogsListProvider).filters;
    _rasaId = current.rasaId;
    _statusPsaId = current.statusPsaId;
    _velicinaPsaId = current.velicinaPsaId;
  }

  @override
  Widget build(BuildContext context) {
    final lookupsAsync = ref.watch(dogLookupsProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: lookupsAsync.when(
          loading: () => const SizedBox(height: 160, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => SizedBox(height: 160, child: Center(child: ErrorBanner(error: e))),
          data: (lookups) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filteri', style: Theme.of(context).textTheme.titleLarge),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _rasaId,
                decoration: const InputDecoration(labelText: 'Rasa'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Sve rase')),
                  for (final rasa in lookups.rase)
                    DropdownMenuItem(value: rasa.rasaId, child: Text(rasa.naziv)),
                ],
                onChanged: (value) => setState(() => _rasaId = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _statusPsaId,
                decoration: const InputDecoration(labelText: 'Status'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Svi statusi')),
                  for (final status in lookups.statusi)
                    DropdownMenuItem(value: status.statusPsaId, child: Text(status.naziv)),
                ],
                onChanged: (value) => setState(() => _statusPsaId = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _velicinaPsaId,
                decoration: const InputDecoration(labelText: 'Veličina'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Sve veličine')),
                  for (final velicina in lookups.velicine)
                    DropdownMenuItem(value: velicina.velicinaPsaId, child: Text(velicina.naziv)),
                ],
                onChanged: (value) => setState(() => _velicinaPsaId = value),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        _rasaId = null;
                        _statusPsaId = null;
                        _velicinaPsaId = null;
                      }),
                      child: const Text('Poništi'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        ref.read(dogsListProvider.notifier).applyFilters(DogFilters(
                              rasaId: _rasaId,
                              statusPsaId: _statusPsaId,
                              velicinaPsaId: _velicinaPsaId,
                            ));
                        Navigator.of(context).pop();
                      },
                      child: const Text('Primijeni'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
