import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/error_banner.dart';
import '../../../widgets/form_error_scroller.dart';
import '../../../widgets/labeled_field.dart';
import '../application/auth_notifier.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen>
    with FormErrorScroller<ResetPasswordScreen> {
  final _kodController = TextEditingController();
  final _lozinkaController = TextEditingController();
  final _lozinkaPotvrdaController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSubmitting = false;
  Object? _apiError;

  @override
  List<String> get fieldOrder => const ['kod', 'lozinka', 'lozinkaPotvrda'];

  @override
  ScrollController get errorScrollController => _scrollController;

  @override
  void dispose() {
    _kodController.dispose();
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

    final kod = _kodController.text.trim();
    if (kod.isEmpty) {
      errors['kod'] = 'Kod je obavezan.';
    } else if (!RegExp(r'^\d{6}$').hasMatch(kod)) {
      errors['kod'] = 'Kod mora imati tačno 6 cifara.';
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
      await ref.read(authApiProvider).resetPassword(
            email: widget.email,
            kod: kod,
            novaLozinka: lozinka,
            novaLozinkaPotvrda: _lozinkaPotvrdaController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lozinka je uspješno promijenjena. Prijavite se novom lozinkom.')),
      );
      context.go('/login');
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
      appBar: AppBar(title: const Text('Novi kod i lozinka')),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Kod je poslan na ${widget.email}. Unesite ga zajedno s novom lozinkom.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ErrorBanner(error: _apiError),
              LabeledField(
                key: keyFor('kod'),
                label: 'Kod',
                child: TextField(
                  controller: _kodController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  onChanged: (_) {
                    _clearApiError();
                    clearFieldError('kod');
                  },
                  decoration: InputDecoration(
                    hintText: '123456',
                    border: const OutlineInputBorder(),
                    errorText: fieldErrors['kod'],
                  ),
                ),
              ),
              LabeledField(
                key: keyFor('lozinka'),
                label: 'Nova lozinka',
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
                label: 'Potvrda nove lozinke',
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
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Promijeni lozinku'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
