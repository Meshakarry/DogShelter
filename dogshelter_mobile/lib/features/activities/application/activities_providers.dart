import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/aktivnost_volontera/data/aktivnost_volontera_api.dart';
import 'package:dogshelter_shared/aktivnost_volontera/domain/aktivnost_volontera.dart';
import 'package:dogshelter_shared/aktivnost_volontera/domain/tip_aktivnosti.dart';
import 'package:dogshelter_shared/auth/application/auth_notifier.dart';

final activitiesApiProvider =
    Provider<AktivnostVolonteraApi>((ref) => AktivnostVolonteraApi(ref.watch(apiClientProvider)));

final tipoviAktivnostiProvider = FutureProvider<List<TipAktivnosti>>((ref) {
  return ref.watch(activitiesApiProvider).getTipoviAktivnosti();
});

class AktivnostiListState {
  const AktivnostiListState({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoading = false,
    this.error,
  });

  final List<AktivnostVolontera> items;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final Object? error;

  AktivnostiListState copyWith({
    List<AktivnostVolontera>? items,
    int? page,
    bool? hasMore,
    bool? isLoading,
    Object? error,
    bool clearError = false,
  }) {
    return AktivnostiListState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AktivnostiListNotifier extends StateNotifier<AktivnostiListState> {
  AktivnostiListNotifier(this._api) : super(const AktivnostiListState()) {
    loadFirstPage();
  }

  final AktivnostVolonteraApi _api;
  static const _pageSize = 20;

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _api.getAktivnosti(page: 1, pageSize: _pageSize);
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
      final result = await _api.getAktivnosti(page: nextPage, pageSize: _pageSize);
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
}

final aktivnostiListProvider = StateNotifierProvider<AktivnostiListNotifier, AktivnostiListState>((ref) {
  return AktivnostiListNotifier(ref.watch(activitiesApiProvider));
});
