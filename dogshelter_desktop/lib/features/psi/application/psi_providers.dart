import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import 'package:dogshelter_shared/pas/data/pas_api.dart';
import 'package:dogshelter_shared/pas/domain/lookups.dart';
import 'package:dogshelter_shared/pas/domain/pas.dart';
import 'package:dogshelter_shared/pas/domain/pas_list_item.dart';
import 'package:dogshelter_shared/pas/domain/slika_psa.dart';
import '../../postavke/data/lookup_api.dart';
import '../../postavke/domain/lookup_item.dart';

const rasaConfig = LookupTableConfig(path: '/api/Rasa', idKey: 'rasaId', label: 'rasa');
const statusPsaConfig = LookupTableConfig(path: '/api/StatusPsa', idKey: 'statusPsaId', label: 'status psa');
const velicinaPsaConfig = LookupTableConfig(path: '/api/VelicinaPsa', idKey: 'velicinaPsaId', label: 'veličina psa');

final pasApiProvider = Provider<PasApi>((ref) => PasApi(ref.watch(apiClientProvider)));

typedef PsiFormLookups = ({List<Rasa> rase, List<StatusPsa> statusi, List<VelicinaPsa> velicine});

/// Reuses the desktop's generic LookupApi (same as Postavke/Pocetna) instead of PasApi's
/// own typed getRase/getStatusi/getVelicine, which exist only for mobile's continued use.
final psiFormLookupsProvider = FutureProvider.autoDispose<PsiFormLookups>((ref) async {
  final client = ref.watch(apiClientProvider);
  final rasaFuture = LookupApi(client, rasaConfig).search();
  final statusFuture = LookupApi(client, statusPsaConfig).search();
  final velicinaFuture = LookupApi(client, velicinaPsaConfig).search();
  return (
    rase: (await rasaFuture).items.map((e) => Rasa(rasaId: e.id, naziv: e.naziv)).toList(),
    statusi: (await statusFuture).items.map((e) => StatusPsa(statusPsaId: e.id, naziv: e.naziv)).toList(),
    velicine: (await velicinaFuture).items.map((e) => VelicinaPsa(velicinaPsaId: e.id, naziv: e.naziv)).toList(),
  );
});

class PsiFilters {
  const PsiFilters({this.naziv, this.rasaId, this.statusPsaId, this.velicinaPsaId, this.aktivan = true});

  final String? naziv;
  final int? rasaId;
  final int? statusPsaId;
  final int? velicinaPsaId;
  final bool? aktivan;

  PsiFilters copyWith({
    String? naziv,
    bool clearNaziv = false,
    int? rasaId,
    bool clearRasaId = false,
    int? statusPsaId,
    bool clearStatusPsaId = false,
    int? velicinaPsaId,
    bool clearVelicinaPsaId = false,
    bool? aktivan,
    bool clearAktivan = false,
  }) {
    return PsiFilters(
      naziv: clearNaziv ? null : (naziv ?? this.naziv),
      rasaId: clearRasaId ? null : (rasaId ?? this.rasaId),
      statusPsaId: clearStatusPsaId ? null : (statusPsaId ?? this.statusPsaId),
      velicinaPsaId: clearVelicinaPsaId ? null : (velicinaPsaId ?? this.velicinaPsaId),
      aktivan: clearAktivan ? null : (aktivan ?? this.aktivan),
    );
  }
}

class PsiListState {
  const PsiListState({
    this.items = const [],
    this.page = 1,
    this.pageSize = 20,
    this.totalCount = 0,
    this.isLoading = false,
    this.error,
    this.filters = const PsiFilters(),
  });

  final List<PasListItem> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final bool isLoading;
  final Object? error;
  final PsiFilters filters;

  int get totalPages => totalCount == 0 ? 1 : ((totalCount + pageSize - 1) ~/ pageSize);

  PsiListState copyWith({
    List<PasListItem>? items,
    int? page,
    int? totalCount,
    bool? isLoading,
    Object? error,
    bool clearError = false,
    PsiFilters? filters,
  }) {
    return PsiListState(
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

class PsiListNotifier extends StateNotifier<PsiListState> {
  PsiListNotifier(this._api) : super(const PsiListState()) {
    load();
  }

  final PasApi _api;

  Future<void> load({int? page}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _api.getDogs(
        page: page ?? state.page,
        pageSize: state.pageSize,
        naziv: state.filters.naziv,
        rasaId: state.filters.rasaId,
        statusPsaId: state.filters.statusPsaId,
        velicinaPsaId: state.filters.velicinaPsaId,
        aktivan: state.filters.aktivan,
      );
      state = state.copyWith(items: result.items, page: result.page, totalCount: result.totalCount, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> applyFilters(PsiFilters filters) async {
    state = state.copyWith(filters: filters, page: 1);
    await load(page: 1);
  }

  Future<void> applySearch(String naziv) async {
    await applyFilters(state.filters.copyWith(naziv: naziv, clearNaziv: naziv.isEmpty));
  }

  Future<void> goToPage(int page) => load(page: page);

  Future<void> remove(int id) async {
    await _api.delete(id);
    // Deleting the last row on a page that's no longer the first should step back a page
    // instead of landing on a now-empty page.
    final targetPage = (state.items.length == 1 && state.page > 1) ? state.page - 1 : state.page;
    await load(page: targetPage);
  }
}

final psiListProvider = StateNotifierProvider.autoDispose<PsiListNotifier, PsiListState>((ref) {
  return PsiListNotifier(ref.watch(pasApiProvider));
});

/// Loads an existing Pas for the edit form. Null id (new dog) is handled entirely
/// client-side by the form screen, so this provider is only ever watched in edit mode.
final psiDetailProvider = FutureProvider.autoDispose.family<Pas, int>((ref, id) {
  return ref.watch(pasApiProvider).getDogById(id);
});

class PsiGalleryNotifier extends StateNotifier<AsyncValue<List<SlikaPsa>>> {
  PsiGalleryNotifier(this._api, this.pasId) : super(const AsyncValue.loading()) {
    _load();
  }

  final PasApi _api;
  final int pasId;

  Future<void> _load() async {
    state = await AsyncValue.guard(() async => (await _api.getDogById(pasId)).slike);
  }

  Future<void> add(File image) async {
    final current = state.valueOrNull ?? [];
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _api.addGalleryImage(pasId, image, current.length);
      return (await _api.getDogById(pasId)).slike;
    });
  }

  Future<void> remove(int slikaId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _api.deleteGalleryImage(pasId, slikaId);
      return (await _api.getDogById(pasId)).slike;
    });
  }
}

final psiGalleryProvider =
    StateNotifierProvider.autoDispose.family<PsiGalleryNotifier, AsyncValue<List<SlikaPsa>>, int>((ref, pasId) {
  return PsiGalleryNotifier(ref.watch(pasApiProvider), pasId);
});
