import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_config.dart';
import 'auth_service.dart';
import 'user_profile.dart';

class ProfileService {
  ProfileService._();
  static ProfileService instance = ProfileService._();

  SupabaseClient get _c => SupabaseConfig.client;

  /// Loads the signed-in user's profile into [currentProfile].
  Future<void> load() async {
    final id = AuthService.instance.user?.id;
    if (id == null) return;
    final r = await _c.from('profiles').select().eq('id', id).maybeSingle();
    if (r == null) return;
    final p = currentProfile;
    p.id = id;
    p.firstName = (r['first_name'] ?? '') as String;
    p.lastName = (r['last_name'] ?? '') as String;
    p.email = (r['email'] ?? '') as String;
    final phone = (r['phone'] ?? '') as String;
    p.phone = phone;
    p.phoneVerified = r['phone_verified'] == true;
    p.location = (r['country'] ?? '') as String;
    p.city = (r['city'] ?? '') as String;
    p.address = (r['address'] ?? '') as String;
    p.sex = (r['sex'] ?? '') as String;
    final b = r['birthday'] as String?;
    p.birthday = b == null ? '' : b.split('-').reversed.join('/');
    p.businessName = (r['business_name'] ?? '') as String;
    p.about = (r['business_about'] ?? '') as String;
    p.link = (r['business_link'] ?? '') as String;
    p.avatarUrl = r['avatar_url'] as String?;
    p.language = (r['language'] ?? 'English UK') as String;
    p.verificationStatus = (r['verification_status'] ?? 'unverified') as String;
    p.ratingAvg = (r['rating_avg'] as num?)?.toDouble() ?? 0;
    p.ratingCount = (r['rating_count'] as num?)?.toInt() ?? 0;
    p.accountStatus = (r['account_status'] ?? 'active') as String;
    p.mustChangePassword = r['must_change_password'] == true;
    final prefs = await _c
        .from('notification_preferences')
        .select('prefs')
        .eq('user_id', id)
        .maybeSingle();
    if (prefs != null && prefs['prefs'] is Map) {
      (prefs['prefs'] as Map).forEach((k, v) {
        if (p.notifications.containsKey(k)) p.notifications[k] = v == true;
      });
    }
  }

  Future<void> saveDetails(
      {required String first,
      required String last,
      required String phone10}) async {
    final id = AuthService.instance.user!.id;
    await _c.from('profiles').update({
      'first_name': first.trim(),
      'last_name': last.trim(),
      'phone': '+234$phone10',
      'onboarding_step': 'location',
    }).eq('id', id);
    await load();
  }

  Future<void> update(Map<String, dynamic> fields) async {
    final id = AuthService.instance.user!.id;
    await _c.from('profiles').update(fields).eq('id', id);
    await load();
  }

  Future<void> saveNotificationPrefs(Map<String, bool> prefs) async {
    final id = AuthService.instance.user!.id;
    await _c
        .from('notification_preferences')
        .upsert({'user_id': id, 'prefs': prefs});
  }

  /// The NIN goes to a server function: the app never stores them. The
  /// server verifies them with the identity partner and keeps only the last
  /// 4 digits and a hash. Returns the resulting status (verified / pending).
  Future<String> submitIdentity({required String nin}) async {
    try {
      final r = await _c.functions
          .invoke('verify-identity', body: {'nin': nin, 'consent': true});
      final d = r.data;
      if (d is Map && d['ok'] == true) {
        return (d['status'] ?? 'pending') as String;
      }
      throw AuthFailure('Could not submit. Please try again.');
    } on AuthFailure {
      rethrow;
    } on FunctionException catch (e) {
      final d = e.details;
      if (d is Map && d['error'] is String) {
        throw AuthFailure(d['error'] as String);
      }
      throw AuthFailure('Could not submit. Please try again.');
    } catch (_) {
      throw AuthFailure('No connection. Check your internet and try again.');
    }
  }

  // --- location ---------------------------------------------------------

  Future<LocationPermission> locationPermission() =>
      Geolocator.checkPermission();

  /// Requests permission, reads the position and stores it server-side.
  /// Returns null on success, or a user-facing reason on failure.
  Future<String?> captureLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return 'Turn on your phone’s location (GPS) to continue.';
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) {
      return 'Seculate needs your location to show items and services near you.';
    }
    if (perm == LocationPermission.deniedForever) {
      return 'Location is blocked. Open Settings and allow location for Seculate.';
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 20)));
      await _c.rpc('set_my_location',
          params: {'p_lat': pos.latitude, 'p_lng': pos.longitude});
      currentProfile.lat = pos.latitude;
      currentProfile.lng = pos.longitude;
      return null;
    } catch (_) {
      return 'We couldn’t get your location. Please try again.';
    }
  }

  Future<void> openLocationSettings() => Geolocator.openAppSettings();
}
