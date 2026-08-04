import 'package:dogshelter_shared/core/api_client.dart';
import '../domain/preporuceni_pas.dart';

class PreporukeApi {
  PreporukeApi(this._client);

  final ApiClient _client;

  Future<List<PreporuceniPas>> getPreporuceniPsi({int take = 5}) async {
    final json = await _client.get('/api/Preporuka/psi', query: {'take': take});
    return (json as List).map((item) => PreporuceniPas.fromJson(item as Map<String, dynamic>)).toList();
  }
}
