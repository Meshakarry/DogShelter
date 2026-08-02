import 'package:dogshelter_shared/core/api_client.dart';
import 'package:dogshelter_shared/core/paged_result.dart';
import '../domain/status_zahtjeva.dart';
import '../domain/zahtjev_za_udomljavanje.dart';

class ZahtjevZaUdomljavanjeApi {
  ZahtjevZaUdomljavanjeApi(this._client);

  final ApiClient _client;

  Future<PagedResult<ZahtjevZaUdomljavanje>> getZahtjevi({
    required int page,
    int pageSize = 20,
    int? statusZahtjevaId,
    int? pasId,
    int? korisnikId,
  }) async {
    final json = await _client.get('/api/ZahtjevZaUdomljavanje', query: {
      'page': page,
      'pageSize': pageSize,
      'statusZahtjevaId': statusZahtjevaId,
      'pasId': pasId,
      'korisnikId': korisnikId,
    });
    return PagedResult.fromJson(
      json as Map<String, dynamic>,
      (item) => ZahtjevZaUdomljavanje.fromJson(item),
    );
  }

  Future<ZahtjevZaUdomljavanje> getZahtjevById(int id) async {
    final json = await _client.get('/api/ZahtjevZaUdomljavanje/$id');
    return ZahtjevZaUdomljavanje.fromJson(json as Map<String, dynamic>);
  }

  Future<ZahtjevZaUdomljavanje> createZahtjev({required int pasId, String? napomena}) async {
    final json = await _client.post('/api/ZahtjevZaUdomljavanje', body: {
      'pasId': pasId,
      'napomena': (napomena == null || napomena.isEmpty) ? null : napomena,
    });
    return ZahtjevZaUdomljavanje.fromJson(json as Map<String, dynamic>);
  }

  /// Admin-only: flips the request to Odobren, the dog to Udomljen, and creates the
  /// resulting Udomljavanje row - all server-side, atomically.
  Future<ZahtjevZaUdomljavanje> odobri(int id) async {
    final json = await _client.post('/api/ZahtjevZaUdomljavanje/$id/odobri');
    return ZahtjevZaUdomljavanje.fromJson(json as Map<String, dynamic>);
  }

  /// Admin-only: flips the request to Odbijen with a required reason.
  Future<ZahtjevZaUdomljavanje> odbij(int id, {required String razlogOdbijanja}) async {
    final json = await _client.post('/api/ZahtjevZaUdomljavanje/$id/odbij', body: {
      'razlogOdbijanja': razlogOdbijanja,
    });
    return ZahtjevZaUdomljavanje.fromJson(json as Map<String, dynamic>);
  }

  // Small lookup table, well under the server's 100-row page cap, so a single request
  // returns the full list.
  Future<List<StatusZahtjeva>> getStatusi() async {
    final json = await _client.get('/api/StatusZahtjeva', query: {'pageSize': 100});
    final result = PagedResult.fromJson(json as Map<String, dynamic>, (item) => StatusZahtjeva.fromJson(item));
    return result.items;
  }
}
