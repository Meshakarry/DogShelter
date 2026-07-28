import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_notifier.dart';
import '../data/events_api.dart';
import '../domain/dogadjaj.dart';

final eventsApiProvider = Provider<EventsApi>((ref) => EventsApi(ref.watch(apiClientProvider)));

final eventDetailProvider = FutureProvider.family<Dogadjaj, int>((ref, id) {
  return ref.watch(eventsApiProvider).getDogadjajById(id);
});

final isZaduzenProvider = FutureProvider.family<bool, int>((ref, dogadjajId) {
  return ref.watch(eventsApiProvider).isZaduzen(dogadjajId);
});

enum EventsTab { nadolazeci, prosli }

class EventsListState {
  const EventsListState({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoading = false,
    this.error,
    this.tab = EventsTab.nadolazeci,
  });

  final List<Dogadjaj> items;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final Object? error;
  final EventsTab tab;

  EventsListState copyWith({
    List<Dogadjaj>? items,
    int? page,
    bool? hasMore,
    bool? isLoading,
    Object? error,
    bool clearError = false,
    EventsTab? tab,
  }) {
    return EventsListState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      tab: tab ?? this.tab,
    );
  }
}

class EventsListNotifier extends StateNotifier<EventsListState> {
  EventsListNotifier(this._api) : super(const EventsListState()) {
    loadFirstPage();
  }

  final EventsApi _api;
  static const _pageSize = 20;

  // Nadolazeći passes DatumOd=now (soonest-first); Prošli passes DatumDo=now (backend then
  // orders most-recent-first) - see DogadjajService.Get's isPastOnlyQuery heuristic.
  DateTime? get _datumOd => state.tab == EventsTab.nadolazeci ? DateTime.now() : null;
  DateTime? get _datumDo => state.tab == EventsTab.prosli ? DateTime.now() : null;

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _api.getDogadjaji(page: 1, pageSize: _pageSize, datumOd: _datumOd, datumDo: _datumDo);
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
      final result = await _api.getDogadjaji(
        page: nextPage,
        pageSize: _pageSize,
        datumOd: _datumOd,
        datumDo: _datumDo,
      );
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

  Future<void> applyTab(EventsTab tab) async {
    if (tab == state.tab) return;
    state = state.copyWith(tab: tab, items: [], page: 1, hasMore: true);
    await loadFirstPage();
  }
}

final eventsListProvider = StateNotifierProvider<EventsListNotifier, EventsListState>((ref) {
  return EventsListNotifier(ref.watch(eventsApiProvider));
});
