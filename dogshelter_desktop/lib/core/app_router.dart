import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import 'package:dogshelter_shared/auth/domain/auth_state.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/korisnici/presentation/korisnici_screen.dart';
import '../features/pocetna/presentation/pocetna_screen.dart';
import '../features/postavke/domain/lookup_item.dart';
import '../features/postavke/presentation/grad_crud_screen.dart';
import '../features/postavke/presentation/kategorija_donacije_crud_screen.dart';
import '../features/postavke/presentation/lookup_detail_page.dart';
import '../features/postavke/presentation/postavke_screen.dart';
import '../features/postavke/presentation/potreba_azila_crud_screen.dart';
import '../features/postavke/presentation/rasa_crud_screen.dart';
import '../features/postavke/presentation/simple_lookup_crud_screen.dart';
import '../features/psi/presentation/psi_form_screen.dart';
import '../features/psi/presentation/psi_list_screen.dart';
import '../features/root/app_shell.dart';
import '../features/root/placeholder_screen.dart';

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
      final isLogin = state.matchedLocation == '/login';

      if (authState.status == AuthStatus.unknown) {
        return isSplash ? null : '/splash';
      }
      if (!authState.isLoggedIn) {
        return isLogin ? null : '/login';
      }
      if (isSplash || isLogin) return '/pocetna';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/pocetna', builder: (context, state) => const PocetnaScreen()),
          GoRoute(path: '/psi', builder: (context, state) => const PsiListScreen()),
          GoRoute(path: '/psi/novi', builder: (context, state) => const PsiFormScreen()),
          GoRoute(
            path: '/psi/:id',
            builder: (context, state) => PsiFormScreen(pasId: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(
            path: '/zahtjevi',
            builder: (context, state) => const PlaceholderScreen(title: 'Zahtjevi za udomljavanje'),
          ),
          GoRoute(
            path: '/udomljavanja',
            builder: (context, state) => const PlaceholderScreen(title: 'Udomljavanja'),
          ),
          GoRoute(path: '/posjete', builder: (context, state) => const PlaceholderScreen(title: 'Posjete')),
          GoRoute(path: '/donacije', builder: (context, state) => const PlaceholderScreen(title: 'Donacije')),
          GoRoute(path: '/volonteri', builder: (context, state) => const PlaceholderScreen(title: 'Volonteri')),
          GoRoute(path: '/obavijesti', builder: (context, state) => const PlaceholderScreen(title: 'Obavijesti')),
          GoRoute(path: '/dogadjaji', builder: (context, state) => const PlaceholderScreen(title: 'Događaji')),
          GoRoute(path: '/izvjestaji', builder: (context, state) => const PlaceholderScreen(title: 'Izvještaji')),
          GoRoute(path: '/korisnici', builder: (context, state) => const KorisniciScreen()),
          GoRoute(path: '/postavke', builder: (context, state) => const PostavkeScreen()),
          GoRoute(
            path: '/postavke/gradovi',
            builder: (context, state) => const LookupDetailPage(title: 'Gradovi', child: GradCrudScreen()),
          ),
          GoRoute(
            path: '/postavke/rase',
            builder: (context, state) => const LookupDetailPage(title: 'Rase pasa', child: RasaCrudScreen()),
          ),
          GoRoute(
            path: '/postavke/status-psa',
            builder: (context, state) => const LookupDetailPage(
              title: 'Status psa',
              child: SimpleLookupCrudScreen(
                config: LookupTableConfig(path: '/api/StatusPsa', idKey: 'statusPsaId', label: 'status psa'),
              ),
            ),
          ),
          GoRoute(
            path: '/postavke/velicina-psa',
            builder: (context, state) => const LookupDetailPage(
              title: 'Veličina psa',
              child: SimpleLookupCrudScreen(
                config: LookupTableConfig(path: '/api/VelicinaPsa', idKey: 'velicinaPsaId', label: 'veličina psa'),
              ),
            ),
          ),
          GoRoute(
            path: '/postavke/tip-donacije',
            builder: (context, state) => const LookupDetailPage(
              title: 'Tip donacije',
              child: SimpleLookupCrudScreen(
                config: LookupTableConfig(path: '/api/TipDonacije', idKey: 'tipDonacijeId', label: 'tip donacije'),
              ),
            ),
          ),
          GoRoute(
            path: '/postavke/kategorija-donacije',
            builder: (context, state) => const LookupDetailPage(
              title: 'Kategorije materijalnih donacija',
              child: KategorijaDonacijeCrudScreen(),
            ),
          ),
          GoRoute(
            path: '/postavke/jedinica-mjere',
            builder: (context, state) => const LookupDetailPage(
              title: 'Jedinice mjere',
              child: SimpleLookupCrudScreen(
                config: LookupTableConfig(path: '/api/JedinicaMjere', idKey: 'jedinicaMjereId', label: 'jedinica mjere'),
              ),
            ),
          ),
          GoRoute(
            path: '/postavke/tip-aktivnosti',
            builder: (context, state) => const LookupDetailPage(
              title: 'Tip aktivnosti volontera',
              child: SimpleLookupCrudScreen(
                config: LookupTableConfig(path: '/api/TipAktivnosti', idKey: 'tipAktivnostiId', label: 'tip aktivnosti'),
              ),
            ),
          ),
          GoRoute(
            path: '/postavke/prioritet-potrebe',
            builder: (context, state) => const LookupDetailPage(
              title: 'Prioritet potrebe',
              child: SimpleLookupCrudScreen(
                config:
                    LookupTableConfig(path: '/api/PrioritetPotrebe', idKey: 'prioritetPotrebeId', label: 'prioritet potrebe'),
              ),
            ),
          ),
          GoRoute(
            path: '/postavke/potreba-azila',
            builder: (context, state) =>
                const LookupDetailPage(title: 'Potrebe azila', child: PotrebaAzilaCrudScreen()),
          ),
          GoRoute(
            path: '/postavke/status-zahtjeva',
            builder: (context, state) => const LookupDetailPage(
              title: 'Status zahtjeva za udomljavanje',
              child: SimpleLookupCrudScreen(
                config: LookupTableConfig(path: '/api/StatusZahtjeva', idKey: 'statusZahtjevaId', label: 'status zahtjeva'),
              ),
            ),
          ),
          GoRoute(
            path: '/postavke/status-posjete',
            builder: (context, state) => const LookupDetailPage(
              title: 'Status posjete',
              child: SimpleLookupCrudScreen(
                config: LookupTableConfig(path: '/api/StatusPosjete', idKey: 'statusPosjeteId', label: 'status posjete'),
              ),
            ),
          ),
          GoRoute(
            path: '/postavke/status-donacije',
            builder: (context, state) => const LookupDetailPage(
              title: 'Status donacije',
              child: SimpleLookupCrudScreen(
                config: LookupTableConfig(path: '/api/StatusDonacije', idKey: 'statusDonacijeId', label: 'status donacije'),
              ),
            ),
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    refreshListenable.dispose();
    router.dispose();
  });

  return router;
});
