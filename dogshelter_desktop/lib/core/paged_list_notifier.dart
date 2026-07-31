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

  Future<void> load({String? query}) async {
    final isNewQuery = query != null;
    _query = query ?? _query;
    if (isNewQuery) _page = 1;
    if (!state.hasValue) {
      state = const AsyncValue.loading();
    }
    state = await AsyncValue.guard(() => fetch(query: _query, page: _page));
  }

  Future<void> goToPage(int page) async {
    _page = page;
    state = await AsyncValue.guard(() => fetch(query: _query, page: _page));
  }

  Future<void> refresh() => load();
}
