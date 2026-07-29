import '../../../core/api_client.dart';
import '../../../core/paged_result.dart';
import '../domain/posjeta.dart';
import '../domain/status_posjete.dart';

class VisitsApi {
  VisitsApi(this._client);

  final ApiClient _client;

  Future<PagedResult<Posjeta>> getPosjete({
    required int page,
    int pageSize = 20,
    int? statusPosjeteId,
    int? pasId,
  }) async {
    final json = await _client.get('/api/Posjeta', query: {
      'page': page,
      'pageSize': pageSize,
      'statusPosjeteId': statusPosjeteId,
      'pasId': pasId,
    });
    return PagedResult.fromJson(
      json as Map<String, dynamic>,
      (item) => Posjeta.fromJson(item),
    );
  }

  Future<Posjeta> getPosjetaById(int id) async {
    final json = await _client.get('/api/Posjeta/$id');
    return Posjeta.fromJson(json as Map<String, dynamic>);
  }

  Future<Posjeta> createPosjeta({required DateTime datumVrijeme, int? pasId, String? napomena}) async {
    final json = await _client.post('/api/Posjeta', body: {
      'datumVrijeme': datumVrijeme.toIso8601String(),
      'pasId': pasId,
      'napomena': (napomena == null || napomena.isEmpty) ? null : napomena,
    });
    return Posjeta.fromJson(json as Map<String, dynamic>);
  }

  Future<Posjeta> otkaziPosjetu(int id, {required String razlogOtkazivanja}) async {
    final json = await _client.post('/api/Posjeta/$id/otkazi', body: {
      'razlogOtkazivanja': razlogOtkazivanja,
    });
    return Posjeta.fromJson(json as Map<String, dynamic>);
  }

  // Small lookup table, well under the server's 100-row page cap, so a single request
  // returns the full list.
  Future<List<StatusPosjete>> getStatusi() async {
    final json = await _client.get('/api/StatusPosjete', query: {'pageSize': 100});
    final result = PagedResult.fromJson(json as Map<String, dynamic>, (item) => StatusPosjete.fromJson(item));
    return result.items;
  }

  /// Exact DatumVrijeme values already booked (Na čekanju/Potvrđena) on the given day -
  /// shelter-wide, not per-dog/per-user, mirroring PosjetaService.EnsureSlotAvailableAsync's own
  /// definition of "taken" so the booking sheet can grey out a slot before the user even submits.
  Future<List<DateTime>> getZauzetiTermini(DateTime datum) async {
    final dateOnly =
        '${datum.year.toString().padLeft(4, '0')}-${datum.month.toString().padLeft(2, '0')}-${datum.day.toString().padLeft(2, '0')}';
    final json = await _client.get('/api/Posjeta/zauzeti-termini', query: {'datum': dateOnly});
    return (json as List<dynamic>).map((e) => DateTime.parse(e as String)).toList();
  }
}
