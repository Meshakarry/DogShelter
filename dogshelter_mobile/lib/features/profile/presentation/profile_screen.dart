import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/image_url.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/form_error_scroller.dart';
import '../../../widgets/labeled_field.dart';
import '../../auth/application/auth_notifier.dart';
import '../../auth/domain/korisnik.dart';
import '../application/profile_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with FormErrorScroller<ProfileScreen> {
  late final TextEditingController _imeController;
  late final TextEditingController _prezimeController;
  late final TextEditingController _emailController;
  late final TextEditingController _telefonController;
  late final TextEditingController _korisnickoImeController;
  final _staraLozinkaController = TextEditingController();
  final _novaLozinkaController = TextEditingController();
  final _novaLozinkaPotvrdaController = TextEditingController();
  final _scrollController = ScrollController();

  bool _isEditing = false;
  bool _showPasswordFields = false;
  bool _isSubmitting = false;
  Object? _apiError;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static const _passwordFields = [
    'staraLozinka',
    'novaLozinka',
    'novaLozinkaPotvrda',
  ];

  @override
  List<String> get fieldOrder => const [
    'ime',
    'prezime',
    'email',
    'telefon',
    'korisnickoIme',
    ..._passwordFields,
  ];

  @override
  ScrollController get errorScrollController => _scrollController;

  Korisnik get _korisnik => ref.read(authNotifierProvider).korisnik!;

  @override
  void initState() {
    super.initState();
    final korisnik = _korisnik;
    _imeController = TextEditingController(text: korisnik.ime);
    _prezimeController = TextEditingController(text: korisnik.prezime);
    _emailController = TextEditingController(text: korisnik.email);
    _telefonController = TextEditingController(text: korisnik.telefon ?? '');
    _korisnickoImeController = TextEditingController(
      text: korisnik.korisnickoIme,
    );
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
    _scrollController.dispose();
    super.dispose();
  }

  /// A stale server-side error (from a previous failed Save) shouldn't linger once the user
  /// starts correcting something - it gets a fresh chance to reappear next time they hit Sačuvaj.
  void _clearApiError() {
    if (_apiError != null) setState(() => _apiError = null);
  }

  Future<void> _pickAvatar() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
    );
    if (file == null) return;

    setState(() {
      _isSubmitting = true;
      _apiError = null;
    });
    try {
      final updated = await ref.read(profileApiProvider).updateAvatar(file);
      await ref.read(authNotifierProvider.notifier).updateKorisnik(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slika profila je ažurirana.')),
        );
      }
    } catch (e) {
      setState(() => _apiError = e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _save() async {
    final errors = <String, String>{};

    final ime = _imeController.text.trim();
    if (ime.isEmpty) {
      errors['ime'] = 'Ime je obavezno.';
    } else if (ime.length < 2) {
      errors['ime'] = 'Ime mora imati najmanje 2 znaka.';
    }

    final prezime = _prezimeController.text.trim();
    if (prezime.isEmpty) {
      errors['prezime'] = 'Prezime je obavezno.';
    } else if (prezime.length < 2) {
      errors['prezime'] = 'Prezime mora imati najmanje 2 znaka.';
    }

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      errors['email'] = 'Email je obavezan.';
    } else if (!_emailRegex.hasMatch(email)) {
      errors['email'] = 'Unesite ispravan email, npr. ime@primjer.com';
    }

    final korisnickoIme = _korisnickoImeController.text.trim();
    if (korisnickoIme.isEmpty) {
      errors['korisnickoIme'] = 'Korisničko ime je obavezno.';
    } else if (korisnickoIme.length < 3) {
      errors['korisnickoIme'] = 'Korisničko ime mora imati najmanje 3 znaka.';
    }

    if (_showPasswordFields) {
      final novaLozinka = _novaLozinkaController.text;
      if (_staraLozinkaController.text.isEmpty) {
        errors['staraLozinka'] = 'Trenutna lozinka je obavezna.';
      }
      if (novaLozinka.isEmpty) {
        errors['novaLozinka'] = 'Nova lozinka je obavezna.';
      } else if (novaLozinka.length < 6) {
        errors['novaLozinka'] = 'Lozinka mora imati najmanje 6 znakova.';
      }
      if (_novaLozinkaPotvrdaController.text != novaLozinka) {
        errors['novaLozinkaPotvrda'] = 'Lozinke se ne podudaraju.';
      }
    }

    if (errors.isNotEmpty) {
      applyValidationErrors(errors);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _apiError = null;
      clearAllFieldErrors();
    });

    try {
      final updated = await ref
          .read(profileApiProvider)
          .updateProfile(
            ime: ime,
            prezime: prezime,
            email: email,
            telefon: _telefonController.text.trim().isEmpty
                ? null
                : _telefonController.text.trim(),
            korisnickoIme: korisnickoIme,
          );
      await ref.read(authNotifierProvider.notifier).updateKorisnik(updated);

      if (_showPasswordFields) {
        await ref
            .read(profileApiProvider)
            .changePassword(
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil je uspješno ažuriran.')),
      );
    } catch (e) {
      setState(() => _apiError = e);
      scrollToTop();
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
      _apiError = null;
      fieldErrors.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authNotifierProvider); // rebuild on avatar/profile updates
    final korisnik = _korisnik;
    final avatarUrl = resolveImageUrl(korisnik.slikaPutanja);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
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
                    backgroundImage: avatarUrl == null
                        ? null
                        : CachedNetworkImageProvider(avatarUrl),
                    child: avatarUrl == null
                        ? const Icon(Icons.person, size: 48)
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF008554),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ErrorBanner(error: _apiError),
          LabeledField(
            key: keyFor('ime'),
            label: 'Ime',
            child: TextField(
              controller: _imeController,
              enabled: _isEditing,
              onChanged: (_) {
                _clearApiError();
                clearFieldError('ime');
              },
              decoration: InputDecoration(
                hintText: 'npr. Amina',
                border: const OutlineInputBorder(),
                errorText: fieldErrors['ime'],
              ),
            ),
          ),
          const SizedBox(height: 16),
          LabeledField(
            key: keyFor('prezime'),
            label: 'Prezime',
            child: TextField(
              controller: _prezimeController,
              enabled: _isEditing,
              onChanged: (_) {
                _clearApiError();
                clearFieldError('prezime');
              },
              decoration: InputDecoration(
                hintText: 'npr. Hodžić',
                border: const OutlineInputBorder(),
                errorText: fieldErrors['prezime'],
              ),
            ),
          ),
          const SizedBox(height: 16),
          LabeledField(
            key: keyFor('email'),
            label: 'Email',
            child: TextField(
              controller: _emailController,
              enabled: _isEditing,
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) {
                _clearApiError();
                clearFieldError('email');
              },
              decoration: InputDecoration(
                hintText: 'ime@primjer.com',
                border: const OutlineInputBorder(),
                errorText: fieldErrors['email'],
              ),
            ),
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Telefon (opcionalno)',
            required: false,
            child: TextField(
              controller: _telefonController,
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
              onChanged: (_) => _clearApiError(),
              decoration: const InputDecoration(
                hintText: 'npr. 061 234 567',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          LabeledField(
            key: keyFor('korisnickoIme'),
            label: 'Korisničko ime',
            child: TextField(
              controller: _korisnickoImeController,
              enabled: _isEditing,
              onChanged: (_) {
                _clearApiError();
                clearFieldError('korisnickoIme');
              },
              decoration: InputDecoration(
                hintText: 'npr. amina123',
                border: const OutlineInputBorder(),
                errorText: fieldErrors['korisnickoIme'],
              ),
            ),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _showPasswordFields,
              title: const Text('Promijeni lozinku'),
              onChanged: (value) {
                setState(() => _showPasswordFields = value ?? false);
                if (!_showPasswordFields) clearFieldErrors(_passwordFields);
              },
            ),
            if (_showPasswordFields) ...[
              LabeledField(
                key: keyFor('staraLozinka'),
                label: 'Trenutna lozinka',
                child: TextField(
                  controller: _staraLozinkaController,
                  obscureText: true,
                  onChanged: (_) {
                    _clearApiError();
                    clearFieldError('staraLozinka');
                  },
                  decoration: InputDecoration(
                    hintText: 'Unesite trenutnu lozinku',
                    border: const OutlineInputBorder(),
                    errorText: fieldErrors['staraLozinka'],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                key: keyFor('novaLozinka'),
                label: 'Nova lozinka',
                child: TextField(
                  controller: _novaLozinkaController,
                  obscureText: true,
                  onChanged: (_) {
                    _clearApiError();
                    clearFieldError('novaLozinka');
                  },
                  decoration: InputDecoration(
                    hintText: 'Najmanje 6 znakova',
                    border: const OutlineInputBorder(),
                    errorText: fieldErrors['novaLozinka'],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                key: keyFor('novaLozinkaPotvrda'),
                label: 'Potvrda nove lozinke',
                child: TextField(
                  controller: _novaLozinkaPotvrdaController,
                  obscureText: true,
                  onChanged: (_) {
                    _clearApiError();
                    clearFieldError('novaLozinkaPotvrda');
                  },
                  decoration: InputDecoration(
                    hintText: 'Ponovite novu lozinku',
                    border: const OutlineInputBorder(),
                    errorText: fieldErrors['novaLozinkaPotvrda'],
                  ),
                ),
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
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sačuvaj'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
