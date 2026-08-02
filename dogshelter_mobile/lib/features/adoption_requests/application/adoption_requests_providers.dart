import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import 'package:dogshelter_shared/zahtjev_za_udomljavanje/data/zahtjev_za_udomljavanje_api.dart';
import 'package:dogshelter_shared/zahtjev_za_udomljavanje/domain/status_zahtjeva.dart';
import 'package:dogshelter_shared/zahtjev_za_udomljavanje/domain/zahtjev_za_udomljavanje.dart';

final zahtjevApiProvider =
    Provider<ZahtjevZaUdomljavanjeApi>((ref) => ZahtjevZaUdomljavanjeApi(ref.watch(apiClientProvider)));

final statusZahtjevaLookupProvider = FutureProvider<List<StatusZahtjeva>>((ref) {
  return ref.watch(zahtjevApiProvider).getStatusi();
});

final zahtjevDetailProvider = FutureProvider.family<ZahtjevZaUdomljavanje, int>((ref, id) {
  return ref.watch(zahtjevApiProvider).getZahtjevById(id);
});

// autoDispose so re-entering a dog's detail page always re-checks against the server rather
// than reusing a stale cached answer from before a request was submitted or resolved.
final hasPendingZahtjevProvider = FutureProvider.autoDispose.family<bool, int>((ref, pasId) async {
  final api = ref.watch(zahtjevApiProvider);
  final statuses = await ref.watch(statusZahtjevaLookupProvider.future);
  final naCekanju = statuses.where((s) => s.naziv == 'Na čekanju').firstOrNull;
  if (naCekanju == null) return false;
  final result = await api.getZahtjevi(
    page: 1,
    pageSize: 1,
    pasId: pasId,
    statusZahtjevaId: naCekanju.statusZahtjevaId,
  );
  return result.totalCount > 0;
});

class ZahtjevListState {
  const ZahtjevListState({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoading = false,
    this.error,
    this.statusZahtjevaId,
  });

  final List<ZahtjevZaUdomljavanje> items;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final Object? error;
  final int? statusZahtjevaId;

  ZahtjevListState copyWith({
    List<ZahtjevZaUdomljavanje>? items,
    int? page,
    bool? hasMore,
    bool? isLoading,
    Object? error,
    bool clearError = false,
    int? statusZahtjevaId,
    bool clearStatusZahtjevaId = false,
  }) {
    return ZahtjevListState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      statusZahtjevaId: clearStatusZahtjevaId ? null : (statusZahtjevaId ?? this.statusZahtjevaId),
    );
  }
}

class ZahtjevListNotifier extends StateNotifier<ZahtjevListState> {
  ZahtjevListNotifier(this._api) : super(const ZahtjevListState()) {
    loadFirstPage();
  }

  final ZahtjevZaUdomljavanjeApi _api;
  static const _pageSize = 20;

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _api.getZahtjevi(
        page: 1,
        pageSize: _pageSize,
        statusZahtjevaId: state.statusZahtjevaId,
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
      final result = await _api.getZahtjevi(
        page: nextPage,
        pageSize: _pageSize,
        statusZahtjevaId: state.statusZahtjevaId,
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

  Future<void> applyStatusFilter(int? statusZahtjevaId) async {
    state = state.copyWith(
      statusZahtjevaId: statusZahtjevaId,
      clearStatusZahtjevaId: statusZahtjevaId == null,
      items: [],
      page: 1,
      hasMore: true,
    );
    await loadFirstPage();
  }
}

final zahtjevListProvider = StateNotifierProvider<ZahtjevListNotifier, ZahtjevListState>((ref) {
  return ZahtjevListNotifier(ref.watch(zahtjevApiProvider));
});
