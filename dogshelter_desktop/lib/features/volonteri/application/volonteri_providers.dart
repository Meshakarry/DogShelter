import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/aktivnost_volontera/data/aktivnost_volontera_api.dart';
import 'package:dogshelter_shared/aktivnost_volontera/domain/aktivnost_volontera.dart';
import 'package:dogshelter_shared/aktivnost_volontera/domain/tip_aktivnosti.dart';
import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import 'package:dogshelter_shared/auth/domain/korisnik.dart';
import 'package:dogshelter_shared/core/paged_result.dart';
import 'package:dogshelter_shared/dogadjaj_volonter/data/dogadjaj_volonter_api.dart';
import 'package:dogshelter_shared/dogadjaj_volonter/domain/dogadjaj_volonter.dart';
import 'package:dogshelter_shared/volonter/data/volonter_api.dart';
import 'package:dogshelter_shared/volonter/domain/volonter.dart';
import '../../../core/paged_list_notifier.dart';
import '../../korisnici/data/korisnik_admin_api.dart';

final volonterApiProvider = Provider<VolonterApi>((ref) => VolonterApi(ref.watch(apiClientProvider)));
final aktivnostVolonteraApiProvider =
    Provider<AktivnostVolonteraApi>((ref) => AktivnostVolonteraApi(ref.watch(apiClientProvider)));
final dogadjajVolonterApiProvider =
    Provider<DogadjajVolonterApi>((ref) => DogadjajVolonterApi(ref.watch(apiClientProvider)));
final volonterKorisnikApiProvider =
    Provider<KorisnikAdminApi>((ref) => KorisnikAdminApi(ref.watch(apiClientProvider)));

final tipoviAktivnostiProvider = FutureProvider.autoDispose<List<TipAktivnosti>>((ref) {
  return ref.watch(aktivnostVolonteraApiProvider).getTipoviAktivnosti();
});

/// Backs "Dodaj volontera"'s "Postojeći korisnik" mode - active users who aren't already a
/// Volonter (VolonterService.Insert rejects a duplicate anyway, but there's no reason to offer
/// one) or an Admin. Same filter as posjetaKorisnikOptionsProvider's walk-in booking picker.
final volonterKorisnikOptionsProvider = FutureProvider.autoDispose<List<Korisnik>>((ref) async {
  final result = await ref.watch(volonterKorisnikApiProvider).search(page: 1, pageSize: 100);
  return result.items.where((k) => k.aktivan && !k.hasRole('Admin') && !k.hasRole('Volonter')).toList();
});

class VolonterListNotifier extends PagedListNotifier<Volonter> {
  VolonterListNotifier(this._api);

  final VolonterApi _api;
  bool? _aktivan;

  bool? get aktivan => _aktivan;

  @override
  Future<PagedResult<Volonter>> fetch({String? query, required int page}) =>
      _api.search(page: page, ime: query, aktivan: _aktivan);

  Future<void> filterByAktivan(bool? aktivan) async {
    _aktivan = aktivan;
    await resetAndReload();
  }

  Future<Volonter> create({required int korisnikId, required DateTime datumPridruzivanja, String? napomena}) async {
    final created = await _api.insert(korisnikId: korisnikId, datumPridruzivanja: datumPridruzivanja, napomena: napomena);
    await refresh();
    return created;
  }

  Future<void> update(int id, {required bool aktivan, String? napomena}) async {
    await _api.update(id, aktivan: aktivan, napomena: napomena);
    await refresh();
  }
}

// autoDispose: the list's ukupnoSati column changes from a different screen (logging an
// activity on volonter_detail_screen.dart), so a cached instance would show stale hours.
final volonterListProvider =
    StateNotifierProvider.autoDispose<VolonterListNotifier, AsyncValue<PagedResult<Volonter>>>((ref) {
  return VolonterListNotifier(ref.watch(volonterApiProvider));
});

final volonterFormApiProvider = Provider<KorisnikAdminApi>((ref) => ref.watch(volonterKorisnikApiProvider));

/// autoDispose so navigating back to a volunteer's profile after an edit always shows the
/// latest saved state instead of a stale cache.
final volonterDetailProvider = FutureProvider.autoDispose.family<Volonter, int>((ref, id) {
  return ref.watch(volonterApiProvider).getById(id);
});

class VolonterAktivnostiNotifier extends PagedListNotifier<AktivnostVolontera> {
  VolonterAktivnostiNotifier(this._api, this._volonterId);

  final AktivnostVolonteraApi _api;
  final int _volonterId;

  @override
  Future<PagedResult<AktivnostVolontera>> fetch({String? query, required int page}) =>
      _api.getAktivnosti(page: page, volonterId: _volonterId);

  Future<void> log({
    required int tipAktivnostiId,
    required DateTime datumAktivnosti,
    required double brojSati,
    String? opis,
  }) async {
    await _api.logAktivnost(
      volonterId: _volonterId,
      tipAktivnostiId: tipAktivnostiId,
      datumAktivnosti: datumAktivnosti,
      brojSati: brojSati,
      opis: opis,
    );
    await refresh();
  }

  Future<void> remove(int id) async {
    await _api.delete(id);
    await refresh();
  }
}

final volonterAktivnostiProvider = StateNotifierProvider.autoDispose
    .family<VolonterAktivnostiNotifier, AsyncValue<PagedResult<AktivnostVolontera>>, int>((ref, volonterId) {
  return VolonterAktivnostiNotifier(ref.watch(aktivnostVolonteraApiProvider), volonterId);
});

/// Read-only "Dodijeljeni događaji" section on the volunteer profile. Assignment itself only
/// happens from the Događaji side.
final volonterDodijeljeniDogadjajiProvider =
    FutureProvider.autoDispose.family<List<DogadjajVolonter>, int>((ref, volonterId) async {
  final result = await ref.watch(dogadjajVolonterApiProvider).search(volonterId: volonterId);
  return result.items;
});
