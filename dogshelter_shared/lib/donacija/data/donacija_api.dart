import 'package:dogshelter_shared/core/api_client.dart';
import 'package:dogshelter_shared/core/paged_result.dart';
import '../domain/donacija.dart';
import '../domain/jedinica_mjere.dart';
import '../domain/kategorija_donacije.dart';
import '../domain/potreba_azila.dart';
import '../domain/status_donacije.dart';
import '../domain/tip_donacije.dart';

class DonacijaApi {
  DonacijaApi(this._client);

  final ApiClient _client;

  Future<PagedResult<Donacija>> getDonacije({
    required int page,
    int pageSize = 20,
    int? tipDonacijeId,
    int? statusDonacijeId,
    DateTime? datumOd,
    DateTime? datumDo,
  }) async {
    final json = await _client.get('/api/Donacija', query: {
      'page': page,
      'pageSize': pageSize,
      'tipDonacijeId': tipDonacijeId,
      'statusDonacijeId': statusDonacijeId,
      'datumOd': datumOd?.toIso8601String(),
      'datumDo': datumDo?.toIso8601String(),
    });
    return PagedResult.fromJson(
      json as Map<String, dynamic>,
      (item) => Donacija.fromJson(item),
    );
  }

  Future<Donacija> getDonacijaById(int id) async {
    final json = await _client.get('/api/Donacija/$id');
    return Donacija.fromJson(json as Map<String, dynamic>);
  }

  Future<DonacijaPaymentResponse> createDonacija({
    required int tipDonacijeId,
    double? iznos,
    String? napomena,
    int? kategorijaDonacijeId,
    String? prilagodjenNaziv,
    double? kolicina,
    int? jedinicaMjereId,
    bool trebaPreuzimanje = false,
    String? adresaPreuzimanja,
    String? telefonPreuzimanja,
    DateTime? datumPreuzimanja,
    DateTime? zeljeniDatumDostave,
  }) async {
    final json = await _client.post('/api/Donacija', body: {
      'tipDonacijeId': tipDonacijeId,
      'iznos': iznos,
      'napomena': (napomena == null || napomena.isEmpty) ? null : napomena,
      'kategorijaDonacijeId': kategorijaDonacijeId,
      'prilagodjenNaziv': (prilagodjenNaziv == null || prilagodjenNaziv.isEmpty) ? null : prilagodjenNaziv,
      'kolicina': kolicina,
      'jedinicaMjereId': jedinicaMjereId,
      'trebaPreuzimanje': trebaPreuzimanje,
      'adresaPreuzimanja': (adresaPreuzimanja == null || adresaPreuzimanja.isEmpty) ? null : adresaPreuzimanja,
      'telefonPreuzimanja': (telefonPreuzimanja == null || telefonPreuzimanja.isEmpty) ? null : telefonPreuzimanja,
      'datumPreuzimanja': datumPreuzimanja?.toIso8601String(),
      'zeljeniDatumDostave': zeljeniDatumDostave?.toIso8601String(),
    });
    return DonacijaPaymentResponse.fromJson(json as Map<String, dynamic>);
  }

  Future<DonacijaPaymentResponse> retryPlacanje(int id) async {
    final json = await _client.post('/api/Donacija/$id/retry-placanje');
    return DonacijaPaymentResponse.fromJson(json as Map<String, dynamic>);
  }

  /// Admin-only: manually confirms an in-kind (Materijalna) donation still Na čekanju - the
  /// backend rejects this for Novčana donations, which only ever resolve via Stripe.
  Future<Donacija> potvrdi(int id) async {
    final json = await _client.post('/api/Donacija/$id/potvrdi');
    return Donacija.fromJson(json as Map<String, dynamic>);
  }

  /// Admin-only: rejects an in-kind donation still Na čekanju with a required reason.
  Future<Donacija> odbij(int id, {required String razlogOdbijanja}) async {
    final json = await _client.post('/api/Donacija/$id/odbij', body: {
      'razlogOdbijanja': razlogOdbijanja,
    });
    return Donacija.fromJson(json as Map<String, dynamic>);
  }

  /// Admin-only: refunds an already-successful monetary donation with a required reason.
  Future<Donacija> refund(int id, {required String razlogVracanja}) async {
    final json = await _client.post('/api/Donacija/$id/refund', body: {
      'razlogVracanja': razlogVracanja,
    });
    return Donacija.fromJson(json as Map<String, dynamic>);
  }

  // Small lookup tables, well under the server's 100-row page cap, so a single request
  // returns the full list.
  Future<List<TipDonacije>> getTipovi() async {
    final json = await _client.get('/api/TipDonacije', query: {'pageSize': 100});
    final result = PagedResult.fromJson(json as Map<String, dynamic>, (item) => TipDonacije.fromJson(item));
    return result.items;
  }

  Future<List<StatusDonacije>> getStatusi() async {
    final json = await _client.get('/api/StatusDonacije', query: {'pageSize': 100});
    final result = PagedResult.fromJson(json as Map<String, dynamic>, (item) => StatusDonacije.fromJson(item));
    return result.items;
  }

  Future<List<KategorijaDonacije>> getKategorije() async {
    final json = await _client.get('/api/KategorijaDonacije', query: {'pageSize': 100});
    final result = PagedResult.fromJson(json as Map<String, dynamic>, (item) => KategorijaDonacije.fromJson(item));
    return result.items;
  }

  Future<List<JedinicaMjere>> getJedinice() async {
    final json = await _client.get('/api/JedinicaMjere', query: {'pageSize': 100});
    final result = PagedResult.fromJson(json as Map<String, dynamic>, (item) => JedinicaMjere.fromJson(item));
    return result.items;
  }

  /// Admin-curated "what the shelter currently needs" board - read-only for donors.
  Future<List<PotrebaAzila>> getPotrebeAzila() async {
    final json = await _client.get('/api/PotrebaAzila', query: {'pageSize': 100});
    final result = PagedResult.fromJson(json as Map<String, dynamic>, (item) => PotrebaAzila.fromJson(item));
    return result.items;
  }
}
