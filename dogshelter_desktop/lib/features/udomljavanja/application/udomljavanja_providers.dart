import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import 'package:dogshelter_shared/core/paged_result.dart';
import 'package:dogshelter_shared/udomljavanje/data/udomljavanje_api.dart';
import 'package:dogshelter_shared/udomljavanje/domain/udomljavanje.dart';
import '../../../core/paged_list_notifier.dart';

final udomljavanjeApiProvider = Provider<UdomljavanjeApi>((ref) => UdomljavanjeApi(ref.watch(apiClientProvider)));

class UdomljavanjeListNotifier extends PagedListNotifier<Udomljavanje> {
  UdomljavanjeListNotifier(this._api);

  final UdomljavanjeApi _api;
  DateTime? _datumOd;
  DateTime? _datumDo;

  DateTime? get datumOd => _datumOd;
  DateTime? get datumDo => _datumDo;

  @override
  Future<PagedResult<Udomljavanje>> fetch({String? query, required int page}) =>
      _api.getUdomljavanja(page: page, datumOd: _datumOd, datumDo: _datumDo);

  Future<void> filterByDateRange({DateTime? datumOd, DateTime? datumDo}) async {
    _datumOd = datumOd;
    _datumDo = datumDo;
    await resetAndReload();
  }
}

final udomljavanjeListProvider =
    StateNotifierProvider<UdomljavanjeListNotifier, AsyncValue<PagedResult<Udomljavanje>>>((ref) {
  return UdomljavanjeListNotifier(ref.watch(udomljavanjeApiProvider));
});

/// Backs the dedicated /udomljavanja/:id detail page.
final udomljavanjeDetailProvider = FutureProvider.autoDispose.family<Udomljavanje, int>((ref, id) {
  return ref.watch(udomljavanjeApiProvider).getUdomljavanjeById(id);
});
