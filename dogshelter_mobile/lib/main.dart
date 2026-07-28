import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'core/app_router.dart';
import 'core/app_theme.dart';
import 'environment.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Environment.stripePublishableKey.isNotEmpty) {
    Stripe.publishableKey = Environment.stripePublishableKey;
    await Stripe.instance.applySettings();
  }

  runApp(const ProviderScope(child: DogShelterApp()));
}

class DogShelterApp extends ConsumerWidget {
  const DogShelterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'DogShelter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
