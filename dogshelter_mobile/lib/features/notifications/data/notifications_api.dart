import 'package:dogshelter_shared/core/api_client.dart';
import 'package:dogshelter_shared/core/paged_result.dart';
import '../domain/notifikacija.dart';

class NotificationsApi {
  NotificationsApi(this._client);

  final ApiClient _client;

  Future<PagedResult<Notifikacija>> getNotifikacije({
    required int page,
    int pageSize = 20,
    bool? procitano,
  }) async {
    final json = await _client.get('/api/Notifikacija', query: {
      'page': page,
      'pageSize': pageSize,
      'procitano': procitano,
    });
    return PagedResult.fromJson(
      json as Map<String, dynamic>,
      (item) => Notifikacija.fromJson(item),
    );
  }

  Future<int> getUnreadCount() async {
    final json = await _client.get('/api/Notifikacija/broj-neprocitanih');
    return json as int;
  }

  Future<void> markAsRead(int id) async {
    await _client.post('/api/Notifikacija/$id/procitaj');
  }

  Future<void> markAllAsRead() async {
    await _client.post('/api/Notifikacija/procitaj-sve');
  }
}
