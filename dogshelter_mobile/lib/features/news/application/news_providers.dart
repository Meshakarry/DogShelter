import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import '../data/news_api.dart';
import '../domain/obavijest.dart';
import '../domain/obavijest_list_item.dart';

final newsApiProvider = Provider<NewsApi>((ref) => NewsApi(ref.watch(apiClientProvider)));

final obavijestDetailProvider = FutureProvider.family<Obavijest, int>((ref, id) {
  return ref.watch(newsApiProvider).getObavijestById(id);
});

class NewsListState {
  const NewsListState({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoading = false,
    this.error,
  });

  final List<ObavijestListItem> items;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final Object? error;

  NewsListState copyWith({
    List<ObavijestListItem>? items,
    int? page,
    bool? hasMore,
    bool? isLoading,
    Object? error,
    bool clearError = false,
  }) {
    return NewsListState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class NewsListNotifier extends StateNotifier<NewsListState> {
  NewsListNotifier(this._api) : super(const NewsListState()) {
    loadFirstPage();
  }

  final NewsApi _api;
  static const _pageSize = 20;

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _api.getObavijesti(page: 1, pageSize: _pageSize);
      state = state.copyWith(items: result.items, page: 1, hasMore: result.hasMore, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final nextPage = state.page + 1;
      final result = await _api.getObavijesti(page: nextPage, pageSize: _pageSize);
      state = state.copyWith(
        items: [...state.items, ...result.items],
        page: nextPage,
        hasMore: result.hasMore,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }
}

final newsListProvider = StateNotifierProvider<NewsListNotifier, NewsListState>((ref) {
  return NewsListNotifier(ref.watch(newsApiProvider));
});
