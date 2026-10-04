import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_config.dart';

/// Why a code is being requested.
enum OtpPurpose { signup, recovery }

class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class OtpSendResult {
  const OtpSendResult({this.exists = false, this.devCode});

  /// Sign-up for an email that already has an account.
  final bool exists;

  /// Only present while no email provider is configured (testing aid).
  final String? devCode;
}

/// All authentication and onboarding calls. Screens depend on this class
/// only, so tests can swap in a fake via [AuthService.instance].
class AuthService {
  AuthService();
  static AuthService instance = AuthService();

  SupabaseClient get _c => SupabaseConfig.client;

  Session? get session => _c.auth.currentSession;
  User? get user => _c.auth.currentUser;
  bool get signedIn => session != null;

  Future<OtpSendResult> sendOtp(String email, OtpPurpose purpose) async {
    final res = await _invoke('otp-send',
        {'email': email.trim().toLowerCase(), 'purpose': purpose.name});
    return OtpSendResult(
      exists: res['exists'] == true,
      devCode: res['dev_code'] as String?,
    );
  }

  /// Verifies the 6-digit code and signs the user in.
  Future<bool> verifyOtp(String email, String code, OtpPurpose purpose) async {
    final res = await _invoke('otp-verify', {
      'email': email.trim().toLowerCase(),
      'code': code,
      'purpose': purpose.name,
    });
    final hash = res['token_hash'] as String?;
    if (hash == null) throw AuthFailure('Could not verify the code.');
    try {
      await _c.auth.verifyOTP(tokenHash: hash, type: OtpType.magiclink);
    } on AuthException catch (e) {
      throw AuthFailure(_friendly(e.message));
    }
    return res['is_new'] == true;
  }

  Future<void> setPassword(String password) async {
    try {
      await _c.auth.updateUser(UserAttributes(password: password));
      await setStep('profile');
    } on AuthException catch (e) {
      throw AuthFailure(_friendly(e.message));
    }
  }

  /// Route to resume onboarding from the saved step.
  static String routeForStep(String step) {
    switch (step) {
      case 'created':
      case 'email_verified':
        return '/create-password';
      case 'profile':
        return '/personal-details';
      case 'location':
        return '/location-gate';
      case 'verification':
        return '/identity-verification';
      default:
        return '/home';
    }
  }

  Future<void> setStep(String step) async {
    final id = user?.id;
    if (id == null) return;
    await _c.from('profiles').update({'onboarding_step': step}).eq('id', id);
  }

  /// Where an interrupted onboarding should resume. 'done' means go home.
  Future<String> onboardingStep() async {
    final id = user?.id;
    if (id == null) return 'created';
    final r = await _c
        .from('profiles')
        .select('onboarding_step')
        .eq('id', id)
        .maybeSingle();
    return (r?['onboarding_step'] as String?) ?? 'created';
  }

  Future<void> signIn(String email, String password) async {
    try {
      await _c.auth.signInWithPassword(
          email: email.trim().toLowerCase(), password: password);
    } on AuthException catch (e) {
      throw AuthFailure(_friendly(e.message));
    }
  }

  Future<void> signOut() async {
    try {
      await _c.auth.signOut();
    } catch (_) {}
    // The library removes the saved login in the background. Do it here too
    // and wait, so closing the app right after logging out can't leave the
    // person signed in.
    await SupabaseConfig.clearStoredSession();
  }

  Future<void> changePassword(String current, String next) async {
    final email = user?.email;
    if (email == null) throw AuthFailure('Please log in again.');
    await signIn(email, current);
    await setPasswordOnly(next);
  }

  Future<void> setPasswordOnly(String password) async {
    try {
      await _c.auth.updateUser(UserAttributes(password: password));
    } on AuthException catch (e) {
      throw AuthFailure(_friendly(e.message));
    }
  }

  Future<Map<String, dynamic>> _invoke(
      String fn, Map<String, dynamic> body) async {
    try {
      final r = await _c.functions.invoke(fn, body: body);
      final d = r.data;
      if (d is Map) return Map<String, dynamic>.from(d);
      throw AuthFailure('Unexpected response. Please try again.');
    } on FunctionException catch (e) {
      final d = e.details;
      if (d is Map && d['error'] is String) throw AuthFailure(d['error']);
      throw AuthFailure('Something went wrong. Please try again.');
    } on AuthFailure {
      rethrow;
    } catch (e) {
      debugPrint('auth invoke failed: $e');
      throw AuthFailure('No connection. Check your internet and try again.');
    }
  }

  String _friendly(String m) {
    final l = m.toLowerCase();
    if (l.contains('invalid login')) return 'Incorrect email or password.';
    if (l.contains('weak') || l.contains('password should')) {
      return 'Choose a stronger password (8+ characters, mix of letters and numbers).';
    }
    if (l.contains('same password')) return 'Choose a different password.';
    if (l.contains('rate')) return 'Too many attempts. Please wait a moment.';
    if (l.contains('network') || l.contains('socket')) {
      return 'No connection. Check your internet and try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
