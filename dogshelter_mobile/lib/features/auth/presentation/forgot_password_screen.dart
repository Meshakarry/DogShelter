import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/widgets/error_banner.dart';
import 'package:dogshelter_shared/widgets/form_error_scroller.dart';
import 'package:dogshelter_shared/widgets/labeled_field.dart';
import 'package:dogshelter_shared/auth/application/auth_notifier.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with FormErrorScroller<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSubmitting = false;
  Object? _apiError;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  List<String> get fieldOrder => const ['email'];

  @override
  ScrollController get errorScrollController => _scrollController;

  @override
  void dispose() {
    _emailController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _clearApiError() {
    if (_apiError != null) setState(() => _apiError = null);
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      applyValidationErrors({'email': 'Email je obavezan.'});
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      applyValidationErrors({'email': 'Unesite ispravan email, npr. ime@primjer.com'});
      return;
    }

    setState(() {
      _isSubmitting = true;
      _apiError = null;
      clearAllFieldErrors();
    });

    try {
      await ref.read(authApiProvider).requestPasswordReset(email: email);
      if (!mounted) return;
      context.push('/reset-password', extra: email);
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
      appBar: AppBar(title: const Text('Zaboravljena lozinka')),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Unesite email adresu povezanu s vašim računom. Poslat ćemo vam kod za resetiranje lozinke.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ErrorBanner(error: _apiError),
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
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Pošalji kod'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
