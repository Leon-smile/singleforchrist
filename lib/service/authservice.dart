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
///  * Email + password -> real Supabase user (email confirmation supported)
///  * Google           -> real Supabase user, works on any device
///
/// The `profiles` row is created by the `handle_new_user` database trigger.
class AuthService {
  AuthService._();

  static SupabaseClient get _client => Supabase.instance.client;

  static const mobileRedirect =
      'https://gmukhkhkldbzivuhqzdd.supabase.co/auth/v1/callback';

  static const googleWebClientId =
      '1088965435374-afirgoru8mmdnqhfuctpl4vruebkg1o8.apps.googleusercontent.com';
  static const googleIosClientId = '';

  static Session? get session => _client.auth.currentSession;
  static User? get user => _client.auth.currentUser;
  static bool get isSignedIn => session != null;
  static Stream<AuthState> get changes => _client.auth.onAuthStateChange;

  // ------------------------------------------------------------- validation

  static final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static String normalizeEmail(String email) => email.trim().toLowerCase();

  static bool isValidEmail(String email) {
    final e = normalizeEmail(email);
    return e.length <= 254 && _emailRe.hasMatch(e);
  }

  /// Returns an error message, or null when the password is acceptable.
  /// Keep in sync with the minimum length set in Supabase > Auth > Providers.
  static String? passwordProblem(String password) {
    if (password.length < 8) return 'Use at least 8 characters';
    if (password.length > 72) return 'Password is too long (72 max)';
    if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
      return 'Use letters and at least one number';
    }
    return null;
  }

  // ------------------------------------------------------------------ Google

  static bool _isGoogle(User? u) => u?.appMetadata['provider'] == 'google';
  static bool get isGoogleUser => _isGoogle(_client.auth.currentUser);

  static bool get _useNativeGoogle =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

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

      await google.signOut();

      final account = await google.signIn();
      if (account == null) return;

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
        return;
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

  /// The database trigger now creates the profile row for Google users, so
  /// there is nothing to insert from the app. Kept so existing callers
  /// keep compiling.
  static Future<void> ensureGoogleProfile() async {}

  // ------------------------------------------------------------------- name

  static String normalizeName(String name) =>
      name.trim().replaceAll(RegExp(r'\s+'), ' ');

  static Future<bool> isNameAvailable(String name) async {
    final res = await _client.rpc(
      'is_name_available',
      params: {'p_name': normalizeName(name)},
    );
    return res == true;
  }

  // ------------------------------------------------------------------ email

  /// Creates an account with email + password.
  ///
  /// Returns true when the user is signed in right away, false when the
  /// project requires email confirmation first (show "check your inbox").
  ///
  /// When the email is already registered and confirmation is on, Supabase
  /// returns a user with no identities. We treat that exactly like a normal
  /// sign up (returns false) so the screen never reveals which emails exist.
  static Future<bool> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanName = normalizeName(name);
    final cleanEmail = normalizeEmail(email);

    if (!await isNameAvailable(cleanName)) throw const NameTakenException();

    final res = await _client.auth.signUp(
      email: cleanEmail,
      password: password,
      data: {'full_name': cleanName}, // read by the handle_new_user trigger
      emailRedirectTo: kIsWeb ? Uri.base.origin : null,
    );

    return res.session != null;
  }

  /// Email + password sign in. Throws [AuthException] with a friendly message.
  static Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: normalizeEmail(email),
        password: password,
      );
    } on AuthException catch (e) {
      if (e.code == 'email_not_confirmed') {
        throw const AuthException(
          'Please confirm your email first. Check your inbox.',
        );
      }
      if (e.code == 'over_request_rate_limit' || e.statusCode == '429') {
        throw const AuthException(
          'Too many attempts. Please wait a minute and try again.',
        );
      }
      // Same message for "no such user" and "wrong password".
      throw const AuthException('Incorrect email or password.');
    }
  }

  /// Sends a reset link. Callers should always show the same neutral message
  /// afterwards, whether or not the email exists.
  static Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(
      normalizeEmail(email),
      redirectTo: kIsWeb ? Uri.base.origin : null,
    );
  }

  static Future<void> resendConfirmation(String email) async {
    await _client.auth.resend(
      type: OtpType.signup,
      email: normalizeEmail(email),
    );
  }

  /// Confirms the 6-digit code from the sign-up email and signs the user in.
  static Future<void> verifySignUpCode({
    required String email,
    required String code,
  }) async {
    await _client.auth.verifyOTP(
      email: normalizeEmail(email),
      token: code.trim(),
      type: OtpType.signup,
    );
  }

  /// Call after the user opens the reset link (event `passwordRecovery`).
  static Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  // ------------------------------------------------------------------ shared

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
