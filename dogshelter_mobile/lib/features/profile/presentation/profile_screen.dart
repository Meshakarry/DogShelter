import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/image_url.dart';
import '../../../widgets/error_banner.dart';
import '../../auth/application/auth_notifier.dart';
import '../../auth/domain/korisnik.dart';
import '../application/profile_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _imeController;
  late final TextEditingController _prezimeController;
  late final TextEditingController _emailController;
  late final TextEditingController _telefonController;
  late final TextEditingController _korisnickoImeController;
  final _staraLozinkaController = TextEditingController();
  final _novaLozinkaController = TextEditingController();
  final _novaLozinkaPotvrdaController = TextEditingController();

  bool _isEditing = false;
  bool _showPasswordFields = false;
  bool _isSubmitting = false;
  Object? _error;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Korisnik get _korisnik => ref.read(authNotifierProvider).korisnik!;

  @override
  void initState() {
    super.initState();
    final korisnik = _korisnik;
    _imeController = TextEditingController(text: korisnik.ime);
    _prezimeController = TextEditingController(text: korisnik.prezime);
    _emailController = TextEditingController(text: korisnik.email);
    _telefonController = TextEditingController(text: korisnik.telefon ?? '');
    _korisnickoImeController = TextEditingController(text: korisnik.korisnickoIme);
  }

  @override
  void dispose() {
    _imeController.dispose();
    _prezimeController.dispose();
    _emailController.dispose();
    _telefonController.dispose();
    _korisnickoImeController.dispose();
    _staraLozinkaController.dispose();
    _novaLozinkaController.dispose();
    _novaLozinkaPotvrdaController.dispose();
    super.dispose();
  }

  /// A stale server-side error (from a previous failed Save) shouldn't linger once the user
  /// starts correcting something - it gets a fresh chance to reappear next time they hit Sačuvaj.
  void _clearServerError() {
    if (_error != null) setState(() => _error = null);
  }

  Future<void> _pickAvatar() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (file == null) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final updated = await ref.read(profileApiProvider).updateAvatar(file);
      await ref.read(authNotifierProvider.notifier).updateKorisnik(updated);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Slika profila je ažurirana.')));
      }
    } catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final updated = await ref.read(profileApiProvider).updateProfile(
            ime: _imeController.text.trim(),
            prezime: _prezimeController.text.trim(),
            email: _emailController.text.trim(),
            telefon: _telefonController.text.trim().isEmpty ? null : _telefonController.text.trim(),
            korisnickoIme: _korisnickoImeController.text.trim(),
          );
      await ref.read(authNotifierProvider.notifier).updateKorisnik(updated);

      if (_showPasswordFields) {
        await ref.read(profileApiProvider).changePassword(
              staraLozinka: _staraLozinkaController.text,
              novaLozinka: _novaLozinkaController.text,
              novaLozinkaPotvrda: _novaLozinkaPotvrdaController.text,
            );
      }

      if (!mounted) return;
      _staraLozinkaController.clear();
      _novaLozinkaController.clear();
      _novaLozinkaPotvrdaController.clear();
      setState(() {
        _isEditing = false;
        _showPasswordFields = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil je uspješno ažuriran.')));
    } catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _cancelEdit() {
    final korisnik = _korisnik;
    setState(() {
      _imeController.text = korisnik.ime;
      _prezimeController.text = korisnik.prezime;
      _emailController.text = korisnik.email;
      _telefonController.text = korisnik.telefon ?? '';
      _korisnickoImeController.text = korisnik.korisnickoIme;
      _staraLozinkaController.clear();
      _novaLozinkaController.clear();
      _novaLozinkaPotvrdaController.clear();
      _showPasswordFields = false;
      _isEditing = false;
      _error = null;
    });
    // Re-run validators against the just-restored (valid, saved) values so any stale error text/
    // red borders from a previous failed Save attempt are cleared. Form.reset() would seem like
    // the obvious call here, but it resets controller-backed TextFormFields to '' when no
    // initialValue is set - since we manage values via controllers, validate() is the safe way to
    // clear stale errors without wiping the text we just restored.
    _formKey.currentState?.validate();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authNotifierProvider); // rebuild on avatar/profile updates
    final korisnik = _korisnik;
    final avatarUrl = resolveImageUrl(korisnik.slikaPutanja);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: GestureDetector(
                onTap: _isSubmitting ? null : _pickAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: const Color(0xFFE0E0E0),
                      backgroundImage: avatarUrl == null ? null : CachedNetworkImageProvider(avatarUrl),
                      child: avatarUrl == null ? const Icon(Icons.person, size: 48) : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Color(0xFF008554), shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ErrorBanner(error: _error),
            TextFormField(
              controller: _imeController,
              enabled: _isEditing,
              decoration: const InputDecoration(labelText: 'Ime'),
              onChanged: (_) => _clearServerError(),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ime je obavezno.';
                if (v.trim().length < 2) return 'Ime mora imati najmanje 2 znaka.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _prezimeController,
              enabled: _isEditing,
              decoration: const InputDecoration(labelText: 'Prezime'),
              onChanged: (_) => _clearServerError(),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Prezime je obavezno.';
                if (v.trim().length < 2) return 'Prezime mora imati najmanje 2 znaka.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              enabled: _isEditing,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => _clearServerError(),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email je obavezan.';
                if (!_emailRegex.hasMatch(v.trim())) return 'Unesite ispravan email.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telefonController,
              enabled: _isEditing,
              decoration: const InputDecoration(labelText: 'Telefon (opcionalno)'),
              keyboardType: TextInputType.phone,
              onChanged: (_) => _clearServerError(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _korisnickoImeController,
              enabled: _isEditing,
              decoration: const InputDecoration(labelText: 'Korisničko ime'),
              onChanged: (_) => _clearServerError(),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Korisničko ime je obavezno.';
                if (v.trim().length < 3) return 'Korisničko ime mora imati najmanje 3 znaka.';
                return null;
              },
            ),
            if (_isEditing) ...[
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _showPasswordFields,
                title: const Text('Promijeni lozinku'),
                onChanged: (value) => setState(() => _showPasswordFields = value ?? false),
              ),
              if (_showPasswordFields) ...[
                TextFormField(
                  controller: _staraLozinkaController,
                  decoration: const InputDecoration(labelText: 'Trenutna lozinka'),
                  obscureText: true,
                  onChanged: (_) => _clearServerError(),
                  validator: (v) {
                    if (!_showPasswordFields) return null;
                    return (v == null || v.isEmpty) ? 'Trenutna lozinka je obavezna.' : null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _novaLozinkaController,
                  decoration: const InputDecoration(labelText: 'Nova lozinka'),
                  obscureText: true,
                  onChanged: (_) => _clearServerError(),
                  validator: (v) {
                    if (!_showPasswordFields) return null;
                    if (v == null || v.isEmpty) return 'Nova lozinka je obavezna.';
                    if (v.length < 6) return 'Lozinka mora imati najmanje 6 znakova.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _novaLozinkaPotvrdaController,
                  decoration: const InputDecoration(labelText: 'Potvrda nove lozinke'),
                  obscureText: true,
                  onChanged: (_) => _clearServerError(),
                  validator: (v) {
                    if (!_showPasswordFields) return null;
                    return v != _novaLozinkaController.text ? 'Lozinke se ne podudaraju.' : null;
                  },
                ),
              ],
            ],
            const SizedBox(height: 24),
            if (!_isEditing)
              FilledButton.icon(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit),
                label: const Text('Uredi profil'),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : _cancelEdit,
                      child: const Text('Otkaži'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _save,
                      child: _isSubmitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Sačuvaj'),
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
