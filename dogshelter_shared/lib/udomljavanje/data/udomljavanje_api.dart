import 'package:dogshelter_shared/core/api_client.dart';
import 'package:dogshelter_shared/core/paged_result.dart';
import '../domain/udomljavanje.dart';

class UdomljavanjeApi {
  UdomljavanjeApi(this._client);

  final ApiClient _client;

  Future<PagedResult<Udomljavanje>> getUdomljavanja({
    required int page,
    int pageSize = 20,
    int? korisnikId,
    int? pasId,
  }) async {
    final json = await _client.get('/api/Udomljavanje', query: {
      'page': page,
      'pageSize': pageSize,
      'korisnikId': korisnikId,
      'pasId': pasId,
    });
    return PagedResult.fromJson(
      json as Map<String, dynamic>,
      (item) => Udomljavanje.fromJson(item),
    );
  }

  Future<Udomljavanje> getUdomljavanjeById(int id) async {
    final json = await _client.get('/api/Udomljavanje/$id');
    return Udomljavanje.fromJson(json as Map<String, dynamic>);
  }
}
