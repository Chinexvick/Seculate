import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prembly_identity_kyc/prembly_identity_kyc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_config.dart';

/// Result of the in-app ID + face-scan check.
enum WidgetOutcome { verified, pending, rejected, cancelled, failedToStart }

class WidgetResult {
  const WidgetResult(this.outcome, [this.message]);
  final WidgetOutcome outcome;
  final String? message;
}

/// Runs Prembly's in-app widget (ID document + face scan). The widget keys come
/// from our server only to a signed-in user; the result is reported back to the
/// server, which decides the final status.
class IdentityWidget {
  IdentityWidget._();

  static Future<WidgetResult> run(BuildContext context) async {
    final c = SupabaseConfig.client;
    Map<String, dynamic> s;
    try {
      final r = await c.functions.invoke('identity-session', body: {});
      final d = r.data;
      if (d is! Map || d['ok'] != true) {
        return const WidgetResult(
            WidgetOutcome.failedToStart, 'Could not start verification.');
      }
      s = Map<String, dynamic>.from(d);
    } on FunctionException catch (e) {
      final d = e.details;
      return WidgetResult(
          WidgetOutcome.failedToStart,
          d is Map && d['error'] is String
              ? d['error'] as String
              : 'Could not start verification.');
    } catch (_) {
      return const WidgetResult(WidgetOutcome.failedToStart,
          'No connection. Check your internet and try again.');
    }

    final done = Completer<Map<String, dynamic>>();
    if (!context.mounted) return const WidgetResult(WidgetOutcome.cancelled);
    PremblyIdentityKyc.verify(
      context: context,
      options: IdentityKycOptions(
        widgetKey: s['widget_key'] as String,
        widgetId: s['widget_id'] as String,
        firstName: (s['first_name'] as String?)?.isNotEmpty == true
            ? s['first_name'] as String
            : 'Seculate',
        lastName: (s['last_name'] as String?)?.isNotEmpty == true
            ? s['last_name'] as String
            : 'User',
        email: (s['email'] as String?) ?? '',
        phone: s['phone'] as String?,
        userRef: s['ref'] as String,
        isTest: s['is_test'] == true,
        metadata: {'seculate_ref': s['ref']},
        callback: (resp) {
          if (!done.isCompleted) done.complete(resp);
        },
      ),
    );
    final resp = await done.future;
    final status = '${resp['status']}';
    if (status == 'closed' || status == 'error_display_closed') {
      return const WidgetResult(WidgetOutcome.cancelled);
    }
    if (status == 'network_error' || status == 'api_error') {
      return WidgetResult(WidgetOutcome.failedToStart,
          '${resp['message'] ?? 'Could not reach the verification service. Try again.'}');
    }
    final msg = '${resp['message'] ?? ''}'.toLowerCase();
    if (status == 'error' && msg.contains('permission')) {
      return const WidgetResult(WidgetOutcome.failedToStart,
          'Allow camera access for Seculate in Settings, then try again.');
    }
    final outcome = status == 'success' ? 'success' : 'failed';
    try {
      final r = await c.functions.invoke('identity-complete',
          body: {'ref': s['ref'], 'outcome': outcome});
      final d = r.data;
      if (d is Map && d['ok'] == true) {
        switch (d['status']) {
          case 'verified':
            return const WidgetResult(WidgetOutcome.verified);
          case 'pending':
            return const WidgetResult(WidgetOutcome.pending);
          default:
            return WidgetResult(
                WidgetOutcome.rejected, d['message'] as String?);
        }
      }
    } on FunctionException catch (e) {
      final d = e.details;
      if (d is Map && d['error'] is String) {
        return WidgetResult(WidgetOutcome.failedToStart, d['error'] as String);
      }
    } catch (_) {}
    return const WidgetResult(WidgetOutcome.failedToStart,
        'We could not save the result. Please try again.');
  }
}
