import 'package:dogshelter_shared/core/api_client.dart';
import 'package:dogshelter_shared/core/paged_result.dart';
import '../domain/lookup_item.dart';

class LookupApi {
  LookupApi(this._client, this._config);

  final ApiClient _client;
  final LookupTableConfig _config;

  Future<PagedResult<LookupItem>> search({String? naziv}) async {
    final json = await _client.get(_config.path, query: {
      if (naziv != null && naziv.isNotEmpty) 'Naziv': naziv,
      'Page': 1,
      'PageSize': 100,
    });
    return PagedResult<LookupItem>.fromJson(
      json as Map<String, dynamic>,
      (item) => LookupItem.fromJson(item, _config.idKey),
    );
  }

  Future<LookupItem> create(String naziv) async {
    final json = await _client.post(_config.path, body: {'naziv': naziv});
    return LookupItem.fromJson(json as Map<String, dynamic>, _config.idKey);
  }

  Future<LookupItem> update(int id, String naziv) async {
    final json = await _client.put('${_config.path}/$id', body: {'naziv': naziv});
    return LookupItem.fromJson(json as Map<String, dynamic>, _config.idKey);
  }

  Future<void> delete(int id) async {
    await _client.delete('${_config.path}/$id');
  }
}
