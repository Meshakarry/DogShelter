import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import 'package:dogshelter_shared/auth/domain/korisnik.dart';
import 'package:dogshelter_shared/core/paged_result.dart';
import '../../../core/paged_list_notifier.dart';
import '../data/korisnik_admin_api.dart';

final korisnikAdminApiProvider = Provider<KorisnikAdminApi>((ref) => KorisnikAdminApi(ref.watch(apiClientProvider)));

class KorisnikListNotifier extends PagedListNotifier<Korisnik> {
  KorisnikListNotifier(this._api);

  final KorisnikAdminApi _api;
  int? _ulogaId;
  bool? _aktivan;

  int? get ulogaId => _ulogaId;
  bool? get aktivan => _aktivan;

  @override
  Future<PagedResult<Korisnik>> fetch({String? query, required int page}) =>
      _api.search(korisnickoIme: query, ulogaId: _ulogaId, aktivan: _aktivan, page: page);

  Future<void> filterByUloga(int? ulogaId) async {
    _ulogaId = ulogaId;
    await resetAndReload();
  }

  Future<void> filterByAktivan(bool? aktivan) async {
    _aktivan = aktivan;
    await resetAndReload();
  }

  Future<void> create(KorisnikFormData data) async {
    await _api.insert(data);
    await refresh();
  }

  Future<void> update(int id, KorisnikFormData data) async {
    await _api.update(id, data);
    await refresh();
  }

  Future<void> remove(int id) async {
    await _api.delete(id);
    await refresh();
  }
}

// autoDispose so re-entering the Korisnici screen always refetches instead of showing a
// cached list from earlier in the session - a Korisnik's roles can change from a completely
// different screen (e.g. VolonterService.Update() adding/removing "Volonter" when an admin
// (de)activates a volunteer profile on the Volonteri screen), and without this the Korisnici
// list would keep showing the role set from whenever it was first loaded this session.
final korisnikListProvider =
    StateNotifierProvider.autoDispose<KorisnikListNotifier, AsyncValue<PagedResult<Korisnik>>>((ref) {
  return KorisnikListNotifier(ref.watch(korisnikAdminApiProvider));
});
