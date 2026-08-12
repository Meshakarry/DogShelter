import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/core/api_exception.dart';
import 'package:dogshelter_shared/core/image_url.dart';
import 'package:dogshelter_shared/pas/data/pas_api.dart';
import 'package:dogshelter_shared/pas/domain/pas.dart';
import 'package:dogshelter_shared/pas/domain/slika_psa.dart';
import 'package:dogshelter_shared/pas/domain/spol.dart';
import 'package:dogshelter_shared/widgets/error_banner.dart';
import 'package:dogshelter_shared/widgets/form_error_scroller.dart';
import 'package:dogshelter_shared/widgets/labeled_field.dart';
import '../../../core/app_theme.dart';
import '../../../environment.dart';
import '../../../widgets/cover_image_picker.dart';
import '../../../widgets/dashed_dropzone.dart';
import '../../../widgets/date_input_field.dart';
import '../../../widgets/gradient_button.dart';
import '../application/psi_providers.dart';

/// Edit/create screen for a single Pas.
class PsiFormScreen extends ConsumerWidget {
  const PsiFormScreen({super.key, this.pasId});

  final int? pasId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final body = pasId == null
        ? const _PsiFormBody(pasId: null, initial: null)
        : ref.watch(psiDetailProvider(pasId!)).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: ErrorBanner(error: e)),
              data: (pas) => _PsiFormBody(pasId: pasId, initial: pas),
            );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 24, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Nazad',
                onPressed: () => context.go('/psi'),
              ),
              Text(
                pasId == null ? 'Dodaj psa' : 'Uredi psa',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}

class _PsiFormBody extends ConsumerStatefulWidget {
  const _PsiFormBody({required this.pasId, required this.initial});

  final int? pasId;
  final Pas? initial;

  @override
  ConsumerState<_PsiFormBody> createState() => _PsiFormBodyState();
}

class _PsiFormBodyState extends ConsumerState<_PsiFormBody> with FormErrorScroller<_PsiFormBody> {
  late final _nazivController = TextEditingController(text: widget.initial?.naziv ?? '');
  late final _opisController = TextEditingController(text: widget.initial?.opis ?? '');
  late final _tezinaController = TextEditingController(text: widget.initial?.tezina?.toString() ?? '');

  int? _rasaId;
  int? _statusPsaId;
  int? _velicinaPsaId;
  Spol _spol = Spol.muzjak;
  DateTime? _datumRodjenja;
  late DateTime _datumPrijema;
  late bool _vakcinisan;
  late bool _sterilizovan;
  late bool _aktivan;
  File? _newCoverImage;

  /// Extra gallery photos picked before the Pas exists yet (create mode only) - uploaded
  /// one by one right after insert succeeds and a real pasId is known.
  final List<File> _pendingGalleryImages = [];
  bool _isSaving = false;
  Object? _submitError;

  @override
  final errorScrollController = ScrollController();

  @override
  List<String> get fieldOrder =>
      const ['naziv', 'rasaId', 'statusPsaId', 'velicinaPsaId', 'datumPrijema', 'coverImage'];

