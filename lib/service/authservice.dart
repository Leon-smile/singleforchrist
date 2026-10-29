import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase Auth so pages never touch the client directly.
class AuthService {
  AuthService._();

  static SupabaseClient get _client => Supabase.instance.client;

  /// Current session (restored automatically from local storage on app start).
  static Session? get session => _client.auth.currentSession;
  static User? get user => _client.auth.currentUser;
  static bool get isSignedIn => session != null;

  /// Fires on sign in, sign out, token refresh, password recovery...
  static Stream<AuthState> get changes => _client.auth.onAuthStateChange;

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<AuthResponse> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': name.trim()}, // saved in user metadata
    );
  }

  static Future<void> resetPassword(String email) {
    return _client.auth.resetPasswordForEmail(email.trim());
  }

  static Future<void> signOut() => _client.auth.signOut();
}
