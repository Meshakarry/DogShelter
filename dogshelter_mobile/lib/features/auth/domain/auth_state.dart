import 'korisnik.dart';

enum AuthStatus { unknown, loggedOut, loggedIn }

class AuthState {
  const AuthState({required this.status, this.token, this.expiresUtc, this.korisnik});

  const AuthState.initial() : this(status: AuthStatus.unknown);

  final AuthStatus status;
  final String? token;
  final DateTime? expiresUtc;
  final Korisnik? korisnik;

  bool get isLoggedIn => status == AuthStatus.loggedIn && token != null;

  AuthState copyWith({
    AuthStatus? status,
    String? token,
    DateTime? expiresUtc,
    Korisnik? korisnik,
  }) {
    return AuthState(
      status: status ?? this.status,
      token: token ?? this.token,
      expiresUtc: expiresUtc ?? this.expiresUtc,
      korisnik: korisnik ?? this.korisnik,
    );
  }

  static const loggedOut = AuthState(status: AuthStatus.loggedOut);
}
