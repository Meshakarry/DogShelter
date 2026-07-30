import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/auth_token_holder.dart';
import '../../core/secure_storage_service.dart';
import '../data/auth_api.dart';
import '../domain/auth_state.dart';
import '../domain/korisnik.dart';
import '../domain/token_response.dart';

/// Each app overrides this with its own `Environment.apiBaseUrl` in its root `ProviderScope`.
final Provider<String> apiBaseUrlProvider = Provider<String>(
  (ref) => throw UnimplementedError('apiBaseUrlProvider must be overridden by the app'),
);

final Provider<SecureStorageService> secureStorageProvider =
    Provider<SecureStorageService>((ref) => SecureStorageService());

final Provider<AuthTokenHolder> authTokenHolderProvider = Provider<AuthTokenHolder>((ref) {
  final holder = AuthTokenHolder();
  ref.onDispose(holder.dispose);
  return holder;
});

final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) {
  final holder = ref.watch(authTokenHolderProvider);
  return ApiClient(
    baseUrl: ref.watch(apiBaseUrlProvider),
    getToken: () => holder.token,
    onUnauthorized: holder.notifyUnauthorized,
  );
});

final Provider<AuthApi> authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(apiClientProvider)));

final StateNotifierProvider<AuthNotifier, AuthState> authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final holder = ref.watch(authTokenHolderProvider);
  final notifier = AuthNotifier(ref.watch(authApiProvider), ref.watch(secureStorageProvider), holder);
  final subscription = holder.onUnauthorized.listen((_) => notifier.handleUnauthorized());
  ref.onDispose(subscription.cancel);
  return notifier;
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authApi, this._storage, this._tokenHolder) : super(const AuthState.initial());

  final AuthApi _authApi;
  final SecureStorageService _storage;
  final AuthTokenHolder _tokenHolder;

  Future<void> hydrateFromStorage() async {
    final session = await _storage.readSession();
    if (session == null || session.expiresUtc.isBefore(DateTime.now())) {
      state = AuthState.loggedOut;
      return;
    }

    final korisnik = Korisnik.fromJson(jsonDecode(session.korisnikJson) as Map<String, dynamic>);
    _tokenHolder.token = session.token;
    state = AuthState(
      status: AuthStatus.loggedIn,
      token: session.token,
      expiresUtc: session.expiresUtc,
      korisnik: korisnik,
    );
  }

  Future<void> login({required String korisnickoIme, required String lozinka}) async {
    final response = await _authApi.login(korisnickoIme: korisnickoIme, lozinka: lozinka);
    await _persist(response);
  }

  Future<void> registerThenLogin({
    required String ime,
    required String prezime,
    required String email,
    String? telefon,
    required String korisnickoIme,
    required String lozinka,
    required String lozinkaPotvrda,
  }) async {
    await _authApi.register(
      ime: ime,
      prezime: prezime,
      email: email,
      telefon: telefon,
      korisnickoIme: korisnickoIme,
      lozinka: lozinka,
      lozinkaPotvrda: lozinkaPotvrda,
    );
    await login(korisnickoIme: korisnickoIme, lozinka: lozinka);
  }

  Future<void> logout() async {
    try {
      await _authApi.logout();
    } catch (_) {
      // Best-effort server-side revocation; local session is cleared regardless.
    }
    await _clearLocal();
  }

  /// Refreshes the cached Korisnik after a profile/avatar update, keeping secure storage in sync.
  Future<void> updateKorisnik(Korisnik korisnik) async {
    final token = state.token;
    final expiresUtc = state.expiresUtc;
    if (token != null && expiresUtc != null) {
      await _storage.saveSession(token: token, expiresUtc: expiresUtc, korisnikJson: jsonEncode(korisnik.toJson()));
    }
    state = state.copyWith(korisnik: korisnik);
  }

  void handleUnauthorized() {
    unawaited(_clearLocal());
  }

  Future<void> _persist(TokenResponse response) async {
    await _storage.saveSession(
      token: response.token,
      expiresUtc: response.expiresUtc,
      korisnikJson: jsonEncode(response.korisnik.toJson()),
    );
    _tokenHolder.token = response.token;
    state = AuthState(
      status: AuthStatus.loggedIn,
      token: response.token,
      expiresUtc: response.expiresUtc,
      korisnik: response.korisnik,
    );
  }

  Future<void> _clearLocal() async {
    await _storage.clear();
    _tokenHolder.token = null;
    state = AuthState.loggedOut;
  }
}
