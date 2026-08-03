import 'package:dogshelter_shared/core/api_client.dart';
import 'package:dogshelter_shared/core/api_exception.dart';
import 'package:dogshelter_shared/core/paged_result.dart';
import '../domain/volonter.dart';

class VolonterApi {
  VolonterApi(this._client);

  final ApiClient _client;

  /// Null if the current user has no Volonter profile (backend 404s in that case).
  Future<Volonter?> getMe() async {
    try {
      final json = await _client.get('/api/Volonter/me');
      return Volonter.fromJson(json as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Admin-only.
  Future<PagedResult<Volonter>> search({
    String? ime,
    bool? aktivan,
    int page = 1,
    int pageSize = 100,
  }) async {
    final json = await _client.get('/api/Volonter', query: {
      'ime': (ime == null || ime.isEmpty) ? null : ime,
      'aktivan': aktivan,
      'page': page,
      'pageSize': pageSize,
    });
    return PagedResult.fromJson(json as Map<String, dynamic>, (item) => Volonter.fromJson(item));
  }

  Future<Volonter> getById(int id) async {
    final json = await _client.get('/api/Volonter/$id');
    return Volonter.fromJson(json as Map<String, dynamic>);
  }

  /// Admin-only. [korisnikId] must belong to an existing Korisnik not already a Volonter.
  Future<Volonter> insert({required int korisnikId, required DateTime datumPridruzivanja, String? napomena}) async {
    final dateOnly = '${datumPridruzivanja.year.toString().padLeft(4, '0')}-'
        '${datumPridruzivanja.month.toString().padLeft(2, '0')}-'
        '${datumPridruzivanja.day.toString().padLeft(2, '0')}';
    final json = await _client.post('/api/Volonter', body: {
      'korisnikId': korisnikId,
      'datumPridruzivanja': dateOnly,
      'napomena': (napomena == null || napomena.isEmpty) ? null : napomena,
    });
    return Volonter.fromJson(json as Map<String, dynamic>);
  }

  /// Admin-only.
  Future<Volonter> update(int id, {required bool aktivan, String? napomena}) async {
    final json = await _client.put('/api/Volonter/$id', body: {
      'aktivan': aktivan,
      'napomena': (napomena == null || napomena.isEmpty) ? null : napomena,
    });
    return Volonter.fromJson(json as Map<String, dynamic>);
  }
}
