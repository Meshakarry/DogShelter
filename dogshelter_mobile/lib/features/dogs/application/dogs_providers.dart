import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_notifier.dart';
import '../data/dogs_api.dart';
import '../domain/lookups.dart';
import '../domain/pas.dart';
import '../domain/pas_list_item.dart';
import '../domain/spol.dart';

final dogsApiProvider = Provider<DogsApi>((ref) => DogsApi(ref.watch(apiClientProvider)));

typedef DogLookups = ({List<Rasa> rase, List<StatusPsa> statusi, List<VelicinaPsa> velicine});

final dogLookupsProvider = FutureProvider<DogLookups>((ref) async {
  final api = ref.watch(dogsApiProvider);
  // Issued together, not sequentially, per the parallelizable-HTTP-calls rule.
  final results = await Future.wait([api.getRase(), api.getStatusi(), api.getVelicine()]);
  return (
    rase: results[0] as List<Rasa>,
    statusi: results[1] as List<StatusPsa>,
    velicine: results[2] as List<VelicinaPsa>,
  );
});

final dogDetailProvider = FutureProvider.family<Pas, int>((ref, id) {
  return ref.watch(dogsApiProvider).getDogById(id);
});

class DogFilters {
  const DogFilters({this.naziv, this.rasaId, this.statusPsaId, this.velicinaPsaId, this.spol});

  final String? naziv;
  final int? rasaId;
  final int? statusPsaId;
  final int? velicinaPsaId;
  final Spol? spol;

  bool get isEmpty =>
      (naziv == null || naziv!.isEmpty) &&
      rasaId == null &&
      statusPsaId == null &&
      velicinaPsaId == null &&
      spol == null;

  DogFilters copyWith({
    String? naziv,
    bool clearNaziv = false,
    int? rasaId,
    bool clearRasaId = false,
    int? statusPsaId,
    bool clearStatusPsaId = false,
    int? velicinaPsaId,
    bool clearVelicinaPsaId = false,
    Spol? spol,
    bool clearSpol = false,
  }) {
    return DogFilters(
      naziv: clearNaziv ? null : (naziv ?? this.naziv),
      rasaId: clearRasaId ? null : (rasaId ?? this.rasaId),
      statusPsaId: clearStatusPsaId ? null : (statusPsaId ?? this.statusPsaId),
      velicinaPsaId: clearVelicinaPsaId ? null : (velicinaPsaId ?? this.velicinaPsaId),
      spol: clearSpol ? null : (spol ?? this.spol),
    );
  }
}

class DogsListState {
  const DogsListState({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoading = false,
    this.error,
    this.filters = const DogFilters(),
  });

  final List<PasListItem> items;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final Object? error;
  final DogFilters filters;

  DogsListState copyWith({
    List<PasListItem>? items,
    int? page,
    bool? hasMore,
    bool? isLoading,
    Object? error,
    bool clearError = false,
    DogFilters? filters,
  }) {
    return DogsListState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      filters: filters ?? this.filters,
    );
  }
}

class DogsListNotifier extends StateNotifier<DogsListState> {
  DogsListNotifier(this._api) : super(const DogsListState()) {
    loadFirstPage();
  }

  final DogsApi _api;
  static const _pageSize = 20;

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _api.getDogs(
        page: 1,
        pageSize: _pageSize,
        naziv: state.filters.naziv,
        rasaId: state.filters.rasaId,
        statusPsaId: state.filters.statusPsaId,
        velicinaPsaId: state.filters.velicinaPsaId,
        spol: state.filters.spol,
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
      final result = await _api.getDogs(
        page: nextPage,
        pageSize: _pageSize,
        naziv: state.filters.naziv,
        rasaId: state.filters.rasaId,
        statusPsaId: state.filters.statusPsaId,
        velicinaPsaId: state.filters.velicinaPsaId,
        spol: state.filters.spol,
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

  Future<void> applyFilters(DogFilters filters) async {
    state = state.copyWith(filters: filters, items: [], page: 1, hasMore: true);
    await loadFirstPage();
  }

  Future<void> applySearch(String naziv) async {
    await applyFilters(state.filters.copyWith(naziv: naziv, clearNaziv: naziv.isEmpty));
  }
}

final dogsListProvider = StateNotifierProvider<DogsListNotifier, DogsListState>((ref) {
  return DogsListNotifier(ref.watch(dogsApiProvider));
});
