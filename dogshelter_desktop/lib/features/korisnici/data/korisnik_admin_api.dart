import 'package:dogshelter_shared/auth/domain/korisnik.dart';
import 'package:dogshelter_shared/core/api_client.dart';
import 'package:dogshelter_shared/core/paged_result.dart';

class KorisnikFormData {
  const KorisnikFormData({
    required this.ime,
    required this.prezime,
    required this.email,
    this.telefon,
    this.gradId,
    this.adresa,
    required this.korisnickoIme,
    this.lozinka,
    this.lozinkaPotvrda,
    this.status,
    required this.uloge,
    this.ulogeZaBrisanje = const [],
  });

  final String ime;
  final String prezime;
  final String email;
  final String? telefon;
  final int? gradId;
  final String? adresa;
  final String korisnickoIme;

  /// Only sent when set - on update, a blank password means "leave unchanged".
  final String? lozinka;
  final String? lozinkaPotvrda;

  /// Update-only reversible activate/deactivate toggle (distinct from the hard,
  /// anonymizing delete exposed via [KorisnikAdminApi.delete]).
  final bool? status;

  final List<String> uloge;
  final List<String> ulogeZaBrisanje;

  Map<String, dynamic> toJson() => {
        'ime': ime,
        'prezime': prezime,
        'email': email,
        'telefon': telefon,
        'gradId': gradId,
        'adresa': adresa,
        'korisnickoIme': korisnickoIme,
        if (lozinka != null && lozinka!.isNotEmpty) 'lozinka': lozinka,
        if (lozinkaPotvrda != null && lozinkaPotvrda!.isNotEmpty) 'lozinkaPotvrda': lozinkaPotvrda,
        if (status != null) 'status': status,
        'uloge': uloge,
        'ulogeZaBrisanje': ulogeZaBrisanje,
      };
}

class KorisnikAdminApi {
  KorisnikAdminApi(this._client);

  final ApiClient _client;

  Future<PagedResult<Korisnik>> search({
    String? korisnickoIme,
    int? ulogaId,
    bool? aktivan,
    int page = 1,
    int pageSize = 100,
  }) async {
    final json = await _client.get('/api/Korisnik', query: {
      'korisnickoIme': (korisnickoIme == null || korisnickoIme.isEmpty) ? null : korisnickoIme,
      'ulogaId': ulogaId,
      'aktivan': aktivan,
      'page': page,
      'pageSize': pageSize,
    });
    return PagedResult<Korisnik>.fromJson(json as Map<String, dynamic>, Korisnik.fromJson);
  }

  Future<Korisnik> insert(KorisnikFormData data) async {
    final json = await _client.post('/api/Korisnik', body: data.toJson());
    return Korisnik.fromJson(json as Map<String, dynamic>);
  }

  Future<Korisnik> update(int id, KorisnikFormData data) async {
    final json = await _client.put('/api/Korisnik/$id', body: data.toJson());
    return Korisnik.fromJson(json as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _client.delete('/api/Korisnik/$id');
}
