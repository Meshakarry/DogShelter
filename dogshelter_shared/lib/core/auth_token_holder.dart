import 'dart:async';

/// Plain (non-Riverpod) shared state between ApiClient and AuthNotifier.
///
/// ApiClient needs the current token and a way to react to a 401, but it must
/// not depend on authNotifierProvider directly: authNotifierProvider already
/// depends on apiClientProvider (via authApiProvider), and Riverpod's debug-mode
/// dependency check rejects a provider reading anything that transitively
/// depends back on itself, even via ref.read inside a deferred closure. Routing
/// the 401 signal through a plain Stream here (instead of ApiClient calling into
/// authNotifierProvider) keeps apiClientProvider's dependency graph a simple DAG.
class AuthTokenHolder {
  String? token;

  final _unauthorizedController = StreamController<void>.broadcast();
  Stream<void> get onUnauthorized => _unauthorizedController.stream;

  void notifyUnauthorized() => _unauthorizedController.add(null);

  void dispose() => _unauthorizedController.close();
}
