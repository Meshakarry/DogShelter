import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_notifier.dart';
import '../data/donations_api.dart';
import '../domain/donacija.dart';
import '../domain/jedinica_mjere.dart';
import '../domain/kategorija_donacije.dart';
import '../domain/potreba_azila.dart';
import '../domain/status_donacije.dart';
import '../domain/tip_donacije.dart';

final donationsApiProvider = Provider<DonationsApi>((ref) => DonationsApi(ref.watch(apiClientProvider)));

final tipDonacijeLookupProvider = FutureProvider<List<TipDonacije>>((ref) {
  return ref.watch(donationsApiProvider).getTipovi();
});

final statusDonacijeLookupProvider = FutureProvider<List<StatusDonacije>>((ref) {
  return ref.watch(donationsApiProvider).getStatusi();
});

final kategorijaDonacijeLookupProvider = FutureProvider<List<KategorijaDonacije>>((ref) {
  return ref.watch(donationsApiProvider).getKategorije();
});

final jedinicaMjereLookupProvider = FutureProvider<List<JedinicaMjere>>((ref) {
  return ref.watch(donationsApiProvider).getJedinice();
});

// autoDispose so re-opening the donation form always shows the admin's latest curated needs.
final potrebeAzilaProvider = FutureProvider.autoDispose<List<PotrebaAzila>>((ref) {
  return ref.watch(donationsApiProvider).getPotrebeAzila();
});

final donacijaDetailProvider = FutureProvider.autoDispose.family<Donacija, int>((ref, id) {
  return ref.watch(donationsApiProvider).getDonacijaById(id);
});

class DonacijaListState {
  const DonacijaListState({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoading = false,
    this.error,
    this.statusDonacijeId,
  });

  final List<Donacija> items;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final Object? error;
  final int? statusDonacijeId;

  DonacijaListState copyWith({
    List<Donacija>? items,
    int? page,
    bool? hasMore,
    bool? isLoading,
    Object? error,
    bool clearError = false,
    int? statusDonacijeId,
    bool clearStatusDonacijeId = false,
  }) {
    return DonacijaListState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      statusDonacijeId: clearStatusDonacijeId ? null : (statusDonacijeId ?? this.statusDonacijeId),
    );
  }
}

class DonacijaListNotifier extends StateNotifier<DonacijaListState> {
  DonacijaListNotifier(this._api) : super(const DonacijaListState()) {
    loadFirstPage();
  }

  final DonationsApi _api;
  static const _pageSize = 20;

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _api.getDonacije(
        page: 1,
        pageSize: _pageSize,
        statusDonacijeId: state.statusDonacijeId,
      );
      state = state.copyWith(items: result.items, page: 1, hasMore: result.hasMore, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final nextPage = state.page + 1;
      final result = await _api.getDonacije(
        page: nextPage,
        pageSize: _pageSize,
        statusDonacijeId: state.statusDonacijeId,
      );
      state = state.copyWith(
        items: [...state.items, ...result.items],
        page: nextPage,
        hasMore: result.hasMore,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> applyStatusFilter(int? statusDonacijeId) async {
    state = state.copyWith(
      statusDonacijeId: statusDonacijeId,
      clearStatusDonacijeId: statusDonacijeId == null,
      items: [],
      page: 1,
      hasMore: true,
    );
    await loadFirstPage();
  }
}

final donacijaListProvider = StateNotifierProvider<DonacijaListNotifier, DonacijaListState>((ref) {
  return DonacijaListNotifier(ref.watch(donationsApiProvider));
});
