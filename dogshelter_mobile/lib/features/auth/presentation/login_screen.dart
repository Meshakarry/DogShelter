import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/app_title.dart';
import '../../../widgets/error_banner.dart';
import '../application/auth_notifier.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _korisnickoImeController = TextEditingController();
  final _lozinkaController = TextEditingController();
  bool _isSubmitting = false;
  Object? _error;

  @override
  void dispose() {
    _korisnickoImeController.dispose();
    _lozinkaController.dispose();
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
      await ref.read(authNotifierProvider.notifier).login(
            korisnickoIme: _korisnickoImeController.text.trim(),
            lozinka: _lozinkaController.text,
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: AppTitle(style: Theme.of(context).textTheme.headlineMedium)),
                  const SizedBox(height: 32),
                  ErrorBanner(error: _error),
                  TextFormField(
                    controller: _korisnickoImeController,
                    decoration: const InputDecoration(labelText: 'Korisničko ime'),
                    onChanged: (_) => _clearError(),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? 'Korisničko ime je obavezno.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lozinkaController,
                    decoration: const InputDecoration(labelText: 'Lozinka'),
                    obscureText: true,
                    onChanged: (_) => _clearError(),
                    validator: (value) => (value == null || value.isEmpty) ? 'Lozinka je obavezna.' : null,
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
                        : const Text('Prijava'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isSubmitting ? null : () => context.push('/register'),
                    child: const Text('Nemate račun? Registrujte se'),
                  ),
                  TextButton(
                    onPressed: _isSubmitting ? null : () => context.push('/forgot-password'),
                    child: const Text('Zaboravili ste lozinku?'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
