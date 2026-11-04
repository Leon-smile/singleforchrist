import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase Auth so pages never touch the client directly.
/// Accounts are name-only: an anonymous Supabase user plus a row in `profiles`.
class AuthService {
  AuthService._();

  static SupabaseClient get _client => Supabase.instance.client;

  /// Current session (restored automatically from local storage on app start).
  static Session? get session => _client.auth.currentSession;
  static User? get user => _client.auth.currentUser;
  static bool get isSignedIn => session != null;

  /// Fires on sign in, sign out, token refresh...
  static Stream<AuthState> get changes => _client.auth.onAuthStateChange;

  /// Creates the account from just a name.
  static Future<void> signUpWithName(String name) async {
    final res = await _client.auth.signInAnonymously();
    final newUser = res.user;
    if (newUser == null) {
      throw const AuthException('Could not create the account.');
    }

    try {
      await _client.from('profiles').upsert({
        'id': newUser.id,
        'full_name': name.trim(),
      });
    } catch (e) {
      await _client.auth.signOut(); // don't leave an orphan account
      rethrow;
    }
  }

  /// Name saved for the account signed in on this device (null if none).
  static Future<String?> savedName() async {
    final u = _client.auth.currentUser;
    if (u == null) return null;
    final row = await _client
        .from('profiles')
        .select('full_name')
        .eq('id', u.id)
        .maybeSingle();
    return row?['full_name'] as String?;
  }

  static Future<void> signOut() => _client.auth.signOut();
}
