import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_notifier.dart';
import '../data/notifications_api.dart';
import '../domain/notifikacija.dart';

final notificationsApiProvider = Provider<NotificationsApi>((ref) => NotificationsApi(ref.watch(apiClientProvider)));

class NotifikacijaListState {
  const NotifikacijaListState({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoading = false,
    this.error,
    this.onlyUnread = false,
  });

  final List<Notifikacija> items;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final Object? error;
  final bool onlyUnread;

  NotifikacijaListState copyWith({
    List<Notifikacija>? items,
    int? page,
    bool? hasMore,
    bool? isLoading,
    Object? error,
    bool clearError = false,
    bool? onlyUnread,
  }) {
    return NotifikacijaListState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      onlyUnread: onlyUnread ?? this.onlyUnread,
    );
  }
}

class NotifikacijaListNotifier extends StateNotifier<NotifikacijaListState> {
  NotifikacijaListNotifier(this._api, this._ref) : super(const NotifikacijaListState()) {
    loadFirstPage();
  }

  final NotificationsApi _api;
  final Ref _ref;
  static const _pageSize = 20;

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _api.getNotifikacije(
        page: 1,
        pageSize: _pageSize,
        procitano: state.onlyUnread ? false : null,
      );
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
      final result = await _api.getNotifikacije(
        page: nextPage,
        pageSize: _pageSize,
        procitano: state.onlyUnread ? false : null,
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

  Future<void> applyUnreadFilter(bool onlyUnread) async {
    state = state.copyWith(onlyUnread: onlyUnread, items: [], page: 1, hasMore: true);
    await loadFirstPage();
  }

  Future<void> markAsRead(int id) async {
    final target = state.items.where((n) => n.notifikacijaId == id).firstOrNull;
    if (target == null || target.procitano) return;

    await _api.markAsRead(id);
    state = state.copyWith(
      items: [
        for (final n in state.items)
          if (n.notifikacijaId == id) n.copyWith(procitano: true) else n,
      ],
    );
    _ref.read(unreadNotificationCountProvider.notifier).decrementBy(1);
  }

  Future<void> markAllAsRead() async {
    await _api.markAllAsRead();
    state = state.copyWith(items: [for (final n in state.items) n.copyWith(procitano: true)]);
    _ref.read(unreadNotificationCountProvider.notifier).reset();
  }
}

final notifikacijaListProvider = StateNotifierProvider<NotifikacijaListNotifier, NotifikacijaListState>((ref) {
  return NotifikacijaListNotifier(ref.watch(notificationsApiProvider), ref);
});

/// Polls the unread count every 30s (matching the reference repo's Timer.periodic pattern, see
/// phase8-notifications-design memory) so the app-bar badge stays fresh without the user having
/// to open the notifications list. Only polls while logged in - `.select` means this provider
/// (and its timer) is only rebuilt when isLoggedIn actually flips, not on every token refresh.
class UnreadCountNotifier extends StateNotifier<AsyncValue<int>> {
  UnreadCountNotifier(this._api, {required bool isLoggedIn}) : super(const AsyncValue.data(0)) {
    if (isLoggedIn) {
      _refresh();
      _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
    }
  }

  final NotificationsApi _api;
  Timer? _timer;

  Future<void> _refresh() async {
    try {
      final count = await _api.getUnreadCount();
      if (mounted) state = AsyncValue.data(count);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> refreshNow() => _refresh();

  void decrementBy(int amount) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data((current - amount).clamp(0, current));
  }

  void reset() => state = const AsyncValue.data(0);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final unreadNotificationCountProvider = StateNotifierProvider<UnreadCountNotifier, AsyncValue<int>>((ref) {
  final isLoggedIn = ref.watch(authNotifierProvider.select((s) => s.isLoggedIn));
  return UnreadCountNotifier(ref.watch(notificationsApiProvider), isLoggedIn: isLoggedIn);
});
