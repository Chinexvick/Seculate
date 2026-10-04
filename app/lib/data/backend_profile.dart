import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

import 'backend.dart';
import 'profile_service.dart';

/// Profile / settings / verification calls.
extension BackendProfile on Backend {
  /// The raw preferences jsonb (notification toggles plus chat_enabled /
  /// feedback_enabled).
  Future<Map<String, dynamic>> loadPrefs() async {
    try {
      final r = await c
          .from('notification_preferences')
          .select('prefs')
          .eq('user_id', uid)
          .maybeSingle();
      final p = r?['prefs'];
      return p is Map ? Map<String, dynamic>.from(p) : <String, dynamic>{};
    } catch (e) {
      throw BackendError(
          'Could not load your settings. Check your connection and try again.');
    }
  }

  /// Merges [patch] into the stored prefs (keeps keys we do not know about).
  Future<void> savePrefs(Map<String, bool> patch) async {
    try {
      final cur = await loadPrefs();
      final merged = <String, bool>{
        for (final e in cur.entries)
          if (e.value is bool) e.key: e.value as bool,
        ...patch,
      };
      await ProfileService.instance.saveNotificationPrefs(merged);
    } catch (e) {
      if (e is BackendError) rethrow;
      throw BackendError('Could not save your settings. Please try again.');
    }
  }

  /// Uploads a verification document to the private `verification-docs`
  /// bucket under `<uid>/`. Records nothing else; returns the storage path.
  Future<String> uploadVerificationDoc(String filePath,
      {String label = 'doc'}) async {
    try {
      final Uint8List bytes = await File(filePath).readAsBytes();
      final safe = label.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final key = '$uid/${safe}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await c.storage.from('verification-docs').uploadBinary(key, bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'));
      return key;
    } catch (e) {
      throw BackendError('Could not upload the document. Please try again.');
    }
  }
}
