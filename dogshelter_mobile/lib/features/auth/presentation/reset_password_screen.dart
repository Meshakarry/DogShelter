import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/error_banner.dart';
import '../application/auth_notifier.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kodController = TextEditingController();
  final _lozinkaController = TextEditingController();
  final _lozinkaPotvrdaController = TextEditingController();
  bool _isSubmitting = false;
  Object? _error;

  @override
  void dispose() {
    _kodController.dispose();
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
      await ref.read(authApiProvider).resetPassword(
            email: widget.email,
            kod: _kodController.text.trim(),
            novaLozinka: _lozinkaController.text,
            novaLozinkaPotvrda: _lozinkaPotvrdaController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lozinka je uspješno promijenjena. Prijavite se novom lozinkom.')),
      );
      context.go('/login');
    } catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novi kod i lozinka')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Kod je poslan na ${widget.email}. Unesite ga zajedno s novom lozinkom.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ErrorBanner(error: _error),
                TextFormField(
                  controller: _kodController,
                  decoration: const InputDecoration(labelText: 'Kod (6 cifara)'),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  onChanged: (_) => _clearError(),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Kod je obavezan.';
                    if (!RegExp(r'^\d{6}$').hasMatch(v.trim())) {
                      return 'Kod mora imati tačno 6 cifara.';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _lozinkaController,
                  decoration: const InputDecoration(labelText: 'Nova lozinka'),
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
                  decoration: const InputDecoration(labelText: 'Potvrda nove lozinke'),
                  obscureText: true,
                  onChanged: (_) => _clearError(),
                  validator: (v) => v != _lozinkaController.text ? 'Lozinke se ne podudaraju.' : null,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Promijeni lozinku'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
