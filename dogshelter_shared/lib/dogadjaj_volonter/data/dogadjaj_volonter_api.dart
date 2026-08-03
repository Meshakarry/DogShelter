import 'package:dogshelter_shared/core/api_client.dart';
import 'package:dogshelter_shared/core/paged_result.dart';
import '../domain/dogadjaj_volonter.dart';

class DogadjajVolonterApi {
  DogadjajVolonterApi(this._client);

  final ApiClient _client;

  Future<PagedResult<DogadjajVolonter>> search({
    int? dogadjajId,
    int? volonterId,
    int page = 1,
    int pageSize = 100,
  }) async {
    final json = await _client.get('/api/DogadjajVolonter', query: {
      'dogadjajId': dogadjajId,
      'volonterId': volonterId,
      'page': page,
      'pageSize': pageSize,
    });
    return PagedResult.fromJson(json as Map<String, dynamic>, (item) => DogadjajVolonter.fromJson(item));
  }

  /// Admin-only.
  Future<DogadjajVolonter> zaduzi({required int dogadjajId, required int volonterId}) async {
    final json = await _client.post('/api/DogadjajVolonter/zaduzi', body: {
      'dogadjajId': dogadjajId,
      'volonterId': volonterId,
    });
    return DogadjajVolonter.fromJson(json as Map<String, dynamic>);
  }

  /// Admin-only.
  Future<void> ukloni(int id) => _client.delete('/api/DogadjajVolonter/$id');
}
