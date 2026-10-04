import 'backend.dart';

/// Credits and item requests (the "I need something" marketplace).
extension BackendCredits on Backend {
  Map<String, dynamic> _map(dynamic d) =>
      d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};

  List<Map<String, dynamic>> _list(dynamic d) => d is List
      ? d.map((e) => Map<String, dynamic>.from(e as Map)).toList()
      : <Map<String, dynamic>>[];

  /// Balance, bundles for sale, what actions cost, and recent history.
  Future<Map<String, dynamic>> myCredits() =>
      runRpc(() async => _map(await c.rpc('my_credits')));

  /// Starts a credit purchase. Returns the hosted payment link.
  Future<String> startCreditPayment(String bundleId) async {
    final d =
        await fn('payment-init', {'purpose': 'credits', 'bundle_id': bundleId});
    final link = d['link'];
    if (link is String && link.isNotEmpty) return link;
    throw BackendError('Payment is not available right now.');
  }

  /// Fallback lookup if the provider's webhook is slow. True when applied.
  Future<bool> syncCreditPayment() async {
    try {
      final d = await fn('payment-init', {'purpose': 'credits_sync'});
      return d['applied'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> nearbyRequests() => runRpc(() async {
        final p = await c.rpc('search_requests', params: {
          'p_lat': null,
          'p_lng': null,
          'p_limit': 40,
        });
        return _list(p);
      });

  Future<List<Map<String, dynamic>>> myRequests() =>
      runRpc(() async => _list(await c.rpc('my_requests')));

  Future<Map<String, dynamic>> requestDetail(String id) => runRpc(
      () async => _map(await c.rpc('request_detail', params: {'p_id': id})));

  Future<String> createRequest({
    required String title,
    required String description,
    required num budget,
    required int days,
    required DateTime from,
    required num radiusKm,
    double? lat,
    double? lng,
    String? area,
  }) =>
      runRpc(() async {
        final r = await c.rpc('create_request', params: {
          'p_title': title,
          'p_description': description,
          'p_category': null,
          'p_budget': budget,
          'p_days': days,
          'p_from': from.toIso8601String().substring(0, 10),
          'p_radius': radiusKm,
          'p_lat': lat,
          'p_lng': lng,
          'p_area': area,
        });
        return r.toString();
      });

  /// Spends credits to see the full request. Returns the new balance.
  Future<int> unlockRequest(String id) => runRpc(() async {
        final r = await c.rpc('unlock_request', params: {'p_id': id});
        return (r as num).toInt();
      });

  Future<void> submitBid(String requestId,
          {required num price,
          num deposit = 0,
          String message = '',
          String? listingId}) =>
      runRpc(() async {
        await c.rpc('submit_bid', params: {
          'p_request': requestId,
          'p_price': price,
          'p_deposit': deposit,
          'p_message': message,
          'p_listing': listingId,
        });
      });

  /// Edits a request and sends it back for review.
  Future<void> updateRequest(String id,
          {required String title,
          required String description,
          required num budget,
          required int days,
          required DateTime from,
          required num radiusKm}) =>
      runRpc(() async {
        await c.rpc('update_request', params: {
          'p_id': id,
          'p_title': title,
          'p_description': description,
          'p_budget': budget,
          'p_days': days,
          'p_from': from.toIso8601String().substring(0, 10),
          'p_radius': radiusKm,
        });
      });

  Future<void> setListingPaused(String id, bool paused) => runRpc(() async {
        await c.rpc('set_listing_paused',
            params: {'p_id': id, 'p_paused': paused});
      });

  Future<void> withdrawBid(String bidId) =>
      runRpc(() async => c.rpc('withdraw_bid', params: {'p_bid': bidId}));

  Future<void> rejectBid(String bidId) =>
      runRpc(() async => c.rpc('reject_bid', params: {'p_bid': bidId}));

  Future<void> counterBid(String bidId, num price, String message) =>
      runRpc(() async => c.rpc('counter_bid',
          params: {'p_bid': bidId, 'p_price': price, 'p_message': message}));

  /// Accepts an offer. Returns the new transaction id.
  Future<String> acceptBid(String bidId) => runRpc(() async =>
      (await c.rpc('accept_bid', params: {'p_bid': bidId})).toString());

  /// Accepts or declines a counter offer. Returns the transaction id when accepted.
  Future<String?> respondCounter(String bidId, bool accept) => runRpc(() async {
        final r = await c.rpc('respond_counter',
            params: {'p_bid': bidId, 'p_accept': accept});
        return r?.toString();
      });

  Future<void> cancelRequest(String id) =>
      runRpc(() async => c.rpc('cancel_request', params: {'p_id': id}));

  Future<String> reuseRequest(String id) => runRpc(() async =>
      (await c.rpc('reuse_request', params: {'p_id': id})).toString());
}