  bool get _isEdit => widget.pasId != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _rasaId = initial?.rasaId;
    _statusPsaId = initial?.statusPsaId;
    _velicinaPsaId = initial?.velicinaPsaId;
    _spol = initial?.spol ?? Spol.muzjak;
    _datumRodjenja = initial?.datumRodjenja;
    _datumPrijema = initial?.datumPrijema ?? DateTime.now();
    _vakcinisan = initial?.vakcinisan ?? false;
    _sterilizovan = initial?.sterilizovan ?? false;
    _aktivan = initial?.aktivan ?? true;
  }

  @override
  void dispose() {
    _nazivController.dispose();
    _opisController.dispose();
    _tezinaController.dispose();
    errorScrollController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path == null) return;
    clearFieldError('coverImage');
    setState(() => _newCoverImage = File(path));
  }

  Future<void> _pickPendingGalleryImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path == null) return;
    setState(() => _pendingGalleryImages.add(File(path)));
  }

  Future<void> _pickDate({required bool isDatumRodjenja}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDatumRodjenja ? (_datumRodjenja ?? DateTime.now()) : _datumPrijema,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      if (isDatumRodjenja) {
        _datumRodjenja = picked;
      } else {
        _datumPrijema = picked;
        clearFieldError('datumPrijema');
      }
    });
  }

  Future<void> _submit() async {
    final errors = <String, String>{};
    final naziv = _nazivController.text.trim();
    if (naziv.isEmpty) errors['naziv'] = 'Naziv je obavezan.';
    if (_rasaId == null) errors['rasaId'] = 'Rasa je obavezna.';
    if (_statusPsaId == null) errors['statusPsaId'] = 'Status je obavezan.';
    if (_velicinaPsaId == null) errors['velicinaPsaId'] = 'Veličina je obavezna.';
    if (!_isEdit && _newCoverImage == null) errors['coverImage'] = 'Naslovna slika je obavezna.';

    if (errors.isNotEmpty) {
      applyValidationErrors(errors);
      return;
    }
    clearAllFieldErrors();

    final tezinaText = _tezinaController.text.trim();
    final data = PasFormData(
      naziv: naziv,
      rasaId: _rasaId!,
      spol: _spol,
      datumRodjenja: _datumRodjenja,
      opis: _opisController.text.trim(),
      statusPsaId: _statusPsaId!,
      velicinaPsaId: _velicinaPsaId!,
      tezina: tezinaText.isEmpty ? null : double.tryParse(tezinaText),
      datumPrijema: _datumPrijema,
      vakcinisan: _vakcinisan,
      sterilizovan: _sterilizovan,
      aktivan: _isEdit ? _aktivan : null,
    );

    setState(() {
      _isSaving = true;
      _submitError = null;
    });
    try {
      final api = ref.read(pasApiProvider);
      if (_isEdit) {
        await api.update(widget.pasId!, data, coverImage: _newCoverImage);
        ref.invalidate(psiDetailProvider(widget.pasId!));
        if (mounted) _showMessage('Pas je uspješno izmijenjen.');
      } else {
        final created = await api.insert(data, _newCoverImage!);
        for (var i = 0; i < _pendingGalleryImages.length; i++) {
          await api.addGalleryImage(created.pasId, _pendingGalleryImages[i], i);
        }
        if (mounted) {
          _showMessage('Pas je uspješno dodan.');
          context.go('/psi/${created.pasId}');
        }
      }
      ref.invalidate(psiListProvider);
    } catch (e) {
      setState(() => _submitError = e);
      scrollToTop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: errorScrollController,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SizedBox(
          width: 720,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_submitError != null) ErrorBanner(error: _submitError),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CoverImagePicker(
                    key: keyFor('coverImage'),
                    existingUrl: resolveImageUrl(widget.initial?.slikaNaslovna, Environment.apiBaseUrl),
                    newImage: _newCoverImage,
                    onPick: _pickCoverImage,
                    errorText: fieldErrors['coverImage'],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LabeledField(
                          key: keyFor('naziv'),
                          label: 'Naziv',
                          errorText: fieldErrors['naziv'],
                          child: TextField(
                            controller: _nazivController,
                            onChanged: (_) => clearFieldError('naziv'),
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(height: 12),
                        LabeledField(
                          label: 'Spol',
                          child: SegmentedButton<Spol>(
                            segments: [
                              ButtonSegment(value: Spol.muzjak, label: Text(Spol.muzjak.label)),
                              ButtonSegment(value: Spol.zenka, label: Text(Spol.zenka.label)),
                            ],
                            selected: {_spol},
                            onSelectionChanged: (selection) => setState(() => _spol = selection.first),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: LabeledField(
                      key: keyFor('rasaId'),
                      label: 'Rasa',
                      errorText: fieldErrors['rasaId'],
                      child: Consumer(
                        builder: (context, ref, _) {
                          final lookupsAsync = ref.watch(psiFormLookupsProvider);
                          return lookupsAsync.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (e, _) => Text('Greška: $e'),
                            data: (lookups) => DropdownButtonFormField<int>(
                              initialValue: _rasaId,
                              decoration: const InputDecoration(border: OutlineInputBorder()),
                              items: [
                                for (final rasa in lookups.rase)
                                  DropdownMenuItem(value: rasa.rasaId, child: Text(rasa.naziv)),
                              ],
                              onChanged: (value) => setState(() {
                                _rasaId = value;
                                clearFieldError('rasaId');
                              }),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabeledField(
                      key: keyFor('statusPsaId'),
                      label: 'Status',
                      errorText: fieldErrors['statusPsaId'],
                      child: Consumer(
                        builder: (context, ref, _) {
                          final lookupsAsync = ref.watch(psiFormLookupsProvider);
                          return lookupsAsync.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (e, _) => Text('Greška: $e'),
                            data: (lookups) => DropdownButtonFormField<int>(
                              initialValue: _statusPsaId,
                              decoration: const InputDecoration(border: OutlineInputBorder()),
                              items: [
                                for (final status in lookups.statusi)
                                  DropdownMenuItem(value: status.statusPsaId, child: Text(status.naziv)),
                              ],
                              onChanged: (value) => setState(() {
                                _statusPsaId = value;
                                clearFieldError('statusPsaId');
                              }),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: LabeledField(
                      key: keyFor('velicinaPsaId'),
                      label: 'Veličina',
                      errorText: fieldErrors['velicinaPsaId'],
                      child: Consumer(
                        builder: (context, ref, _) {
                          final lookupsAsync = ref.watch(psiFormLookupsProvider);
                          return lookupsAsync.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (e, _) => Text('Greška: $e'),
                            data: (lookups) => DropdownButtonFormField<int>(
                              initialValue: _velicinaPsaId,
                              decoration: const InputDecoration(border: OutlineInputBorder()),
                              items: [
                                for (final velicina in lookups.velicine)
                                  DropdownMenuItem(value: velicina.velicinaPsaId, child: Text(velicina.naziv)),
                              ],
                              onChanged: (value) => setState(() {
                                _velicinaPsaId = value;
                                clearFieldError('velicinaPsaId');
                              }),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabeledField(
                      label: 'Težina (kg)',
                      required: false,
                      child: TextField(
                        controller: _tezinaController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: LabeledField(
                      label: 'Datum rođenja',
                      required: false,
                      child: DateInputField(
                        value: _datumRodjenja,
                        hintText: 'Odaberite datum',
                        onTap: () => _pickDate(isDatumRodjenja: true),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabeledField(
                      key: keyFor('datumPrijema'),
                      label: 'Datum prijema',
                      errorText: fieldErrors['datumPrijema'],
                      child: DateInputField(
                        value: _datumPrijema,
                        hintText: 'Odaberite datum',
                        onTap: () => _pickDate(isDatumRodjenja: false),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LabeledField(
                label: 'Opis',
                required: false,
                child: TextField(
                  controller: _opisController,
                  maxLines: 4,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 24,
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Vakcinisan'),
                    value: _vakcinisan,
                    onChanged: (value) => setState(() => _vakcinisan = value ?? false),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Sterilizovan'),
                    value: _sterilizovan,
                    onChanged: (value) => setState(() => _sterilizovan = value ?? false),
                  ),
                  if (_isEdit)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('Aktivan'),
                      value: _aktivan,
                      onChanged: (value) => setState(() => _aktivan = value ?? true),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              Text('Galerija slika', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              if (_isEdit)
                _GallerySection(pasId: widget.pasId!)
              else
                _PendingGallerySection(
                  images: _pendingGalleryImages,
                  onAdd: _pickPendingGalleryImage,
                  onRemove: (image) => setState(() => _pendingGalleryImages.remove(image)),
                ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: GradientButton(
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Sačuvaj'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GallerySection extends ConsumerWidget {
  const _GallerySection({required this.pasId});

  final int pasId;

  Future<void> _addImage(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path == null) return;
    try {
      await ref.read(psiGalleryProvider(pasId).notifier).add(File(path));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeApiError(e))));
      }
    }
  }

  Future<void> _removeImage(BuildContext context, WidgetRef ref, SlikaPsa slika) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content: const Text('Da li želite obrisati ovu sliku iz galerije?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Obriši')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(psiGalleryProvider(pasId).notifier).remove(slika.slikaPsaId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final galleryAsync = ref.watch(psiGalleryProvider(pasId));

    return galleryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorBanner(error: e),
      data: (images) => Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final slika in images)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  child: Image.network(
                    resolveImageUrl(slika.putanja, Environment.apiBaseUrl)!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 16, color: Colors.white),
                      onPressed: () => _removeImage(context, ref, slika),
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding: EdgeInsets.zero,
                      tooltip: 'Obriši',
                    ),
                  ),
                ),
              ],
            ),
          DashedDropzone(
            width: 160,
            height: 120,
            onTap: () => _addImage(context, ref),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(height: 4),
                Text(
                  '+ Dodaj fotografiju',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Same visual shape as [_GallerySection], but for a brand-new Pas that has no pasId yet -
/// operates on a local file list only; the actual upload happens after insert succeeds.
class _PendingGallerySection extends StatelessWidget {
  const _PendingGallerySection({required this.images, required this.onAdd, required this.onRemove});

  final List<File> images;
  final VoidCallback onAdd;
  final ValueChanged<File> onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final image in images)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                child: Image.file(image, width: 120, height: 120, fit: BoxFit.cover),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.white),
                    onPressed: () => onRemove(image),
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    padding: EdgeInsets.zero,
                    tooltip: 'Ukloni',
                  ),
                ),
              ),
            ],
          ),
        DashedDropzone(
          width: 160,
          height: 120,
          onTap: onAdd,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 4),
              Text(
                '+ Dodaj fotografiju',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
