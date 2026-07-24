import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_notifier.dart';
import '../features/auth/domain/auth_state.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/reset_password_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/dogs/presentation/dog_detail_screen.dart';
import '../features/dogs/presentation/dog_list_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/root/presentation/app_shell.dart';
import '../features/root/presentation/placeholder_screen.dart';

class _AuthRouterRefresh extends ChangeNotifier {
  _AuthRouterRefresh(Ref ref) {
    ref.listen(authNotifierProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _AuthRouterRefresh(ref);
  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final isSplash = state.matchedLocation == '/splash';
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/reset-password';

      if (authState.status == AuthStatus.unknown) {
        return isSplash ? null : '/splash';
      }
      if (!authState.isLoggedIn) {
        return isAuthRoute ? null : '/login';
      }
      if (isSplash || isAuthRoute) return '/dogs';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => ResetPasswordScreen(email: state.extra as String),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/pocetna', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/dogs', builder: (context, state) => const DogListScreen()),
          GoRoute(path: '/zahtjevi', builder: (context, state) => const PlaceholderScreen(title: 'Moji zahtjevi')),
          GoRoute(path: '/posjete', builder: (context, state) => const PlaceholderScreen(title: 'Moje posjete')),
          GoRoute(path: '/donacije', builder: (context, state) => const PlaceholderScreen(title: 'Donacije')),
          GoRoute(path: '/obavijesti', builder: (context, state) => const PlaceholderScreen(title: 'Obavijesti')),
          GoRoute(
            path: '/notifikacije',
            builder: (context, state) => const PlaceholderScreen(title: 'Notifikacije'),
          ),
          GoRoute(path: '/dogadjaji', builder: (context, state) => const PlaceholderScreen(title: 'Događaji')),
          GoRoute(
            path: '/aktivnosti',
            builder: (context, state) => const PlaceholderScreen(title: 'Moje aktivnosti'),
          ),
          GoRoute(path: '/profil', builder: (context, state) => const ProfileScreen()),
        ],
      ),
      GoRoute(
        path: '/dogs/:id',
        builder: (context, state) => DogDetailScreen(pasId: int.parse(state.pathParameters['id']!)),
      ),
    ],
  );

  ref.onDispose(() {
    refreshListenable.dispose();
    router.dispose();
  });

  return router;
});
