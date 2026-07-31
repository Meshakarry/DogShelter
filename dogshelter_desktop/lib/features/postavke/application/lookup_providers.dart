import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import 'package:dogshelter_shared/core/paged_result.dart';
import '../../../core/paged_list_notifier.dart';
import '../data/lookup_api.dart';
import '../domain/lookup_item.dart';

final lookupApiProvider = Provider.family<LookupApi, LookupTableConfig>((ref, config) {
  return LookupApi(ref.watch(apiClientProvider), config);
});

class LookupListNotifier extends PagedListNotifier<LookupItem> {
  LookupListNotifier(this._api);

  final LookupApi _api;

  @override
  Future<PagedResult<LookupItem>> fetch({String? query, required int page}) =>
      _api.search(naziv: query, page: page);

  Future<void> create(String naziv) async {
    await _api.create(naziv);
    await refresh();
  }

  Future<void> update(int id, String naziv) async {
    await _api.update(id, naziv);
    await refresh();
  }

  Future<void> remove(int id) async {
    await _api.delete(id);
    await refresh();
  }
}

final lookupListProvider =
    StateNotifierProvider.family<LookupListNotifier, AsyncValue<PagedResult<LookupItem>>, LookupTableConfig>(
        (ref, config) {
  return LookupListNotifier(ref.watch(lookupApiProvider(config)));
});
