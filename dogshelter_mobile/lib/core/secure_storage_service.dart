import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';
  static const _expiresUtcKey = 'auth_expires_utc';
  static const _korisnikJsonKey = 'auth_korisnik_json';

  Future<void> saveSession({
    required String token,
    required DateTime expiresUtc,
    required String korisnikJson,
  }) async {
    await Future.wait([
      _storage.write(key: _tokenKey, value: token),
      _storage.write(key: _expiresUtcKey, value: expiresUtc.toIso8601String()),
      _storage.write(key: _korisnikJsonKey, value: korisnikJson),
    ]);
  }

  Future<({String token, DateTime expiresUtc, String korisnikJson})?> readSession() async {
    final values = await Future.wait([
      _storage.read(key: _tokenKey),
      _storage.read(key: _expiresUtcKey),
      _storage.read(key: _korisnikJsonKey),
    ]);

    final token = values[0];
    final expiresUtcRaw = values[1];
    final korisnikJson = values[2];

    if (token == null || expiresUtcRaw == null || korisnikJson == null) return null;

    final expiresUtc = DateTime.tryParse(expiresUtcRaw);
    if (expiresUtc == null) return null;

    return (token: token, expiresUtc: expiresUtc, korisnikJson: korisnikJson);
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _expiresUtcKey),
      _storage.delete(key: _korisnikJsonKey),
    ]);
  }
}
