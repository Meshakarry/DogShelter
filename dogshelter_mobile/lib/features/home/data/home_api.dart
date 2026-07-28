import '../../../core/api_client.dart';
import '../../../core/api_exception.dart';
import '../domain/volonter_summary.dart';

/// Interim data source for the home dashboard - pulls just enough from Volonter/
/// AktivnostVolontera to preview on Početna. Once the volunteer activity log (Increment 6)
/// feature is built, prefer reusing its repository here instead of this hand-rolled one,
/// to avoid two copies of the same fetch logic. (The Obavijesti preview above used to live
/// here too - it now reuses NewsApi from the news feature directly, see home_providers.dart.)
class HomeApi {
  HomeApi(this._client);

  final ApiClient _client;

  /// Null if the current user has no Volonter profile (backend 404s in that case).
  Future<VolonterSummary?> getMyVolonterProfile() async {
    try {
      final json = await _client.get('/api/Volonter/me');
      return VolonterSummary.fromJson(json as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// pageSize=1 - only the PagedResult.totalCount is needed, not the actual rows.
  Future<int> getMyActivityCount() async {
    final json = await _client.get('/api/AktivnostVolontera', query: {'page': 1, 'pageSize': 1});
    return (json as Map<String, dynamic>)['totalCount'] as int;
  }
}
