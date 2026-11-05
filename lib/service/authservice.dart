import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart'
    show MissingPluginException, PlatformException;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thrown when the chosen name already belongs to another account.
class NameTakenException implements Exception {
  final String message;
  const NameTakenException([
    this.message = 'That name is already taken. Please choose another.',
  ]);

  @override
  String toString() => message;
}

/// Thin wrapper around Supabase Auth so pages never touch the client directly.
///
/// Two ways to get an account:
///  * name only  -> anonymous Supabase user + a `profiles` row (unique name)
///  * Google     -> real Supabase user, works on any device
class AuthService {
  AuthService._();

  static SupabaseClient get _client => Supabase.instance.client;

  /// Where Google sends the user back to on phones. Must match the Android /
  /// iOS setup and the redirect URL added in the Supabase dashboard.
  /// (Only used by the browser sign-in. The phone popup does not need it.)
  static const mobileRedirect =
      'https://gmukhkhkldbzivuhqzdd.supabase.co/auth/v1/callback';

  /// The *Web application* OAuth client ID from Google Cloud (the same one
  /// you pasted into Supabase > Authentication > Google).
  static const googleWebClientId =
      '1088965435374-afirgoru8mmdnqhfuctpl4vruebkg1o8.apps.googleusercontent.com';

  /// Only needed for iPhone builds (the iOS OAuth client ID). Leave empty on
  /// Android-only apps.
  static const googleIosClientId = '';

  /// Current session (restored automatically from local storage on app start).
  static Session? get session => _client.auth.currentSession;
  static User? get user => _client.auth.currentUser;
  static bool get isSignedIn => session != null;

  /// Fires on sign in, sign out, token refresh...
  static Stream<AuthState> get changes => _client.auth.onAuthStateChange;

  // ------------------------------------------------------------------ Google

  static bool _isGoogle(User? u) => u?.appMetadata['provider'] == 'google';

  /// True when the signed-in user came in through Google.
  static bool get isGoogleUser => _isGoogle(_client.auth.currentUser);

  /// Phones use Google's own account picker (the "Choose an account" popup).
  /// The web and desktop fall back to the browser sign-in page.
  static bool get _useNativeGoogle =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Signs in with Google.
  ///  * Android / iOS: shows the "Choose an account" popup, then hands
  ///    Google's ID token to Supabase.
  ///  * Web / desktop: opens Google's sign-in page in the browser.
  /// The result arrives through [changes] (event `signedIn`).
  static Future<void> signInWithGoogle() async {
    if (!_useNativeGoogle) {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? Uri.base.origin : mobileRedirect,
      );
      return;
    }

    try {
      final google = GoogleSignIn(
        serverClientId: googleWebClientId,
        clientId:
            defaultTargetPlatform == TargetPlatform.iOS &&
                googleIosClientId.isNotEmpty
            ? googleIosClientId
            : null,
      );

      // Forget the last choice so the account popup always appears.
      await google.signOut();

      final account = await google.signIn(); // <- the account popup
      if (account == null) return; // the user closed the popup

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        throw const AuthException('Google did not return an ID token.');
      }

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: auth.accessToken,
      );
    } on MissingPluginException {
      throw const AuthException(
        'The Google plugin is not loaded. Stop the app completely and run '
        'it again (hot reload is not enough).',
      );
    } on PlatformException catch (e) {
      final text = '${e.code} ${e.message} ${e.details}';
      if (text.contains('sign_in_canceled') || text.contains(': 12501')) {
        return; // the user closed the popup
      }
      if (text.contains('ApiException: 10')) {
        throw const AuthException(
          'Google setup does not match this app (error 10). Check the '
          'Android OAuth client in Google Cloud: package name '
          'com.example.mobileappsfc and your debug SHA-1.',
        );
      }
      if (text.contains('ApiException: 12500')) {
        throw const AuthException(
          'Google sign in failed (error 12500). Finish the OAuth consent '
          'screen in Google Cloud (app name and support email).',
        );
      }
      if (text.contains('ApiException: 7') || text.contains('network_error')) {
        throw const AuthException(
          'Network error while contacting Google. Check the connection.',
        );
      }
      throw AuthException('Google sign in failed: ${e.code} ${e.message}');
    }
  }

  /// Makes sure a Google user has a row in `profiles` (name from Google).
  /// Safe to call many times. Never throws: the profile is not needed to
  /// use the app.
  static Future<void> ensureGoogleProfile() async {
    final u = _client.auth.currentUser;
    if (u == null || !_isGoogle(u)) return;
    try {
      final existing = await _client
          .from('profiles')
          .select('id')
          .eq('id', u.id)
          .maybeSingle();
      if (existing != null) return;

      final meta = u.userMetadata ?? const <String, dynamic>{};
      final raw =
          (meta['full_name'] ??
                  meta['name'] ??
                  u.email?.split('@').first ??
                  'Friend')
              .toString();
      final name = normalizeName(raw);
      await _client.from('profiles').insert({
        'id': u.id,
        'full_name': name.isEmpty ? 'Friend' : name,
        'provider': 'google',
      });
    } catch (_) {
      // ignore: the app works without the profile row
    }
  }

  // --------------------------------------------------------------- name only

  /// Trims and collapses repeated spaces: "  Ana   Cruz " -> "Ana Cruz".
  static String normalizeName(String name) =>
      name.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// True when no name-only account uses [name] yet (case-insensitive).
  /// Calls the `is_name_available` database function, so it also works
  /// before the user is signed in.
  static Future<bool> isNameAvailable(String name) async {
    final res = await _client.rpc(
      'is_name_available',
      params: {'p_name': normalizeName(name)},
    );
    return res == true;
  }

  /// Creates the account from just a name.
  ///
  /// Throws [NameTakenException] when the name is already used.
  /// Other failures surface as [AuthException] / [PostgrestException].
  static Future<void> signUpWithName(String name) async {
    final clean = normalizeName(name);

    // 1) Friendly early check, before any account is created.
    if (!await isNameAvailable(clean)) throw const NameTakenException();

    // 2) Create the anonymous account.
    final res = await _client.auth.signInAnonymously();
    final newUser = res.user;
    if (newUser == null) {
      throw const AuthException('Could not create the account.');
    }

    // 3) Save the name. The unique index in the database is the final
    //    judge: if someone took the name a moment ago, Postgres answers
    //    23505 for that index.
    try {
      await _client.from('profiles').upsert({
        'id': newUser.id,
        'full_name': clean,
        'provider': 'name',
      });
    } on PostgrestException catch (e) {
      await _client.auth.signOut(); // don't keep a half-made account
      if (_isNameConflict(e)) throw const NameTakenException();
      rethrow;
    } catch (_) {
      await _client.auth.signOut();
      rethrow;
    }
  }

  /// True only when the failure is the unique-name index, not some other
  /// 23505 (for example the primary key on `id`).
  static bool _isNameConflict(PostgrestException e) {
    if (e.code != '23505') return false;
    final text = '${e.message} ${e.details ?? ''}'.toLowerCase();
    return text.contains('profiles_full_name_unique');
  }

  // ------------------------------------------------------------------ shared

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
