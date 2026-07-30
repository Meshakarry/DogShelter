import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import 'core/app_router.dart';
import 'core/app_theme.dart';
import 'environment.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    size: Size(1280, 832),
    minimumSize: Size(1024, 700),
    center: true,
    title: 'Azil Bugojno - Administracija',
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(
    ProviderScope(
      overrides: [apiBaseUrlProvider.overrideWithValue(Environment.apiBaseUrl)],
      child: const DogShelterDesktopApp(),
    ),
  );
}

class DogShelterDesktopApp extends ConsumerWidget {
  const DogShelterDesktopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Azil Bugojno - Administracija',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
