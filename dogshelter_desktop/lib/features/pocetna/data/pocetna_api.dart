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

  /// Returns a rolling window of the last [mjeseci] months (current month inclusive),
  /// zero-filled for months with no adoptions, so the chart always shows the same number
  /// of bars and naturally shifts forward as the current month changes.
  Future<List<MjesecBroj>> udomljavanjeReport({int mjeseci = 7}) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - (mjeseci - 1), 1);
    final end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));
    final json = await _client.get('/api/Udomljavanje/report', query: {
      'DatumOd': start.toIso8601String(),
      'DatumDo': end.toIso8601String(),
    });
    final items = (json as Map<String, dynamic>)['poMjesecima'] as List<dynamic>;
    final poMjesecima = items.map((e) => MjesecBroj.fromJson(e as Map<String, dynamic>)).toList();
    return _zeroFillMonths(poMjesecima, start, mjeseci);
  }

  List<MjesecBroj> _zeroFillMonths(List<MjesecBroj> poMjesecima, DateTime start, int mjeseci) {
    final byKljuc = {for (final stavka in poMjesecima) '${stavka.godina}-${stavka.mjesec}': stavka};
    return [
      for (var i = 0; i < mjeseci; i++)
        _mjesecZaIndeks(start, i, byKljuc),
    ];
  }

  MjesecBroj _mjesecZaIndeks(DateTime start, int i, Map<String, MjesecBroj> byKljuc) {
    final datum = DateTime(start.year, start.month + i, 1);
    final postojeci = byKljuc['${datum.year}-${datum.month}'];
    return postojeci ??
        MjesecBroj(godina: datum.year, mjesec: datum.month, mjesecNaziv: _mjeseciNazivi[datum.month - 1], broj: 0);
  }
}

const _mjeseciNazivi = [
  'Januar',
  'Februar',
  'Mart',
  'April',
  'Maj',
  'Juni',
  'Juli',
  'August',
  'Septembar',
  'Oktobar',
  'Novembar',
  'Decembar',
];
