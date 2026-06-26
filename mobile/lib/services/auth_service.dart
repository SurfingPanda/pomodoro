import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

/// Thrown for auth failures with a human-readable [message].
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Wraps Supabase Auth. Supabase persists the session itself, so there is no
/// manual token storage here — [accessToken] returns the current JWT, which is
/// what the Laravel API expects as a Bearer token.
class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  bool get isLoggedIn => _client.auth.currentSession != null;

  /// The current Supabase JWT, or null if signed out.
  String? get accessToken => _client.auth.currentSession?.accessToken;

  /// Emits on sign-in / sign-out so the UI can react.
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  /// Register a new account. If the project requires email confirmation,
  /// [AuthResult.needsConfirmation] is true and no session is created yet.
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      return AuthResult(needsConfirmation: res.session == null);
    } on supa.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  /// Log in with email + password.
  Future<void> login({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on supa.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  Future<void> logout() => _client.auth.signOut();
}

/// Result of a registration attempt.
class AuthResult {
  /// True when the account was created but a session is pending email
  /// confirmation (the user must click the link before logging in).
  final bool needsConfirmation;
  AuthResult({required this.needsConfirmation});
}
