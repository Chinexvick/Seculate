import 'backend.dart';

/// Wallet: top-up, withdraw to a bank, and spend on credits or plans.
extension BackendWallet on Backend {
  Map<String, dynamic> _wm(dynamic d) =>
      d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};

  Future<Map<String, dynamic>> myWallet() =>
      runRpc(() async => _wm(await c.rpc('my_wallet')));

  /// Starts a top-up. Returns the hosted payment link.
  Future<String> startTopup(int amount) async {
    final d = await fn('payment-init', {'purpose': 'topup', 'amount': amount});
    final link = d['link'];
    if (link is String && link.isNotEmpty) return link;
    throw BackendError('Payment is not available right now.');
  }

  Future<bool> syncTopup() async {
    try {
      final d = await fn('payment-init', {'purpose': 'topup_sync'});
      return d['applied'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, String>>> banks() async {
    final d = await fn('wallet-withdraw', {'action': 'banks'});
    return (d['banks'] as List? ?? const [])
        .map((e) => {
              'code': '${(e as Map)['code']}',
              'name': '${e['name']}',
            })
        .toList();
  }

  Future<String> resolveAccount(String bankCode, String account) async {
    final d = await fn('wallet-withdraw', {
      'action': 'resolve',
      'bank_code': bankCode,
      'account_number': account,
    });
    return '${d['account_name']}';
  }

  /// Returns `processing`, `successful` or `failed`.
  Future<String> withdraw({
    required int amount,
    required String bankCode,
    required String bankName,
    required String account,
  }) async {
    final d = await fn('wallet-withdraw', {
      'action': 'withdraw',
      'amount': amount,
      'bank_code': bankCode,
      'bank_name': bankName,
      'account_number': account,
    });
    return '${d['status'] ?? 'processing'}';
  }

  Future<void> walletPayCredits(String bundleId) => runRpc(() async {
        await c.rpc('wallet_pay_credits', params: {'p_bundle': bundleId});
      });

  Future<void> walletPayPlan(String planId) => runRpc(() async {
        await c.rpc('wallet_pay_plan', params: {'p_plan': planId});
      });

  // ---- certificates & trust ----
  Future<List<Map<String, dynamic>>> myCertificates() => runRpc(() async {
        final r = await c.rpc('my_certificates');
        return r is List
            ? r.map((e) => Map<String, dynamic>.from(e as Map)).toList()
            : <Map<String, dynamic>>[];
      });

  Future<Map<String, dynamic>> verifyCertificate(String number) =>
      runRpc(() async =>
          _wm(await c.rpc('verify_certificate', params: {'p_number': number})));

  Future<Map<String, dynamic>> myTrust() =>
      runRpc(() async => _wm(await c.rpc('my_trust')));
}

/// Problem reports (disputes), deal timeline and agreement certificates.
extension BackendDeals on Backend {
  Future<void> reportProblem(String txId,
      {required String code,
      required String reason,
      List<String> photos = const []}) async {
    final keys =
        photos.isEmpty ? <String>[] : await uploadTxPhotos(txId, photos);
    await runRpc(() async {
      await c.rpc('report_problem', params: {
        'p_tx': txId,
        'p_code': code,
        'p_reason': reason,
        'p_paths': keys,
      });
    });
  }

  Future<void> respondProblem(String txId, String disputeId,
      {required String body, List<String> photos = const []}) async {
    final keys =
        photos.isEmpty ? <String>[] : await uploadTxPhotos(txId, photos);
    await runRpc(() async {
      await c.rpc('respond_dispute',
          params: {'p_dispute': disputeId, 'p_body': body, 'p_paths': keys});
    });
  }

  Future<Map<String, dynamic>?> disputeForTx(String txId) => runRpc(() async {
        final r = await c.rpc('dispute_for_tx', params: {'p_tx': txId});
        return r is Map ? Map<String, dynamic>.from(r) : null;
      });

  Future<Map<String, dynamic>?> certificateForTx(String txId) =>
      runRpc(() async {
        final r = await c.rpc('certificate_for_tx', params: {'p_tx': txId});
        return r is Map ? Map<String, dynamic>.from(r) : null;
      });

  Future<List<Map<String, dynamic>>> txTimeline(String txId) =>
      runRpc(() async {
        final r = await c.rpc('tx_timeline', params: {'p_tx': txId});
        return r is List
            ? r.map((e) => Map<String, dynamic>.from(e as Map)).toList()
            : <Map<String, dynamic>>[];
      });
}
