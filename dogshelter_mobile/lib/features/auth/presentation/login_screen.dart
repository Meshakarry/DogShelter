import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/app_title.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/form_error_scroller.dart';
import '../../../widgets/labeled_field.dart';
import '../application/auth_notifier.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with FormErrorScroller<LoginScreen> {
  final _korisnickoImeController = TextEditingController();
  final _lozinkaController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSubmitting = false;
  Object? _apiError;

  @override
  List<String> get fieldOrder => const ['korisnickoIme', 'lozinka'];

  @override
  ScrollController get errorScrollController => _scrollController;

  @override
  void dispose() {
    _korisnickoImeController.dispose();
    _lozinkaController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _clearApiError() {
    if (_apiError != null) setState(() => _apiError = null);
  }

  Future<void> _submit() async {
    final errors = <String, String>{};
    if (_korisnickoImeController.text.trim().isEmpty) {
      errors['korisnickoIme'] = 'Korisničko ime je obavezno.';
    }
    if (_lozinkaController.text.isEmpty) {
      errors['lozinka'] = 'Lozinka je obavezna.';
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
          .login(
            korisnickoIme: _korisnickoImeController.text.trim(),
            lozinka: _lozinkaController.text,
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
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: AppTitle(
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 32),
              ErrorBanner(error: _apiError),
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
                    hintText: 'Unesite lozinku',
                    border: const OutlineInputBorder(),
                    errorText: fieldErrors['lozinka'],
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
                    : const Text('Prijava'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => context.push('/register'),
                child: const Text('Nemate račun? Registrujte se'),
              ),
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => context.push('/forgot-password'),
                child: const Text('Zaboravili ste lozinku?'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
