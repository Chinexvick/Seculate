import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Public client configuration. The publishable key is safe to ship in the
/// app: every table is protected by Row Level Security. Secret keys
/// (service role, Flutterwave, Escrow) never belong here.
class SupabaseConfig {
  SupabaseConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL',
      defaultValue: 'https://lckwpcpvnwqfiozpsvdi.supabase.co');
  static const publishableKey = String.fromEnvironment('SUPABASE_KEY',
      defaultValue: 'sb_publishable_47RRabjk2OIi6lP6dOSldQ_BJelFxbX');

  static bool _ready = false;
  static bool get ready => _ready;

  static Future<void> init() async {
    await Supabase.initialize(
      url: url,
      publishableKey: publishableKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: _SecureStore(),
        autoRefreshToken: true,
      ),
    );
    _ready = true;
  }

  static SupabaseClient get client => Supabase.instance.client;

  /// Deletes the stored session right now. Signing out normally removes it in
  /// the background; this makes sure it is gone before the app can be closed.
  static Future<void> clearStoredSession() async {
    try {
      await _SecureStore._s.delete(key: _SecureStore._key);
    } catch (_) {}
  }
}

/// Keeps the session in the Android Keystore-backed secure storage instead
/// of plain SharedPreferences.
class _SecureStore extends LocalStorage {
  _SecureStore();
  static const _key = 'supabase.session';
  static const _s = FlutterSecureStorage();

  @override
  Future<void> initialize() async {}
  @override
  Future<bool> hasAccessToken() async => (await _s.read(key: _key)) != null;
  @override
  Future<String?> accessToken() => _s.read(key: _key);
  @override
  Future<void> persistSession(String persistSessionString) =>
      _s.write(key: _key, value: persistSessionString);
  @override
  Future<void> removePersistedSession() => _s.delete(key: _key);
}
