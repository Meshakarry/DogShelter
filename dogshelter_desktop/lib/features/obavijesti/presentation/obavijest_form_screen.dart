import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/core/image_url.dart';
import 'package:dogshelter_shared/obavijest/data/obavijest_api.dart';
import 'package:dogshelter_shared/obavijest/domain/obavijest.dart';
import 'package:dogshelter_shared/widgets/error_banner.dart';
import 'package:dogshelter_shared/widgets/form_error_scroller.dart';
import 'package:dogshelter_shared/widgets/labeled_field.dart';
import '../../../core/app_theme.dart';
import '../../../environment.dart';
import '../../../widgets/dashed_dropzone.dart';
import '../application/obavijesti_providers.dart';

/// Edit/create screen for a single Obavijest - not a sidebar destination, so (like Psi's form)
/// it renders its own back-button + title header instead of a Scaffold/AppBar.
class ObavijestFormScreen extends ConsumerWidget {
  const ObavijestFormScreen({super.key, this.obavijestId});

  final int? obavijestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final body = obavijestId == null
        ? const _ObavijestFormBody(obavijestId: null, initial: null)
        : ref.watch(obavijestDetailProvider(obavijestId!)).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: ErrorBanner(error: e)),
              data: (obavijest) => _ObavijestFormBody(obavijestId: obavijestId, initial: obavijest),
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
                onPressed: () => context.go('/obavijesti'),
              ),
              Text(
                obavijestId == null ? 'Nova obavijest' : 'Uredi obavijest',
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

class _ObavijestFormBody extends ConsumerStatefulWidget {
  const _ObavijestFormBody({required this.obavijestId, required this.initial});

  final int? obavijestId;
  final Obavijest? initial;

  @override
  ConsumerState<_ObavijestFormBody> createState() => _ObavijestFormBodyState();
}

class _ObavijestFormBodyState extends ConsumerState<_ObavijestFormBody> with FormErrorScroller<_ObavijestFormBody> {
  late final _naslovController = TextEditingController(text: widget.initial?.naslov ?? '');
  late final _sadrzajController = TextEditingController(text: widget.initial?.sadrzaj ?? '');

  late bool _aktivna;
  File? _newSlika;
  bool _isSaving = false;
  Object? _submitError;

  @override
  final errorScrollController = ScrollController();

  @override
  List<String> get fieldOrder => const ['naslov', 'sadrzaj', 'slika'];

  bool get _isEdit => widget.obavijestId != null;

  @override
  void initState() {
    super.initState();
    _aktivna = widget.initial?.aktivna ?? true;
  }

  @override
  void dispose() {
    _naslovController.dispose();
    _sadrzajController.dispose();
    errorScrollController.dispose();
    super.dispose();
  }

  Future<void> _pickSlika() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path == null) return;
    clearFieldError('slika');
    setState(() => _newSlika = File(path));
  }

  Future<void> _submit() async {
    final errors = <String, String>{};
    final naslov = _naslovController.text.trim();
    final sadrzaj = _sadrzajController.text.trim();
    if (naslov.isEmpty) errors['naslov'] = 'Naslov je obavezan.';
    if (sadrzaj.isEmpty) errors['sadrzaj'] = 'Tekst obavijesti je obavezan.';
    if (!_isEdit && _newSlika == null) errors['slika'] = 'Slika je obavezna.';

    if (errors.isNotEmpty) {
      applyValidationErrors(errors);
      return;
    }
    clearAllFieldErrors();

    final data = ObavijestFormData(naslov: naslov, sadrzaj: sadrzaj, aktivna: _aktivna);

    setState(() {
      _isSaving = true;
      _submitError = null;
    });
    try {
      final notifier = ref.read(obavijestListProvider.notifier);
      if (_isEdit) {
        await notifier.update(widget.obavijestId!, data, slika: _newSlika);
        ref.invalidate(obavijestDetailProvider(widget.obavijestId!));
        if (mounted) _showMessage('Obavijest je uspješno izmijenjena.');
      } else {
        await notifier.create(data, _newSlika!);
        if (mounted) _showMessage('Obavijest je uspješno dodana.');
      }
      if (mounted) context.go('/obavijesti');
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
                  _CoverImagePicker(
                    key: keyFor('slika'),
                    existingUrl: resolveImageUrl(widget.initial?.slikaPutanja, Environment.apiBaseUrl),
                    newImage: _newSlika,
                    onPick: _pickSlika,
                    errorText: fieldErrors['slika'],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LabeledField(
                          key: keyFor('naslov'),
                          label: 'Naslov',
                          errorText: fieldErrors['naslov'],
                          child: TextField(
                            controller: _naslovController,
                            onChanged: (_) => clearFieldError('naslov'),
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: const Text('Objavljeno'),
                          value: _aktivna,
                          onChanged: (value) => setState(() => _aktivna = value ?? true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LabeledField(
                key: keyFor('sadrzaj'),
                label: 'Tekst obavijesti',
                errorText: fieldErrors['sadrzaj'],
                child: TextField(
                  controller: _sadrzajController,
                  onChanged: (_) => clearFieldError('sadrzaj'),
                  maxLines: 8,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: _GradientButton(
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

/// Rectangular (no rounding) filled button with a radial gradient, matching Psi's form's
/// primary "Sačuvaj" action per the design mockup.
class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.6, -0.6),
            radius: 1.3,
            colors: [Color(0xFF3D9270), AppTheme.seedColor],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                child: IconTheme.merge(data: const IconThemeData(color: Colors.white), child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CoverImagePicker extends StatelessWidget {
  const _CoverImagePicker({super.key, this.existingUrl, this.newImage, required this.onPick, this.errorText});

  final String? existingUrl;
  final File? newImage;
  final VoidCallback onPick;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasImage = newImage != null || existingUrl != null;
    return Column(
      children: [
        DashedDropzone(
          width: 240,
          height: 160,
          onTap: onPick,
          borderColor: errorText != null ? Theme.of(context).colorScheme.error : null,
          child: newImage != null
              ? Image.file(newImage!, fit: BoxFit.cover, width: 240, height: 160)
              : existingUrl != null
                  ? Image.network(existingUrl!, fit: BoxFit.cover, width: 240, height: 160)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 32, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(height: 8),
                        Text(
                          '+ Dodaj fotografiju',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
        ),
        if (hasImage) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.upload_outlined, size: 18),
            label: const Text('Zamijeni sliku'),
          ),
        ],
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
          ),
      ],
    );
  }
}
