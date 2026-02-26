import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Result DTO
// ─────────────────────────────────────────────────────────────────────────────

/// The data returned after a successful Google sign-in.
///
/// [idToken] is the signed JWT from Google's servers — pass it to your
/// backend if you implement server-side Google token verification.
/// [user]    is the [UserModel] built from the Google account profile;
/// it is marked [isEmailVerified] = true because Google has already
/// verified the email address.
class GoogleSignInResult {
  final String    idToken;
  final UserModel user;

  const GoogleSignInResult({required this.idToken, required this.user});
}

// ─────────────────────────────────────────────────────────────────────────────
// Typed exception
// ─────────────────────────────────────────────────────────────────────────────

/// Thrown by [GoogleAuthService] when sign-in fails or is cancelled.
class GoogleSignInException implements Exception {
  final String message;
  const GoogleSignInException(this.message);

  @override
  String toString() => 'GoogleSignInException: $message';
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps the [google_sign_in] package behind a single async call.
///
/// Architecture notes:
///   • Singleton — one [GoogleSignIn] instance is reused across calls.
///   • No Dio / HTTP calls here — the [idToken] is returned so [AuthProvider]
///     can decide whether to call the backend (e.g. POST /api/users/google)
///     or treat the Google session as the sole auth token.
///   • Signing out from Google is separate from [AuthProvider.signOut] so
///     that a user can switch Google accounts without clearing their
///     AquaSense session prefs.
class GoogleAuthService {
  GoogleAuthService._();
  static final GoogleAuthService instance = GoogleAuthService._();

  /// [GoogleSignIn] instance.
  ///
  /// [scopes] requests read access to the user's basic profile and email.
  /// Add more OAuth scopes here if backend integration requires them.
  final _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  // ── Sign in ────────────────────────────────────────────────────────────────

  /// Triggers the Google account picker and returns a [GoogleSignInResult].
  ///
  /// Throws [GoogleSignInException] when:
  ///   • The user cancels the account picker.
  ///   • The Google authentication step fails.
  ///   • An ID token cannot be retrieved (missing SHA-1 / OAuth config).
  Future<GoogleSignInResult> signIn() async {
    try {
      // Show the Google account picker — returns null if cancelled
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw const GoogleSignInException(
          'Sign-in was cancelled. Please try again.',
        );
      }

      // Fetch the auth tokens — idToken contains the signed JWT
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        throw const GoogleSignInException(
          'Could not retrieve Google token. '
          'Ensure google-services.json is configured correctly.',
        );
      }

      // Build a [UserModel] from the Google profile.
      // Email is always verified by Google.
      final user = UserModel(
        email:           account.email,
        username:        account.displayName?.replaceAll(' ', '') ?? account.email.split('@').first,
        fullName:        account.displayName,
        // Google sign-in doesn't use the AquaSense JWT (no backend call here).
        // If your backend has a POST /api/users/google endpoint, call it in
        // [AuthProvider.signInWithGoogle] and set the token from the response.
        token:           idToken,
        isEmailVerified: true,
        rememberMe:      true, // Google sessions are inherently "remember me"
      );

      return GoogleSignInResult(idToken: idToken, user: user);
    } on GoogleSignInException {
      rethrow;
    } catch (e) {
      throw GoogleSignInException('Google sign-in failed: $e');
    }
  }

  // ── Sign out ───────────────────────────────────────────────────────────────

  /// Signs out of the Google session so the account picker shows on next login.
  ///
  /// Call this from [AuthProvider.signOut] to ensure the user is not silently
  /// re-authenticated on next app launch via a cached Google token.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Swallow — Google sign-out failure should not block AquaSense sign-out
    }
  }

  // ── Disconnect ─────────────────────────────────────────────────────────────

  /// Revokes all OAuth scopes and removes the app from the user's Google
  /// account. Use this for "Delete Account" flows, not ordinary sign-out.
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {}
  }
}
