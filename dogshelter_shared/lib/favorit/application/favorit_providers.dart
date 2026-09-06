import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import '../data/favorit_api.dart';
import '../domain/favorit.dart';

final favoritApiProvider = Provider<FavoritApi>((ref) => FavoritApi(ref.watch(apiClientProvider)));

/// Single source of truth for "which dogs has the current user favorited" - shared between the
/// heart-toggle on the Pas detail screen and the "Moji favoriti" list so the two never disagree.
/// autoDispose: re-fetches whenever a screen watching it is re-entered, same precedent as
/// korisnikListProvider/volonterListProvider on desktop - a favorite added on one screen must show
/// up immediately on the other, not only after an app restart.
class FavoritListNotifier extends StateNotifier<AsyncValue<List<Favorit>>> {
  FavoritListNotifier(this._api) : super(const AsyncValue.loading()) {
    refresh();
  }

  final FavoritApi _api;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final items = await _api.getMine();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  bool isFavorited(int pasId) =>
      state.valueOrNull?.any((f) => f.pasId == pasId) ?? false;

  Future<void> toggle(int pasId) async {
    if (isFavorited(pasId)) {
      await _api.remove(pasId);
      state = AsyncValue.data([
        for (final f in state.valueOrNull ?? []) if (f.pasId != pasId) f,
      ]);
    } else {
      final added = await _api.add(pasId);
      state = AsyncValue.data([added, ...state.valueOrNull ?? []]);
    }
  }
}

final favoritListProvider = StateNotifierProvider.autoDispose<FavoritListNotifier, AsyncValue<List<Favorit>>>((ref) {
  return FavoritListNotifier(ref.watch(favoritApiProvider));
});
