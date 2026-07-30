import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:dogshelter_shared/auth/domain/korisnik.dart';
import 'package:dogshelter_shared/core/api_client.dart';

class ProfileApi {
  ProfileApi(this._client);

  final ApiClient _client;

  Future<Korisnik> updateProfile({
    required String ime,
    required String prezime,
    required String email,
    String? telefon,
    required String korisnickoIme,
  }) async {
    final json = await _client.put('/api/Korisnik/profile', body: {
      'ime': ime,
      'prezime': prezime,
      'email': email,
      'telefon': telefon,
      'korisnickoIme': korisnickoIme,
    });
    return Korisnik.fromJson(json as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String staraLozinka,
    required String novaLozinka,
    required String novaLozinkaPotvrda,
  }) async {
    await _client.put('/api/Korisnik/password', body: {
      'staraLozinka': staraLozinka,
      'novaLozinka': novaLozinka,
      'novaLozinkaPotvrda': novaLozinkaPotvrda,
    });
  }

  Future<Korisnik> updateAvatar(XFile file) async {
    final json = await _client.multipart(
      'POST',
      '/api/Korisnik/avatar',
      files: [await http.MultipartFile.fromPath('slika', file.path)],
    );
    return Korisnik.fromJson(json as Map<String, dynamic>);
  }
}
