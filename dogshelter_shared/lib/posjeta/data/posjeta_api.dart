import 'package:dogshelter_shared/core/api_client.dart';
import 'package:dogshelter_shared/core/paged_result.dart';
import '../domain/posjeta.dart';
import '../domain/status_posjete.dart';

class PosjetaApi {
  PosjetaApi(this._client);

  final ApiClient _client;

  Future<PagedResult<Posjeta>> getPosjete({
    required int page,
    int pageSize = 20,
    int? statusPosjeteId,
    int? pasId,
    int? korisnikId,
    DateTime? datumOd,
    DateTime? datumDo,
  }) async {
    final json = await _client.get('/api/Posjeta', query: {
      'page': page,
      'pageSize': pageSize,
      'statusPosjeteId': statusPosjeteId,
      'pasId': pasId,
      'korisnikId': korisnikId,
      'datumOd': datumOd?.toIso8601String(),
      'datumDo': datumDo?.toIso8601String(),
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

  /// Admin-only walk-in booking - lands directly in Potvrđena (skips Na čekanju) and is
  /// stamped as processed by the calling admin immediately.
  Future<Posjeta> insertAdmin({
    required int korisnikId,
    required DateTime datumVrijeme,
    int? pasId,
    String? napomena,
  }) async {
    final json = await _client.post('/api/Posjeta/admin', body: {
      'korisnikId': korisnikId,
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

  /// Admin-only: Na čekanju -> Potvrđena.
  Future<Posjeta> potvrdi(int id) async {
    final json = await _client.post('/api/Posjeta/$id/potvrdi');
    return Posjeta.fromJson(json as Map<String, dynamic>);
  }

  /// Admin-only: Potvrđena -> Završena.
  Future<Posjeta> zavrsi(int id) async {
    final json = await _client.post('/api/Posjeta/$id/zavrsi');
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
