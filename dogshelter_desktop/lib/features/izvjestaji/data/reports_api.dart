import 'package:dogshelter_shared/core/api_client.dart';
import '../domain/report_models.dart';

class ReportsApi {
  ReportsApi(this._client);

  final ApiClient _client;

  Future<UdomljavanjeIzvjestaj> getUdomljavanjeReport({DateTime? datumOd, DateTime? datumDo}) async {
    final json = await _client.get('/api/Udomljavanje/report', query: _dateQuery(datumOd, datumDo));
    return UdomljavanjeIzvjestaj.fromJson(json as Map<String, dynamic>);
  }

  Future<AktivnostVolonteraIzvjestaj> getAktivnostVolonteraReport({DateTime? datumOd, DateTime? datumDo}) async {
    final json = await _client.get('/api/AktivnostVolontera/report', query: _dateQuery(datumOd, datumDo));
    return AktivnostVolonteraIzvjestaj.fromJson(json as Map<String, dynamic>);
  }

  Future<DonacijaIzvjestaj> getDonacijaReport({DateTime? datumOd, DateTime? datumDo}) async {
    final json = await _client.get('/api/Donacija/report', query: _dateQuery(datumOd, datumDo));
    return DonacijaIzvjestaj.fromJson(json as Map<String, dynamic>);
  }

  Map<String, dynamic> _dateQuery(DateTime? datumOd, DateTime? datumDo) => {
        if (datumOd != null) 'DatumOd': datumOd.toIso8601String(),
        if (datumDo != null) 'DatumDo': datumDo.toIso8601String(),
      };
}
