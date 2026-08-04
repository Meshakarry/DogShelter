import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import 'package:dogshelter_shared/auth/domain/auth_state.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/dogadjaji/presentation/dogadjaj_form_screen.dart';
import '../features/dogadjaji/presentation/dogadjaji_screen.dart';
import '../features/donacije/presentation/donacija_detail_screen.dart';
import '../features/donacije/presentation/donacije_screen.dart';
import '../features/izvjestaji/presentation/izvjestaji_screen.dart';
import '../features/korisnici/presentation/korisnici_screen.dart';
import '../features/notifikacije/presentation/notifikacije_screen.dart';
import '../features/obavijesti/presentation/obavijest_form_screen.dart';
import '../features/obavijesti/presentation/obavijesti_screen.dart';
import '../features/pocetna/presentation/pocetna_screen.dart';
import '../features/postavke/domain/lookup_item.dart';
import '../features/postavke/presentation/grad_crud_screen.dart';
import '../features/postavke/presentation/kategorija_donacije_crud_screen.dart';
import '../features/postavke/presentation/lookup_detail_page.dart';
import '../features/postavke/presentation/postavke_screen.dart';
import '../features/postavke/presentation/potreba_azila_crud_screen.dart';
import '../features/postavke/presentation/rasa_crud_screen.dart';
import '../features/postavke/presentation/simple_lookup_crud_screen.dart';
import '../features/posjete/presentation/posjeta_detail_screen.dart';
import '../features/posjete/presentation/posjete_screen.dart';
import '../features/psi/presentation/psi_form_screen.dart';
import '../features/psi/presentation/psi_list_screen.dart';
import '../features/root/app_shell.dart';
import '../features/udomljavanja/presentation/udomljavanja_screen.dart';
import '../features/udomljavanja/presentation/udomljavanje_detail_screen.dart';
import '../features/volonteri/presentation/volonter_detail_screen.dart';
import '../features/volonteri/presentation/volonteri_screen.dart';
import '../features/zahtjevi/presentation/zahtjev_detail_screen.dart';
import '../features/zahtjevi/presentation/zahtjevi_screen.dart';

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
          GoRoute(path: '/notifikacije', builder: (context, state) => const NotifikacijeScreen()),
          GoRoute(path: '/psi', builder: (context, state) => const PsiListScreen()),
          GoRoute(path: '/psi/novi', builder: (context, state) => const PsiFormScreen()),
          GoRoute(
            path: '/psi/:id',
            builder: (context, state) => PsiFormScreen(pasId: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(path: '/zahtjevi', builder: (context, state) => const ZahtjeviScreen()),
          GoRoute(
            path: '/zahtjevi/:id',
            builder: (context, state) => ZahtjevDetailScreen(id: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(path: '/udomljavanja', builder: (context, state) => const UdomljavanjaScreen()),
          GoRoute(
            path: '/udomljavanja/:id',
            builder: (context, state) => UdomljavanjeDetailScreen(id: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(path: '/posjete', builder: (context, state) => const PosjeteScreen()),
          GoRoute(
            path: '/posjete/:id',
            builder: (context, state) => PosjetaDetailScreen(id: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(path: '/donacije', builder: (context, state) => const DonacijeScreen()),
          GoRoute(
            path: '/donacije/:id',
            builder: (context, state) => DonacijaDetailScreen(id: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(path: '/volonteri', builder: (context, state) => const VolonteriScreen()),
          GoRoute(
            path: '/volonteri/:id',
            builder: (context, state) => VolonterDetailScreen(id: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(path: '/obavijesti', builder: (context, state) => const ObavijestiScreen()),
          GoRoute(path: '/obavijesti/novi', builder: (context, state) => const ObavijestFormScreen()),
          GoRoute(
            path: '/obavijesti/:id',
            builder: (context, state) => ObavijestFormScreen(obavijestId: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(path: '/dogadjaji', builder: (context, state) => const DogadjajiScreen()),
          GoRoute(path: '/dogadjaji/novi', builder: (context, state) => const DogadjajFormScreen()),
          GoRoute(
            path: '/dogadjaji/:id',
            builder: (context, state) => DogadjajFormScreen(dogadjajId: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(path: '/izvjestaji', builder: (context, state) => const IzvjestajiScreen()),
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
          GoRoute(
            path: '/postavke/uloge',
            builder: (context, state) => const LookupDetailPage(
              title: 'Uloge korisnika',
              child: SimpleLookupCrudScreen(
                config: LookupTableConfig(path: '/api/Uloga', idKey: 'ulogaId', label: 'uloga'),
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
