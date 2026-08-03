import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import 'package:dogshelter_shared/core/paged_result.dart';
import 'package:dogshelter_shared/obavijest/data/obavijest_api.dart';
import 'package:dogshelter_shared/obavijest/domain/obavijest.dart';
import 'package:dogshelter_shared/obavijest/domain/obavijest_list_item.dart';
import '../../../core/paged_list_notifier.dart';

final obavijestApiProvider = Provider<ObavijestApi>((ref) => ObavijestApi(ref.watch(apiClientProvider)));

class ObavijestListNotifier extends PagedListNotifier<ObavijestListItem> {
  ObavijestListNotifier(this._api);

  final ObavijestApi _api;
  bool? _aktivna;

  bool? get aktivna => _aktivna;

  @override
  Future<PagedResult<ObavijestListItem>> fetch({String? query, required int page}) =>
      _api.getObavijesti(page: page, naslov: query, aktivna: _aktivna);

  Future<void> filterByAktivna(bool? aktivna) async {
    _aktivna = aktivna;
    await resetAndReload();
  }

  Future<void> create(ObavijestFormData data, File slika) async {
    await _api.insert(data, slika);
    await refresh();
  }

  Future<void> update(int id, ObavijestFormData data, {File? slika}) async {
    await _api.update(id, data, slika: slika);
    await refresh();
  }

  Future<void> remove(int id) async {
    await _api.delete(id);
    await refresh();
  }
}

final obavijestListProvider =
    StateNotifierProvider<ObavijestListNotifier, AsyncValue<PagedResult<ObavijestListItem>>>((ref) {
  return ObavijestListNotifier(ref.watch(obavijestApiProvider));
});

/// Backs the dedicated /obavijesti/:id edit form. autoDispose so reopening the form after an
/// update always shows the latest saved state instead of a stale cache.
final obavijestDetailProvider = FutureProvider.autoDispose.family<Obavijest, int>((ref, id) {
  return ref.watch(obavijestApiProvider).getObavijestById(id);
});
