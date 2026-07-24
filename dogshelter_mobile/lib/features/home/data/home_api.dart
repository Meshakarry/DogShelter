import '../../../core/api_client.dart';
import '../../../core/api_exception.dart';
import '../domain/obavijest_preview.dart';
import '../domain/volonter_summary.dart';

/// Interim data source for the home dashboard - pulls just enough from Obavijest/Volonter/
/// AktivnostVolontera to preview on Početna. Once the full Obavijesti (Increment 5) and
/// volunteer activity log (Increment 6) features are built, prefer reusing their repositories
/// here instead of this hand-rolled one, to avoid two copies of the same fetch logic.
class HomeApi {
  HomeApi(this._client);

  final ApiClient _client;

  Future<List<ObavijestPreview>> getLatestObavijesti({int count = 3}) async {
    final json = await _client.get('/api/Obavijest', query: {'page': 1, 'pageSize': count});
    final items = (json as Map<String, dynamic>)['items'] as List<dynamic>;
    return items.map((e) => ObavijestPreview.fromJson(e as Map<String, dynamic>)).toList();
  }

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
