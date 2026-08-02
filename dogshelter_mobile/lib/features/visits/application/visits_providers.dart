import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import 'package:dogshelter_shared/pas/domain/pas_list_item.dart';
import 'package:dogshelter_shared/posjeta/data/posjeta_api.dart';
import 'package:dogshelter_shared/posjeta/domain/posjeta.dart';
import 'package:dogshelter_shared/posjeta/domain/status_posjete.dart';
import '../../dogs/application/dogs_providers.dart';

final visitsApiProvider = Provider<PosjetaApi>((ref) => PosjetaApi(ref.watch(apiClientProvider)));

final statusPosjeteLookupProvider = FutureProvider<List<StatusPosjete>>((ref) {
  return ref.watch(visitsApiProvider).getStatusi();
});

// Backs the optional dog picker in the general-visit booking sheet - a single pageSize=100
// request covers the full dog list for the dropdown. Excludes already-adopted dogs - the backend
// rejects booking a visit for one anyway, so offering them in the picker would just be a dead end.
final dogPickerOptionsProvider = FutureProvider<List<PasListItem>>((ref) async {
  final result = await ref.watch(dogsApiProvider).getDogs(page: 1, pageSize: 100);
  return result.items.where((dog) => dog.statusNaziv != 'Udomljen').toList();
});

// autoDispose so re-opening the booking sheet always re-checks fresh rather than reusing a stale
// answer from an earlier visit to the same date (e.g. after the user's own submit or cancel).
final zauzetiTerminiProvider = FutureProvider.autoDispose.family<List<DateTime>, DateTime>((ref, datum) {
  return ref.watch(visitsApiProvider).getZauzetiTermini(datum);
});

final posjetaDetailProvider = FutureProvider.family<Posjeta, int>((ref, id) {
  return ref.watch(visitsApiProvider).getPosjetaById(id);
});

class PosjetaListState {
  const PosjetaListState({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoading = false,
    this.error,
    this.statusPosjeteId,
  });

  final List<Posjeta> items;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final Object? error;
  final int? statusPosjeteId;

  PosjetaListState copyWith({
    List<Posjeta>? items,
    int? page,
    bool? hasMore,
    bool? isLoading,
    Object? error,
    bool clearError = false,
    int? statusPosjeteId,
    bool clearStatusPosjeteId = false,
  }) {
    return PosjetaListState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      statusPosjeteId: clearStatusPosjeteId ? null : (statusPosjeteId ?? this.statusPosjeteId),
    );
  }
}

class PosjetaListNotifier extends StateNotifier<PosjetaListState> {
  PosjetaListNotifier(this._api) : super(const PosjetaListState()) {
    loadFirstPage();
  }

  final PosjetaApi _api;
  static const _pageSize = 20;

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _api.getPosjete(
        page: 1,
        pageSize: _pageSize,
        statusPosjeteId: state.statusPosjeteId,
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
      final result = await _api.getPosjete(
        page: nextPage,
        pageSize: _pageSize,
        statusPosjeteId: state.statusPosjeteId,
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

  Future<void> applyStatusFilter(int? statusPosjeteId) async {
    state = state.copyWith(
      statusPosjeteId: statusPosjeteId,
      clearStatusPosjeteId: statusPosjeteId == null,
      items: [],
      page: 1,
      hasMore: true,
    );
    await loadFirstPage();
  }
}

final posjetaListProvider = StateNotifierProvider<PosjetaListNotifier, PosjetaListState>((ref) {
  return PosjetaListNotifier(ref.watch(visitsApiProvider));
});
