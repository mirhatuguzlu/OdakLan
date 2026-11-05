import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Passed with --dart-define-from-file=env.json (see env.example.json); never committed.
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
const _googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
const _googleIosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

const backendConfigured = _supabaseUrl != '' && _supabaseKey != '';

/// Call once in main(); a build without keys runs fully offline.
Future<void> initBackend() async {
  if (!backendConfigured) return;
  await Supabase.initialize(
    url: _supabaseUrl,
    publishableKey: _supabaseKey,
    authOptions: const FlutterAuthClientOptions(
      localStorage: _SecureSessionStorage(),
    ),
  );
}

/// The signed-in user as the app shows it. [nickname] is null until the
/// profile row loads (or if it could not be fetched).
typedef Account = ({String id, String? email, String? nickname});

class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;
  Future<void>? _googleReady;

  Stream<Account?> accounts() =>
      _client.auth.onAuthStateChange.asyncMap((s) async {
        final user = s.session?.user;
        if (user == null) return null;
        String? nickname;
        try {
          final row = await _client
              .from('profiles')
              .select('display_name')
              .eq('id', user.id)
              .maybeSingle();
          nickname = row?['display_name'] as String?;
        } catch (_) {
          // Offline: still signed in, just without the nickname.
        }
        return (id: user.id, email: user.email, nickname: nickname);
      }).distinct();

  /// Native Google account picker → ID token → Supabase session.
  /// Returns false if the user closed the picker.
  Future<bool> signInWithGoogle() async {
    final google = GoogleSignIn.instance;
    await (_googleReady ??= google.initialize(
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? _googleIosClientId
          : null,
      serverClientId: _googleWebClientId,
    ));
    final GoogleSignInAccount picked;
    try {
      picked = await google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      rethrow;
    }
    final idToken = picked.authentication.idToken;
    if (idToken == null) throw const AuthException('Google kimliği alınamadı');
    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
    return true;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    // Next sign-in shows the account picker again.
    if (_googleReady != null) await GoogleSignIn.instance.signOut();
  }
}

final authServiceProvider = Provider<AuthService?>(
  (ref) => backendConfigured ? AuthService(Supabase.instance.client) : null,
);

final accountProvider = StreamProvider<Account?>(
  (ref) => ref.watch(authServiceProvider)?.accounts() ?? Stream.value(null),
);

/// Session tokens in Keychain / Android Keystore instead of SharedPreferences.
class _SecureSessionStorage extends LocalStorage {
  const _SecureSessionStorage();

  static const _key = 'supabase.session';
  static const _storage = FlutterSecureStorage();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: _key);

  @override
  Future<String?> accessToken() => _storage.read(key: _key);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _key, value: persistSessionString);
}
