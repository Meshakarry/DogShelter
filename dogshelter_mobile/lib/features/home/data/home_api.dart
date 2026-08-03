import 'package:dogshelter_shared/core/api_client.dart';
import 'package:dogshelter_shared/volonter/data/volonter_api.dart';
import 'package:dogshelter_shared/volonter/domain/volonter.dart';

/// Data source for the home dashboard - pulls just enough from Volonter/AktivnostVolontera to
/// preview on Početna.
class HomeApi {
  HomeApi(this._client);

  final ApiClient _client;

  /// Null if the current user has no Volonter profile (backend 404s in that case).
  Future<Volonter?> getMyVolonterProfile() => VolonterApi(_client).getMe();

  /// pageSize=1 - only the PagedResult.totalCount is needed, not the actual rows.
  Future<int> getMyActivityCount() async {
    final json = await _client.get('/api/AktivnostVolontera', query: {'page': 1, 'pageSize': 1});
    return (json as Map<String, dynamic>)['totalCount'] as int;
  }
}
