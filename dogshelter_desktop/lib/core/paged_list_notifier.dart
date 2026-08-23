import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/core/paged_result.dart';

/// Shared paging behavior for the app's admin list screens (Postavke lookup tables,
/// Korisnici): tracks the current search term + page, refetches on search (resetting to
/// page 1) or explicit page navigation. Subclasses just implement [fetch] and add their own
/// create/update/delete methods that call [refresh] afterwards.
abstract class PagedListNotifier<T> extends StateNotifier<AsyncValue<PagedResult<T>>> {
  PagedListNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  String? _query;
  int _page = 1;

  Future<PagedResult<T>> fetch({String? query, required int page});

  // autoDispose subclasses may already be disposed when this runs (stale ref.read from a
  // screen that's navigated away) - reading or writing `state` after dispose throws, so guard
  // both before the request and after it resolves.
  Future<void> load({String? query}) async {
    if (!mounted) return;
    final isNewQuery = query != null;
    _query = query ?? _query;
    if (isNewQuery) _page = 1;
    if (!state.hasValue) {
      state = const AsyncValue.loading();
    }
    final result = await AsyncValue.guard(() => fetch(query: _query, page: _page));
    if (mounted) state = result;
  }

  Future<void> goToPage(int page) async {
    if (!mounted) return;
    _page = page;
    final result = await AsyncValue.guard(() => fetch(query: _query, page: _page));
    if (mounted) state = result;
  }

  Future<void> refresh() => load();

  /// For subclasses with non-search filter fields (e.g. a status dropdown) that need to
  /// jump back to page 1 without going through the search-only [load] parameter.
  Future<void> resetAndReload() async {
    if (!mounted) return;
    _page = 1;
    final result = await AsyncValue.guard(() => fetch(query: _query, page: _page));
    if (mounted) state = result;
  }
}
