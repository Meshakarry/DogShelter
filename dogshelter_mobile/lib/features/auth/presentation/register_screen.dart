import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/error_banner.dart';
import '../../../widgets/form_error_scroller.dart';
import '../../../widgets/labeled_field.dart';
import '../application/auth_notifier.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with FormErrorScroller<RegisterScreen> {
  final _imeController = TextEditingController();
  final _prezimeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonController = TextEditingController();
  final _korisnickoImeController = TextEditingController();
  final _lozinkaController = TextEditingController();
  final _lozinkaPotvrdaController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSubmitting = false;
  Object? _apiError;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  List<String> get fieldOrder => const [
    'ime',
    'prezime',
    'email',
    'telefon',
    'korisnickoIme',
    'lozinka',
    'lozinkaPotvrda',
  ];

  @override
  ScrollController get errorScrollController => _scrollController;

  @override
  void dispose() {
    _imeController.dispose();
    _prezimeController.dispose();
    _emailController.dispose();
    _telefonController.dispose();
    _korisnickoImeController.dispose();
    _lozinkaController.dispose();
    _lozinkaPotvrdaController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _clearApiError() {
    if (_apiError != null) setState(() => _apiError = null);
  }

  Future<void> _submit() async {
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

    final lozinka = _lozinkaController.text;
    if (lozinka.isEmpty) {
      errors['lozinka'] = 'Lozinka je obavezna.';
    } else if (lozinka.length < 6) {
      errors['lozinka'] = 'Lozinka mora imati najmanje 6 znakova.';
    }

    if (_lozinkaPotvrdaController.text != lozinka) {
      errors['lozinkaPotvrda'] = 'Lozinke se ne podudaraju.';
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
      await ref
          .read(authNotifierProvider.notifier)
          .registerThenLogin(
            ime: ime,
            prezime: prezime,
            email: email,
            telefon: _telefonController.text.trim().isEmpty
                ? null
                : _telefonController.text.trim(),
            korisnickoIme: korisnickoIme,
            lozinka: lozinka,
            lozinkaPotvrda: _lozinkaPotvrdaController.text,
          );
    } catch (e) {
      setState(() => _apiError = e);
      scrollToTop();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registracija')),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ErrorBanner(error: _apiError),
              LabeledField(
                key: keyFor('ime'),
                label: 'Ime',
                child: TextField(
                  controller: _imeController,
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
              const SizedBox(height: 16),
              LabeledField(
                key: keyFor('lozinka'),
                label: 'Lozinka',
                child: TextField(
                  controller: _lozinkaController,
                  obscureText: true,
                  onChanged: (_) {
                    _clearApiError();
                    clearFieldError('lozinka');
                  },
                  decoration: InputDecoration(
                    hintText: 'Najmanje 6 znakova',
                    border: const OutlineInputBorder(),
                    errorText: fieldErrors['lozinka'],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                key: keyFor('lozinkaPotvrda'),
                label: 'Potvrda lozinke',
                child: TextField(
                  controller: _lozinkaPotvrdaController,
                  obscureText: true,
                  onChanged: (_) {
                    _clearApiError();
                    clearFieldError('lozinkaPotvrda');
                  },
                  decoration: InputDecoration(
                    hintText: 'Ponovite lozinku',
                    border: const OutlineInputBorder(),
                    errorText: fieldErrors['lozinkaPotvrda'],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Registruj se'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
