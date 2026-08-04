import 'package:dogshelter_shared/core/api_client.dart';
import '../domain/pocetna_dashboard_data.dart';

class PocetnaApi {
  PocetnaApi(this._client);

  final ApiClient _client;

  Future<int> countPas({int? statusPsaId}) async {
    final json = await _client.get('/api/Pas', query: {
      if (statusPsaId != null) 'StatusPsaId': statusPsaId,
      'Page': 1,
      'PageSize': 1,
    });
    return (json as Map<String, dynamic>)['totalCount'] as int;
  }

  Future<int> countZahtjevi({int? statusZahtjevaId}) async {
    final json = await _client.get('/api/ZahtjevZaUdomljavanje', query: {
      if (statusZahtjevaId != null) 'StatusZahtjevaId': statusZahtjevaId,
      'Page': 1,
      'PageSize': 1,
    });
    return (json as Map<String, dynamic>)['totalCount'] as int;
  }

  Future<int> countPosjeteToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
    final json = await _client.get('/api/Posjeta', query: {
      'DatumOd': startOfDay.toIso8601String(),
      'DatumDo': endOfDay.toIso8601String(),
      'Page': 1,
      'PageSize': 1,
    });
    return (json as Map<String, dynamic>)['totalCount'] as int;
  }

  Future<List<ZahtjevSummary>> recentZahtjevi({int count = 5}) async {
    final json = await _client.get('/api/ZahtjevZaUdomljavanje', query: {'Page': 1, 'PageSize': count});
    final items = (json as Map<String, dynamic>)['items'] as List<dynamic>;
    return items.map((e) => ZahtjevSummary.fromJson(e as Map<String, dynamic>)).toList();
  }
}
