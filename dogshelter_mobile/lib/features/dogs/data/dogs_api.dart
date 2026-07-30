import 'package:dogshelter_shared/core/api_client.dart';
import 'package:dogshelter_shared/core/paged_result.dart';
import '../domain/lookups.dart';
import '../domain/pas.dart';
import '../domain/pas_list_item.dart';
import '../domain/spol.dart';

class DogsApi {
  DogsApi(this._client);

  final ApiClient _client;

  Future<PagedResult<PasListItem>> getDogs({
    required int page,
    int pageSize = 20,
    String? naziv,
    int? rasaId,
    int? statusPsaId,
    int? velicinaPsaId,
    Spol? spol,
  }) async {
    final json = await _client.get('/api/Pas', query: {
      'page': page,
      'pageSize': pageSize,
      'naziv': (naziv == null || naziv.isEmpty) ? null : naziv,
      'rasaId': rasaId,
      'statusPsaId': statusPsaId,
      'velicinaPsaId': velicinaPsaId,
      'spol': spol?.toJson(),
    });
    return PagedResult.fromJson(
      json as Map<String, dynamic>,
      (item) => PasListItem.fromJson(item),
    );
  }

  Future<Pas> getDogById(int id) async {
    final json = await _client.get('/api/Pas/$id');
    return Pas.fromJson(json as Map<String, dynamic>);
  }

  // Lookup tables are small (well under the server's 100-row page cap), so a single
  // pageSize=100 request is enough to get the full list for a dropdown - no pagination UI needed here.
  Future<List<Rasa>> getRase() async {
    final json = await _client.get('/api/Rasa', query: {'pageSize': 100});
    final result = PagedResult.fromJson(json as Map<String, dynamic>, (item) => Rasa.fromJson(item));
    return result.items;
  }

  Future<List<StatusPsa>> getStatusi() async {
    final json = await _client.get('/api/StatusPsa', query: {'pageSize': 100});
    final result = PagedResult.fromJson(json as Map<String, dynamic>, (item) => StatusPsa.fromJson(item));
    return result.items;
  }

  Future<List<VelicinaPsa>> getVelicine() async {
    final json = await _client.get('/api/VelicinaPsa', query: {'pageSize': 100});
    final result = PagedResult.fromJson(json as Map<String, dynamic>, (item) => VelicinaPsa.fromJson(item));
    return result.items;
  }
}
