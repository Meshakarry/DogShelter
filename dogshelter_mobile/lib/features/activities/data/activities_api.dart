import '../../../core/api_client.dart';
import '../../../core/paged_result.dart';
import '../domain/aktivnost_volontera.dart';
import '../domain/tip_aktivnosti.dart';

class ActivitiesApi {
  ActivitiesApi(this._client);

  final ApiClient _client;

  Future<PagedResult<AktivnostVolontera>> getAktivnosti({required int page, int pageSize = 20}) async {
    final json = await _client.get('/api/AktivnostVolontera', query: {'page': page, 'pageSize': pageSize});
    return PagedResult.fromJson(json as Map<String, dynamic>, (item) => AktivnostVolontera.fromJson(item));
  }

  // Small lookup table, well under the server's 100-row page cap, so a single request
  // returns the full list.
  Future<List<TipAktivnosti>> getTipoviAktivnosti() async {
    final json = await _client.get('/api/TipAktivnosti', query: {'pageSize': 100});
    final result = PagedResult.fromJson(json as Map<String, dynamic>, (item) => TipAktivnosti.fromJson(item));
    return result.items;
  }

  Future<AktivnostVolontera> logAktivnost({
    required int tipAktivnostiId,
    required DateTime datumAktivnosti,
    required double brojSati,
    String? opis,
  }) async {
    final dateOnly = '${datumAktivnosti.year.toString().padLeft(4, '0')}-'
        '${datumAktivnosti.month.toString().padLeft(2, '0')}-'
        '${datumAktivnosti.day.toString().padLeft(2, '0')}';
    final json = await _client.post('/api/AktivnostVolontera', body: {
      'tipAktivnostiId': tipAktivnostiId,
      'datumAktivnosti': dateOnly,
      'brojSati': brojSati,
      'opis': (opis == null || opis.isEmpty) ? null : opis,
    });
    return AktivnostVolontera.fromJson(json as Map<String, dynamic>);
  }
}
