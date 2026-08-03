import 'package:dogshelter_shared/core/api_client.dart';
import 'package:dogshelter_shared/core/paged_result.dart';
import '../domain/aktivnost_volontera.dart';
import '../domain/tip_aktivnosti.dart';

class AktivnostVolonteraApi {
  AktivnostVolonteraApi(this._client);

  final ApiClient _client;

  Future<PagedResult<AktivnostVolontera>> getAktivnosti({
    required int page,
    int pageSize = 20,
    int? volonterId,
  }) async {
    final json = await _client
        .get('/api/AktivnostVolontera', query: {'page': page, 'pageSize': pageSize, 'volonterId': volonterId});
    return PagedResult.fromJson(json as Map<String, dynamic>, (item) => AktivnostVolontera.fromJson(item));
  }

  // Small lookup table, well under the server's 100-row page cap, so a single request
  // returns the full list.
  Future<List<TipAktivnosti>> getTipoviAktivnosti() async {
    final json = await _client.get('/api/TipAktivnosti', query: {'pageSize': 100});
    final result = PagedResult.fromJson(json as Map<String, dynamic>, (item) => TipAktivnosti.fromJson(item));
    return result.items;
  }

  /// [volonterId] is only honored server-side when the caller is Admin - a Volonter caller is
  /// always scoped to their own record regardless of what's sent here.
  Future<AktivnostVolontera> logAktivnost({
    int? volonterId,
    required int tipAktivnostiId,
    required DateTime datumAktivnosti,
    required double brojSati,
    String? opis,
  }) async {
    final dateOnly = '${datumAktivnosti.year.toString().padLeft(4, '0')}-'
        '${datumAktivnosti.month.toString().padLeft(2, '0')}-'
        '${datumAktivnosti.day.toString().padLeft(2, '0')}';
    final json = await _client.post('/api/AktivnostVolontera', body: {
      'volonterId': volonterId,
      'tipAktivnostiId': tipAktivnostiId,
      'datumAktivnosti': dateOnly,
      'brojSati': brojSati,
      'opis': (opis == null || opis.isEmpty) ? null : opis,
    });
    return AktivnostVolontera.fromJson(json as Map<String, dynamic>);
  }

  /// Admin-only.
  Future<void> delete(int id) => _client.delete('/api/AktivnostVolontera/$id');
}
