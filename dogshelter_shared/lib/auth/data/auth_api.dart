import '../../core/api_client.dart';
import '../domain/korisnik.dart';
import '../domain/token_response.dart';

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<TokenResponse> login({required String korisnickoIme, required String lozinka}) async {
    final json = await _client.post('/api/Korisnik/Token', body: {
      'korisnickoIme': korisnickoIme,
      'lozinka': lozinka,
    });
    return TokenResponse.fromJson(json as Map<String, dynamic>);
  }

  Future<Korisnik> register({
    required String ime,
    required String prezime,
    required String email,
    String? telefon,
    required String korisnickoIme,
    required String lozinka,
    required String lozinkaPotvrda,
  }) async {
    final json = await _client.post('/api/Korisnik/Register', body: {
      'ime': ime,
      'prezime': prezime,
      'email': email,
      'telefon': telefon,
      'korisnickoIme': korisnickoIme,
      'lozinka': lozinka,
      'lozinkaPotvrda': lozinkaPotvrda,
    });
    return Korisnik.fromJson(json as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _client.post('/api/Korisnik/logout');
  }

  Future<String> requestPasswordReset({required String email}) async {
    final json = await _client.post('/api/PasswordReset/request', body: {'email': email});
    return (json as Map<String, dynamic>)['message'] as String;
  }

  Future<String> resetPassword({
    required String email,
    required String kod,
    required String novaLozinka,
    required String novaLozinkaPotvrda,
  }) async {
    final json = await _client.post('/api/PasswordReset/reset', body: {
      'email': email,
      'kod': kod,
      'novaLozinka': novaLozinka,
      'novaLozinkaPotvrda': novaLozinkaPotvrda,
    });
    return (json as Map<String, dynamic>)['message'] as String;
  }
}
