import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import 'package:dogshelter_shared/auth/domain/korisnik.dart';
import 'package:dogshelter_shared/pas/data/pas_api.dart';
import 'package:dogshelter_shared/pas/domain/pas_list_item.dart';
import 'package:dogshelter_shared/posjeta/data/posjeta_api.dart';
import 'package:dogshelter_shared/posjeta/domain/posjeta.dart';
import '../../korisnici/data/korisnik_admin_api.dart';
import '../../postavke/data/lookup_api.dart';
import '../../postavke/domain/lookup_item.dart';

const statusPosjeteConfig =
    LookupTableConfig(path: '/api/StatusPosjete', idKey: 'statusPosjeteId', label: 'status posjete');

final posjetaApiProvider = Provider<PosjetaApi>((ref) => PosjetaApi(ref.watch(apiClientProvider)));
final posjetaPasApiProvider = Provider<PasApi>((ref) => PasApi(ref.watch(apiClientProvider)));
final posjetaKorisnikApiProvider =
    Provider<KorisnikAdminApi>((ref) => KorisnikAdminApi(ref.watch(apiClientProvider)));

final statusPosjeteOptionsProvider = FutureProvider.autoDispose<List<LookupItem>>((ref) async {
  final api = LookupApi(ref.watch(apiClientProvider), statusPosjeteConfig);
  return (await api.search()).items;
});

/// Backs the walk-in booking dialog's Korisnik dropdown. Filtered to aktivan-only (the backend's
/// soft-delete/anonymize path always sets Aktivan=false, so this also excludes anonymized
/// accounts) and excludes the Admin role, since a walk-in visit is booked on behalf of a visitor.
final posjetaKorisnikOptionsProvider = FutureProvider.autoDispose<List<Korisnik>>((ref) async {
  final result = await ref.watch(posjetaKorisnikApiProvider).search(page: 1, pageSize: 100);
  return result.items.where((k) => k.aktivan && !k.hasRole('Admin')).toList();
});

/// Backs the walk-in booking dialog's optional Pas dropdown.
final posjetaDogOptionsProvider = FutureProvider.autoDispose<List<PasListItem>>((ref) async {
  final result = await ref.watch(posjetaPasApiProvider).getDogs(page: 1, pageSize: 100);
  return result.items;
});

/// Exact taken DatumVrijeme values for a given day - backs the walk-in booking dialog's time
/// slot grid. autoDispose so re-opening the dialog on a previously-picked date always re-checks
/// fresh instead of reusing a stale answer.
final posjetaZauzetiTerminiProvider = FutureProvider.autoDispose.family<List<DateTime>, DateTime>((ref, datum) {
  return ref.watch(posjetaApiProvider).getZauzetiTermini(datum);
});

class PosjetaFilters {
  const PosjetaFilters({this.statusPosjeteId, this.datumOd, this.datumDo});

  final int? statusPosjeteId;
  final DateTime? datumOd;
  final DateTime? datumDo;

  PosjetaFilters copyWith({
    int? statusPosjeteId,
    bool clearStatusPosjeteId = false,
    DateTime? datumOd,
    bool clearDatumOd = false,
    DateTime? datumDo,
    bool clearDatumDo = false,
  }) {
    return PosjetaFilters(
      statusPosjeteId: clearStatusPosjeteId ? null : (statusPosjeteId ?? this.statusPosjeteId),
      datumOd: clearDatumOd ? null : (datumOd ?? this.datumOd),
      datumDo: clearDatumDo ? null : (datumDo ?? this.datumDo),
    );
  }
}

class PosjetaListState {
  const PosjetaListState({
    this.items = const [],
    this.page = 1,
    this.pageSize = 20,
    this.totalCount = 0,
    this.isLoading = false,
    this.error,
    this.filters = const PosjetaFilters(),
  });

  final List<Posjeta> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final bool isLoading;
  final Object? error;
  final PosjetaFilters filters;

  int get totalPages => totalCount == 0 ? 1 : ((totalCount + pageSize - 1) ~/ pageSize);

  PosjetaListState copyWith({
    List<Posjeta>? items,
    int? page,
    int? totalCount,
    bool? isLoading,
    Object? error,
    bool clearError = false,
    PosjetaFilters? filters,
  }) {
    return PosjetaListState(
      items: items ?? this.items,
      page: page ?? this.page,
      pageSize: pageSize,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      filters: filters ?? this.filters,
    );
  }
}

class PosjetaListNotifier extends StateNotifier<PosjetaListState> {
  PosjetaListNotifier(this._api) : super(const PosjetaListState()) {
    load();
  }

  final PosjetaApi _api;

  Future<void> load({int? page}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _api.getPosjete(
        page: page ?? state.page,
        pageSize: state.pageSize,
        statusPosjeteId: state.filters.statusPosjeteId,
        datumOd: state.filters.datumOd,
        datumDo: state.filters.datumDo,
      );
      state = state.copyWith(items: result.items, page: result.page, totalCount: result.totalCount, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> applyFilters(PosjetaFilters filters) async {
    state = state.copyWith(filters: filters, page: 1);
    await load(page: 1);
  }

  Future<void> goToPage(int page) => load(page: page);

  Future<void> potvrdi(int id) async {
    await _api.potvrdi(id);
    await load();
  }

  Future<void> zavrsi(int id) async {
    await _api.zavrsi(id);
    await load();
  }

  Future<void> otkazi(int id, String razlogOtkazivanja) async {
    await _api.otkaziPosjetu(id, razlogOtkazivanja: razlogOtkazivanja);
    await load();
  }

  Future<void> bookWalkIn({
    required int korisnikId,
    required DateTime datumVrijeme,
    int? pasId,
    String? napomena,
  }) async {
    await _api.insertAdmin(korisnikId: korisnikId, datumVrijeme: datumVrijeme, pasId: pasId, napomena: napomena);
    await load();
  }
}

final posjetaListProvider = StateNotifierProvider.autoDispose<PosjetaListNotifier, PosjetaListState>((ref) {
  return PosjetaListNotifier(ref.watch(posjetaApiProvider));
});

/// Backs the dedicated /posjete/:id detail page. Invalidated after potvrdi/otkazi/zavrsi from
/// that page so the detail re-fetches instead of showing stale status.
final posjetaDetailProvider = FutureProvider.autoDispose.family<Posjeta, int>((ref, id) {
  return ref.watch(posjetaApiProvider).getPosjetaById(id);
});
