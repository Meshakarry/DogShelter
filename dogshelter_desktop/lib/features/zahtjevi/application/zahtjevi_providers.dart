import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import 'package:dogshelter_shared/core/paged_result.dart';
import 'package:dogshelter_shared/zahtjev_za_udomljavanje/data/zahtjev_za_udomljavanje_api.dart';
import 'package:dogshelter_shared/zahtjev_za_udomljavanje/domain/zahtjev_za_udomljavanje.dart';
import '../../../core/paged_list_notifier.dart';
import '../../postavke/data/lookup_api.dart';
import '../../postavke/domain/lookup_item.dart';

const statusZahtjevaConfig =
    LookupTableConfig(path: '/api/StatusZahtjeva', idKey: 'statusZahtjevaId', label: 'status zahtjeva');

final zahtjevZaUdomljavanjeApiProvider =
    Provider<ZahtjevZaUdomljavanjeApi>((ref) => ZahtjevZaUdomljavanjeApi(ref.watch(apiClientProvider)));

/// Reuses the desktop's generic LookupApi (same as Postavke/Psi) instead of the shared
/// API class's own getStatusi(), which exists only for mobile's continued use.
final statusZahtjevaOptionsProvider = FutureProvider.autoDispose<List<LookupItem>>((ref) async {
  final api = LookupApi(ref.watch(apiClientProvider), statusZahtjevaConfig);
  return (await api.search()).items;
});

class ZahtjevListNotifier extends PagedListNotifier<ZahtjevZaUdomljavanje> {
  ZahtjevListNotifier(this._api);

  final ZahtjevZaUdomljavanjeApi _api;
  int? _statusZahtjevaId;

  int? get statusZahtjevaId => _statusZahtjevaId;

  @override
  Future<PagedResult<ZahtjevZaUdomljavanje>> fetch({String? query, required int page}) =>
      _api.getZahtjevi(page: page, statusZahtjevaId: _statusZahtjevaId);

  Future<void> filterByStatus(int? statusZahtjevaId) async {
    _statusZahtjevaId = statusZahtjevaId;
    await resetAndReload();
  }

  Future<void> odobri(int id) async {
    await _api.odobri(id);
    await refresh();
  }

  Future<void> odbij(int id, String razlogOdbijanja) async {
    await _api.odbij(id, razlogOdbijanja: razlogOdbijanja);
    await refresh();
  }

  Future<void> otkazi(int id, String razlogOtkazivanja) async {
    await _api.otkazi(id, razlogOtkazivanja: razlogOtkazivanja);
    await refresh();
  }
}

final zahtjevListProvider =
    StateNotifierProvider<ZahtjevListNotifier, AsyncValue<PagedResult<ZahtjevZaUdomljavanje>>>((ref) {
  return ZahtjevListNotifier(ref.watch(zahtjevZaUdomljavanjeApiProvider));
});

/// Backs the dedicated /zahtjevi/:id detail page. autoDispose + invalidated after odobri/odbij
/// from that page so the detail re-fetches instead of showing stale status.
final zahtjevDetailProvider = FutureProvider.autoDispose.family<ZahtjevZaUdomljavanje, int>((ref, id) {
  return ref.watch(zahtjevZaUdomljavanjeApiProvider).getZahtjevById(id);
});
