import 'korisnik.dart';

class TokenResponse {
  TokenResponse({required this.token, required this.expiresUtc, required this.korisnik});

  final String token;
  final DateTime expiresUtc;
  final Korisnik korisnik;

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      token: json['token'] as String,
      expiresUtc: DateTime.parse(json['expiresUtc'] as String),
      korisnik: Korisnik.fromJson(json['korisnik'] as Map<String, dynamic>),
    );
  }
}
