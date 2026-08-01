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

  @override
  Future<PagedResult<Udomljavanje>> fetch({String? query, required int page}) =>
      _api.getUdomljavanja(page: page);
}

final udomljavanjeListProvider =
    StateNotifierProvider<UdomljavanjeListNotifier, AsyncValue<PagedResult<Udomljavanje>>>((ref) {
  return UdomljavanjeListNotifier(ref.watch(udomljavanjeApiProvider));
});
