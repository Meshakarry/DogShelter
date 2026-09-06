import 'package:dogshelter_shared/core/api_client.dart';
import '../domain/favorit.dart';

class FavoritApi {
  FavoritApi(this._client);

  final ApiClient _client;

  Future<List<Favorit>> getMine() async {
    final json = await _client.get('/api/Favorit/mine');
    return (json as List<dynamic>)
        .map((e) => Favorit.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Favorit> add(int pasId) async {
    final json = await _client.post('/api/Favorit', body: {'pasId': pasId});
    return Favorit.fromJson(json as Map<String, dynamic>);
  }

  Future<void> remove(int pasId) => _client.delete('/api/Favorit/$pasId');
}
