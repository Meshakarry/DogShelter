import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import 'package:dogshelter_shared/donacija/data/donacija_api.dart';
import 'package:dogshelter_shared/donacija/domain/donacija.dart';
import '../../postavke/data/lookup_api.dart';
import '../../postavke/domain/lookup_item.dart';

const tipDonacijeConfig = LookupTableConfig(path: '/api/TipDonacije', idKey: 'tipDonacijeId', label: 'tip donacije');
const statusDonacijeConfig =
    LookupTableConfig(path: '/api/StatusDonacije', idKey: 'statusDonacijeId', label: 'status donacije');

final donacijaApiProvider = Provider<DonacijaApi>((ref) => DonacijaApi(ref.watch(apiClientProvider)));

final tipDonacijeOptionsProvider = FutureProvider.autoDispose<List<LookupItem>>((ref) async {
  final api = LookupApi(ref.watch(apiClientProvider), tipDonacijeConfig);
  return (await api.search()).items;
});

final statusDonacijeOptionsProvider = FutureProvider.autoDispose<List<LookupItem>>((ref) async {
  final api = LookupApi(ref.watch(apiClientProvider), statusDonacijeConfig);
  return (await api.search()).items;
});

class DonacijaFilters {
  const DonacijaFilters({this.tipDonacijeId, this.statusDonacijeId, this.datumOd, this.datumDo});

  final int? tipDonacijeId;
  final int? statusDonacijeId;
  final DateTime? datumOd;
  final DateTime? datumDo;

  DonacijaFilters copyWith({
    int? tipDonacijeId,
    bool clearTipDonacijeId = false,
    int? statusDonacijeId,
    bool clearStatusDonacijeId = false,
    DateTime? datumOd,
    bool clearDatumOd = false,
    DateTime? datumDo,
    bool clearDatumDo = false,
  }) {
    return DonacijaFilters(
      tipDonacijeId: clearTipDonacijeId ? null : (tipDonacijeId ?? this.tipDonacijeId),
      statusDonacijeId: clearStatusDonacijeId ? null : (statusDonacijeId ?? this.statusDonacijeId),
      datumOd: clearDatumOd ? null : (datumOd ?? this.datumOd),
      datumDo: clearDatumDo ? null : (datumDo ?? this.datumDo),
    );
  }
}

class DonacijaListState {
  const DonacijaListState({
    this.items = const [],
    this.page = 1,
    this.pageSize = 20,
    this.totalCount = 0,
    this.isLoading = false,
    this.error,
    this.filters = const DonacijaFilters(),
  });

  final List<Donacija> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final bool isLoading;
  final Object? error;
  final DonacijaFilters filters;

  int get totalPages => totalCount == 0 ? 1 : ((totalCount + pageSize - 1) ~/ pageSize);

  DonacijaListState copyWith({
    List<Donacija>? items,
    int? page,
    int? totalCount,
    bool? isLoading,
    Object? error,
    bool clearError = false,
    DonacijaFilters? filters,
  }) {
    return DonacijaListState(
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

class DonacijaListNotifier extends StateNotifier<DonacijaListState> {
  DonacijaListNotifier(this._api) : super(const DonacijaListState()) {
    load();
  }

  final DonacijaApi _api;

  Future<void> load({int? page}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _api.getDonacije(
        page: page ?? state.page,
        pageSize: state.pageSize,
        tipDonacijeId: state.filters.tipDonacijeId,
        statusDonacijeId: state.filters.statusDonacijeId,
        datumOd: state.filters.datumOd,
        datumDo: state.filters.datumDo,
      );
      state = state.copyWith(items: result.items, page: result.page, totalCount: result.totalCount, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> applyFilters(DonacijaFilters filters) async {
    state = state.copyWith(filters: filters, page: 1);
    await load(page: 1);
  }

  Future<void> goToPage(int page) => load(page: page);

  Future<void> potvrdi(int id) async {
    await _api.potvrdi(id);
    await load();
  }

  Future<void> odbij(int id, String razlogOdbijanja) async {
    await _api.odbij(id, razlogOdbijanja: razlogOdbijanja);
    await load();
  }

  Future<void> refund(int id, String razlogVracanja) async {
    await _api.refund(id, razlogVracanja: razlogVracanja);
    await load();
  }
}

final donacijaListProvider = StateNotifierProvider.autoDispose<DonacijaListNotifier, DonacijaListState>((ref) {
  return DonacijaListNotifier(ref.watch(donacijaApiProvider));
});

/// Backs the dedicated /donacije/:id detail page. Invalidated after potvrdi/odbij/refund from
/// that page so the detail re-fetches instead of showing stale status.
final donacijaDetailProvider = FutureProvider.autoDispose.family<Donacija, int>((ref, id) {
  return ref.watch(donacijaApiProvider).getDonacijaById(id);
});
