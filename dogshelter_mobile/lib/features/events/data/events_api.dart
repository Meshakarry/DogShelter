import '../../../core/api_client.dart';
import '../../../core/paged_result.dart';
import '../domain/dogadjaj.dart';

class EventsApi {
  EventsApi(this._client);

  final ApiClient _client;

  Future<PagedResult<Dogadjaj>> getDogadjaji({
    required int page,
    int pageSize = 20,
    DateTime? datumOd,
    DateTime? datumDo,
  }) async {
    final json = await _client.get('/api/Dogadjaj', query: {
      'page': page,
      'pageSize': pageSize,
      'datumOd': datumOd?.toIso8601String(),
      'datumDo': datumDo?.toIso8601String(),
    });
    return PagedResult.fromJson(json as Map<String, dynamic>, (item) => Dogadjaj.fromJson(item));
  }

  Future<Dogadjaj> getDogadjajById(int id) async {
    final json = await _client.get('/api/Dogadjaj/$id');
    return Dogadjaj.fromJson(json as Map<String, dynamic>);
  }

  /// Whether the current volunteer is assigned ("zadužen") to the given event - the backend
  /// auto-scopes GET /api/DogadjajVolonter to the caller's own VolonterId for non-admins, so a
  /// non-empty result for this dogadjajId means "yes, I'm assigned".
  Future<bool> isZaduzen(int dogadjajId) async {
    final json = await _client.get('/api/DogadjajVolonter', query: {
      'dogadjajId': dogadjajId,
      'page': 1,
      'pageSize': 1,
    });
    return ((json as Map<String, dynamic>)['totalCount'] as int) > 0;
  }
}
