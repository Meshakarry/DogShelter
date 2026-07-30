import 'package:dogshelter_shared/core/api_client.dart';
import 'package:dogshelter_shared/core/paged_result.dart';
import '../domain/obavijest.dart';
import '../domain/obavijest_list_item.dart';

class NewsApi {
  NewsApi(this._client);

  final ApiClient _client;

  Future<PagedResult<ObavijestListItem>> getObavijesti({
    required int page,
    int pageSize = 20,
    String? naslov,
  }) async {
    final json = await _client.get('/api/Obavijest', query: {
      'page': page,
      'pageSize': pageSize,
      'naslov': (naslov == null || naslov.isEmpty) ? null : naslov,
    });
    return PagedResult.fromJson(
      json as Map<String, dynamic>,
      (item) => ObavijestListItem.fromJson(item),
    );
  }

  Future<Obavijest> getObavijestById(int id) async {
    final json = await _client.get('/api/Obavijest/$id');
    return Obavijest.fromJson(json as Map<String, dynamic>);
  }
}
