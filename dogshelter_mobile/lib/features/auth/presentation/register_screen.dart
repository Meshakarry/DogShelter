import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/error_banner.dart';
import '../application/auth_notifier.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imeController = TextEditingController();
  final _prezimeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonController = TextEditingController();
  final _korisnickoImeController = TextEditingController();
  final _lozinkaController = TextEditingController();
  final _lozinkaPotvrdaController = TextEditingController();
  bool _isSubmitting = false;
  Object? _error;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _imeController.dispose();
    _prezimeController.dispose();
    _emailController.dispose();
    _telefonController.dispose();
    _korisnickoImeController.dispose();
    _lozinkaController.dispose();
    _lozinkaPotvrdaController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await ref.read(authNotifierProvider.notifier).registerThenLogin(
            ime: _imeController.text.trim(),
            prezime: _prezimeController.text.trim(),
            email: _emailController.text.trim(),
            telefon: _telefonController.text.trim().isEmpty ? null : _telefonController.text.trim(),
            korisnickoIme: _korisnickoImeController.text.trim(),
            lozinka: _lozinkaController.text,
            lozinkaPotvrda: _lozinkaPotvrdaController.text,
          );
    } catch (e) {
      setState(() => _error = e);
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
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ErrorBanner(error: _error),
                TextFormField(
                  controller: _imeController,
                  decoration: const InputDecoration(labelText: 'Ime'),
                  onChanged: (_) => _clearError(),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ime je obavezno.';
                    if (v.trim().length < 2) return 'Ime mora imati najmanje 2 znaka.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _prezimeController,
                  decoration: const InputDecoration(labelText: 'Prezime'),
                  onChanged: (_) => _clearError(),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Prezime je obavezno.';
                    if (v.trim().length < 2) return 'Prezime mora imati najmanje 2 znaka.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => _clearError(),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email je obavezan.';
                    if (!_emailRegex.hasMatch(v.trim())) {
                      return 'Unesite ispravan email, npr. ime@primjer.com';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefonController,
                  decoration: const InputDecoration(labelText: 'Telefon (opcionalno)'),
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => _clearError(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _korisnickoImeController,
                  decoration: const InputDecoration(labelText: 'Korisničko ime'),
                  onChanged: (_) => _clearError(),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Korisničko ime je obavezno.';
                    if (v.trim().length < 3) return 'Korisničko ime mora imati najmanje 3 znaka.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lozinkaController,
                  decoration: const InputDecoration(labelText: 'Lozinka'),
                  obscureText: true,
                  onChanged: (_) => _clearError(),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Lozinka je obavezna.';
                    if (v.length < 6) return 'Lozinka mora imati najmanje 6 znakova.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lozinkaPotvrdaController,
                  decoration: const InputDecoration(labelText: 'Potvrda lozinke'),
                  obscureText: true,
                  onChanged: (_) => _clearError(),
                  validator: (v) =>
                      v != _lozinkaController.text ? 'Lozinke se ne podudaraju.' : null,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Registruj se'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
