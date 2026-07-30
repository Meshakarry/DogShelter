import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import '../data/lookup_api.dart';
import '../domain/lookup_item.dart';

final lookupApiProvider = Provider.family<LookupApi, LookupTableConfig>((ref, config) {
  return LookupApi(ref.watch(apiClientProvider), config);
});

class LookupListNotifier extends StateNotifier<AsyncValue<List<LookupItem>>> {
  LookupListNotifier(this._api) : super(const AsyncValue.loading()) {
    load();
  }

  final LookupApi _api;
  String? _naziv;

  Future<void> load({String? naziv}) async {
    _naziv = naziv ?? _naziv;
    // Keep showing the current list while re-searching - only the very first load
    // (no data yet) should show the loading spinner, otherwise every keystroke-driven
    // search flashes the list to a spinner and back.
    if (!state.hasValue) {
      state = const AsyncValue.loading();
    }
    state = await AsyncValue.guard(() async {
      final result = await _api.search(naziv: _naziv);
      return result.items;
    });
  }

  Future<void> create(String naziv) async {
    await _api.create(naziv);
    await load();
  }

  Future<void> update(int id, String naziv) async {
    await _api.update(id, naziv);
    await load();
  }

  Future<void> remove(int id) async {
    await _api.delete(id);
    await load();
  }
}

final lookupListProvider =
    StateNotifierProvider.family<LookupListNotifier, AsyncValue<List<LookupItem>>, LookupTableConfig>((ref, config) {
  return LookupListNotifier(ref.watch(lookupApiProvider(config)));
});
