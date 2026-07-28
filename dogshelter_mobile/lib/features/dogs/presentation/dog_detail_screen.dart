import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/image_url.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/status_pill.dart';
import '../../adoption_requests/application/adoption_requests_providers.dart';
import '../../visits/presentation/book_visit_sheet.dart';
import '../application/dogs_providers.dart';
import '../domain/pas.dart';
import 'dog_status_style.dart';

class DogDetailScreen extends ConsumerWidget {
  const DogDetailScreen({super.key, required this.pasId});

  final int pasId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dogAsync = ref.watch(dogDetailProvider(pasId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalji psa')),
      body: dogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: ErrorBanner(error: e)),
        data: (dog) => _DogDetailBody(dog: dog),
      ),
    );
  }
}

class _DogDetailBody extends StatefulWidget {
  const _DogDetailBody({required this.dog});

  final Pas dog;

  @override
  State<_DogDetailBody> createState() => _DogDetailBodyState();
}

class _DogDetailBodyState extends State<_DogDetailBody> {
  late final List<String> _images;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    final coverUrl = resolveImageUrl(widget.dog.slikaNaslovna);
    final galleryUrls =
        widget.dog.slike.map((s) => resolveImageUrl(s.putanja)).whereType<String>().toList();
    _images = [?coverUrl, ...galleryUrls.where((url) => url != coverUrl)];
    _selectedIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    final dog = widget.dog;
    final heroUrl = _images.isEmpty ? null : _images[_selectedIndex];

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: heroUrl == null
                      ? const ColoredBox(color: Color(0xFFE0E0E0), child: Icon(Icons.pets, size: 48))
                      : CachedNetworkImage(imageUrl: heroUrl, fit: BoxFit.cover),
                ),
              ),
            ),
            if (_images.length > 1)
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(16),
                  itemCount: _images.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final selected = index == _selectedIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIndex = index),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: selected
                              ? Border.all(color: const Color(0xFF008554), width: 3)
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: _images[index],
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dog.naziv,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (dog.statusNaziv != null)
                        Text(
                          dog.statusNaziv!,
                          style: TextStyle(fontWeight: FontWeight.bold, color: dogStatusColor(dog.statusNaziv)),
                        ),
                      if (dog.rasaNaziv != null) StatusPill(label: dog.rasaNaziv!),
                      StatusPill(label: dog.spol.label),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(label: 'Starost', value: dog.ageLabel ?? 'Nepoznato'),
                  _DetailRow(label: 'Veličina', value: dog.velicinaNaziv ?? 'Nepoznato'),
                  if (dog.tezina != null) _DetailRow(label: 'Težina', value: '${dog.tezina} kg'),
                  _DetailRow(label: 'Vakcinisan', value: dog.vakcinisan ? 'Da' : 'Ne'),
                  _DetailRow(label: 'Sterilizovan', value: dog.sterilizovan ? 'Da' : 'Ne'),
                  if (dog.opis != null && dog.opis!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Opis', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(dog.opis!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _AdoptRequestBar(dog: dog),
    );
  }
}

/// The adopt CTA plus, per the faculty's "disabled actions need an explanation" rule, a reason
/// line shown whenever the button is disabled - either the dog isn't available, or the caller
/// already has an active (Na čekanju) request for this dog (checked via hasPendingZahtjevProvider,
/// same real-message text the backend itself would reject a duplicate submit with).
class _AdoptRequestBar extends ConsumerWidget {
  const _AdoptRequestBar({required this.dog});

  final Pas dog;

  bool get _isAvailable => dog.statusNaziv?.toLowerCase() == 'dostupan';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPending = ref.watch(hasPendingZahtjevProvider(dog.pasId)).valueOrNull ?? false;
    final enabled = _isAvailable && !hasPending;

    String? reason;
    if (!_isAvailable) {
      reason = 'Zahtjev nije moguć jer pas trenutno nije dostupan (status: ${dog.statusNaziv ?? 'nepoznat'}).';
    } else if (hasPending) {
      reason = 'Već imate aktivan zahtjev za ovog psa.';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (reason != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                reason,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
              ),
            ),
          _AdoptRequestButton(
            enabled: enabled,
            onPressed: () async {
              final submitted = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                builder: (_) => _SubmitRequestSheet(pasId: dog.pasId),
              );
              if (submitted == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Zahtjev za udomljavanje je poslan.')),
                );
                context.go('/zahtjevi');
              }
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final booked = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(),
                builder: (_) => BookVisitSheet(pasId: dog.pasId, pasNaziv: dog.naziv),
              );
              if (booked == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Posjeta je zakazana.')),
                );
                context.go('/posjete');
              }
            },
            icon: const Icon(Icons.event),
            label: const Text('Zakaži posjetu'),
          ),
        ],
      ),
    );
  }
}

/// A gradient-filled button. Flutter's ElevatedButton/FilledButton only accept a single flat
/// backgroundColor - there's no built-in gradient button - so this hand-builds one: a Container
/// paints the gradient background, and a transparent Material+InkWell on top gives the normal
/// button tap-ripple feedback.
class _AdoptRequestButton extends StatelessWidget {
  const _AdoptRequestButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: enabled
            ? const LinearGradient(
                colors: [Color(0xFF34C77B), Color(0xFF00593A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: enabled ? null : const Color(0xFFE0E0E0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? onPressed : null,
          child: Center(
            child: Text(
              'Pošalji zahtjev za udomljavanje',
              style: TextStyle(
                color: enabled ? Colors.white : const Color(0xFF9CA3AF),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet asking for an optional note before submitting a real
/// POST /api/ZahtjevZaUdomljavanje - pops `true` on success so the caller can navigate/snackbar.
class _SubmitRequestSheet extends ConsumerStatefulWidget {
  const _SubmitRequestSheet({required this.pasId});

  final int pasId;

  @override
  ConsumerState<_SubmitRequestSheet> createState() => _SubmitRequestSheetState();
}

class _SubmitRequestSheetState extends ConsumerState<_SubmitRequestSheet> {
  final _napomenaController = TextEditingController();
  bool _isSubmitting = false;
  Object? _error;

  @override
  void dispose() {
    _napomenaController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await ref.read(zahtjevApiProvider).createZahtjev(
            pasId: widget.pasId,
            napomena: _napomenaController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Zahtjev za udomljavanje',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Možete dodati napomenu za osoblje azila (nije obavezno).',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ErrorBanner(error: _error),
            TextField(
              controller: _napomenaController,
              onChanged: (_) => _clearError(),
              maxLines: 4,
              maxLength: 1000,
              decoration: const InputDecoration(labelText: 'Napomena', alignLabelWithHint: true),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                    child: const Text('Otkaži'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Pošalji'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
