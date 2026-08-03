import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import 'package:dogshelter_shared/core/paged_result.dart';
import 'package:dogshelter_shared/dogadjaj/data/dogadjaj_api.dart';
import 'package:dogshelter_shared/dogadjaj/domain/dogadjaj.dart';
import 'package:dogshelter_shared/volonter/domain/volonter.dart';
import '../../../core/paged_list_notifier.dart';
import '../../volonteri/application/volonteri_providers.dart' show volonterApiProvider;

final dogadjajApiProvider = Provider<DogadjajApi>((ref) => DogadjajApi(ref.watch(apiClientProvider)));

class DogadjajListNotifier extends PagedListNotifier<Dogadjaj> {
  DogadjajListNotifier(this._api);

  final DogadjajApi _api;
  bool? _aktivan;
  DateTime? _datumOd;
  DateTime? _datumDo;

  bool? get aktivan => _aktivan;
  DateTime? get datumOd => _datumOd;
  DateTime? get datumDo => _datumDo;

  @override
  Future<PagedResult<Dogadjaj>> fetch({String? query, required int page}) => _api.getDogadjaji(
        page: page,
        naziv: query,
        aktivan: _aktivan,
        datumOd: _datumOd,
        datumDo: _datumDo,
      );

  Future<void> applyFilters({bool? aktivan, DateTime? datumOd, bool clearDatumOd = false, DateTime? datumDo, bool clearDatumDo = false}) async {
    _aktivan = aktivan;
    _datumOd = clearDatumOd ? null : (datumOd ?? _datumOd);
    _datumDo = clearDatumDo ? null : (datumDo ?? _datumDo);
    await resetAndReload();
  }

  Future<void> otkazi(int id) async {
    await _api.otkazi(id);
    await refresh();
  }
}

final dogadjajListProvider = StateNotifierProvider<DogadjajListNotifier, AsyncValue<PagedResult<Dogadjaj>>>((ref) {
  return DogadjajListNotifier(ref.watch(dogadjajApiProvider));
});

/// autoDispose so reopening the form after an update always shows the latest saved state.
final dogadjajDetailProvider = FutureProvider.autoDispose.family<Dogadjaj, int>((ref, id) {
  return ref.watch(dogadjajApiProvider).getDogadjajById(id);
});

/// Backs the "Zaduži volontera" picker - all active volunteers, filtered client-side against
/// the current roster so an already-assigned volunteer can't be picked again.
final aktivniVolonteriProvider = FutureProvider.autoDispose<List<Volonter>>((ref) async {
  final result = await ref.watch(volonterApiProvider).search(aktivan: true, pageSize: 100);
  return result.items;
});
