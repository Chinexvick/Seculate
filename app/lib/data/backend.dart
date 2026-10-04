import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_config.dart';
import 'auth_service.dart';
import 'models.dart';
import 'user_profile.dart';

/// A user-facing failure with a friendly message.
class BackendError implements Exception {
  BackendError(this.message, {this.code, this.extra});
  final String message;

  /// Machine-readable reason from the server, e.g. `identity_required`.
  final String? code;
  final Map<String, dynamic>? extra;
  @override
  String toString() => message;
}

/// Result of sending a chat message.
class SendResult {
  const SendResult(
      {required this.ok,
      this.blocked = false,
      this.error,
      this.flagged = false,
      this.id});
  final bool ok;

  /// The message was stopped by safety rules (contact details, off-platform
  /// payment, etc). [error] explains why.
  final bool blocked;
  final String? error;
  final bool flagged;
  final String? id;
}

class ListingDraft {
  ListingDraft({
    required this.kind,
    required this.title,
    required this.description,
    required this.categoryLabel,
    this.subCategory,
    this.pricePerDay = 0,
    this.collateral = 0,
    this.securityFee = 0,
    this.minDays,
    this.maxDays,
    this.stock = 1,
    this.lendingPeriod,
    this.availability,
    this.deliveryOption,
    this.locationLabel,
    this.features = const [],
    this.photos = const [],
  });
  final String kind;
  final String title;
  final String description;
  final String categoryLabel;
  final String? subCategory;
  final int pricePerDay;
  final int collateral;
  final int securityFee;
  final int? minDays;
  final int? maxDays;
  final int stock;
  final String? lendingPeriod;
  final String? availability;
  final String? deliveryOption;
  final String? locationLabel;
  final List<String> features;

  /// Local file paths of photos to upload.
  final List<String> photos;
}

/// Every call the app makes to the server. Screens use the single [backend]
/// instance; tests replace it with a subclass that returns canned data.
///
/// Security: this class only ever talks to Supabase with the signed-in
/// user's session. Everything sensitive (payments, escrow, moderation,
/// violations, reputation) is enforced by database rules and server
/// functions, never by checks here.
class Backend {
  SupabaseClient get c => SupabaseConfig.client;
  String get uid => c.auth.currentUser?.id ?? '';

  BackendError _fail(Object e,
      [String fallback = 'Something went wrong. Please try again.']) {
    if (e is BackendError) return e;
    if (e is PostgrestException) {
      final m = e.message;
      // Our RPCs raise readable messages; surface those, hide the rest.
      if (e.code == 'P0001' || e.code == '42501' || e.code == '23505') {
        return BackendError(m.replaceAll(RegExp(r'^[A-Z_]+:\s*'), ''));
      }
      return BackendError(fallback);
    }
    if (e is SocketException || e is TimeoutException) {
      return BackendError('No connection. Check your internet and try again.');
    }
    return BackendError(fallback);
  }

  /// Calls an edge function; turns server errors into [BackendError] with the
  /// server's own friendly message and code.
  Future<Map<String, dynamic>> fn(
      String name, Map<String, dynamic> body) async {
    try {
      final r = await c.functions.invoke(name, body: body);
      final d = r.data;
      if (d is Map) return Map<String, dynamic>.from(d);
      throw BackendError('Unexpected response. Please try again.');
    } on FunctionException catch (e) {
      final d = e.details;
      if (d is Map) {
        throw BackendError(
            (d['error'] ?? 'Something went wrong. Please try again.')
                .toString(),
            code: d['code'] as String?,
            extra: Map<String, dynamic>.from(d));
      }
      throw BackendError('Something went wrong. Please try again.');
    } on BackendError {
      rethrow;
    } catch (e) {
      throw _fail(e);
    }
  }

  /// Same as [_run] for extensions in other files.
  Future<T> runRpc<T>(Future<T> Function() f) => _run(f);

  Future<T> _run<T>(Future<T> Function() f, [String? fallback]) async {
    try {
      return await f();
    } catch (e) {
      throw _fail(e, fallback ?? 'Something went wrong. Please try again.');
    }
  }

  // ───────────────────────── browse ─────────────────────────

  /// Items (and services) near the user, newest/closest first.
  Future<List<Product>> products({
    String query = '',
    String? category,
    String? kind,
    double? radiusKm,
    num? minPrice,
    num? maxPrice,
    double? minRating,
    int limit = 30,
    int offset = 0,
  }) =>
      _run(() async {
        final rows = await c.rpc('search_listings', params: {
          'p_q': query.trim(),
          'p_kind': kind,
          'p_category': category,
          'p_lat': currentProfile.lat,
          'p_lng': currentProfile.lng,
          'p_radius_km': radiusKm,
          'p_min_price': minPrice,
          'p_max_price': maxPrice,
          'p_min_rating': minRating,
          'p_limit': limit,
          'p_offset': offset,
        });
        return [
          for (final r in (rows as List))
            Product.fromSearch(Map<String, dynamic>.from(r as Map))
        ];
      }, 'Could not load items. Pull to retry.');

  /// Full listing with photos and owner (only visible if live, or yours /
  /// staff via row level security).
  Future<Product> listing(String id) => _run(() async {
        final r = Map<String, dynamic>.from(await c
            .from('listings')
            .select('*, listing_images(path, sort_order)')
            .eq('id', id)
            .single());
        // The owner comes from the public profile view in a second query:
        // PostgREST cannot embed a view through the listings foreign key.
        try {
          final o = await c
              .from('public_profiles')
              .select('first_name,last_name,avatar_url,verification_status')
              .eq('id', r['owner_id'] as String)
              .maybeSingle();
          if (o != null) r['public_profiles'] = o;
        } catch (_) {}
        return Product.fromListing(r);
      }, 'This item isn’t available.');

  /// Whether I asked to be told when this item is free again.
  Future<bool> isWatching(String listingId) async {
    try {
      final r = await c
          .from('listing_watches')
          .select('listing_id')
          .eq('listing_id', listingId)
          .isFilter('notified_at', null)
          .maybeSingle();
      return r != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> watchListing(String listingId, bool on) => _run(() async {
        await c
            .rpc('watch_listing', params: {'p_listing': listingId, 'p_on': on});
      }, 'Could not update this alert. Please try again.');

  /// Top-level item categories shown on Home.
  Future<List<Category>> categories() => _run(() async {
        final rows = await c
            .from('categories')
            .select('id, slug, label, kind')
            .isFilter('parent_id', null)
            .eq('is_active', true)
            .order('sort_order');
        return [
          for (final r in rows)
            Category(
              id: r['slug'] as String,
              label: r['label'] as String,
              kind: r['kind'] as String,
              icon: _categoryIcon(r['slug'] as String),
            )
        ];
      });

  String? _categoryIcon(String slug) {
    const m = {
      'electronics-appliances': 'assets/images/categories/electronics.png',
      'fashion-style': 'assets/images/categories/fashion.png',
      'furniture': 'assets/images/categories/furniture.png',
      'tools-equipment': 'assets/images/categories/tools.png',
      'photography-media': 'assets/images/categories/media.png',
      'mobile-gadgets': 'assets/images/categories/media.png',
      'kitchenware': 'assets/images/categories/appliances.png',
      'services': 'assets/images/categories/services.png',
    };
    return m[slug];
  }

  /// Service kinds (Plumber, Electrician, ...) as tiles.
  Future<List<ServiceItem>> serviceCategories() => _run(() async {
        final rows = await c
            .from('categories')
            .select('id, label, slug')
            .eq('kind', 'service')
            .not('parent_id', 'is', null)
            .eq('is_active', true)
            .order('sort_order');
        return [
          for (final r in rows)
            ServiceItem(
              id: r['slug'] as String,
              name: r['label'] as String,
              description:
                  'Find trusted ${(r['label'] as String).toLowerCase()} services near you.',
              image: '',
              categoryLabel: r['label'] as String,
            )
        ];
      });

  /// Open errands / tasks near the user.
  Future<List<ServiceItem>> tasks(
          {String query = '', int limit = 30, int offset = 0}) =>
      _run(() async {
        final rows = await c.rpc('search_tasks', params: {
          'p_q': query.trim(),
          'p_lat': currentProfile.lat,
          'p_lng': currentProfile.lng,
          'p_limit': limit,
          'p_offset': offset,
        });
        return [
          for (final r in (rows as List))
            ServiceItem.fromTaskSearch(Map<String, dynamic>.from(r as Map))
        ];
      });

  Future<Person> person(String id) => _run(() async {
        final r =
            await c.from('public_profiles').select().eq('id', id).single();
        return Person.fromPublic(Map<String, dynamic>.from(r));
      }, 'This profile isn’t available.');

  Future<List<Product>> listingsOf(String ownerId) => products(query: '')
      .then((all) => all.where((p) => p.ownerId == ownerId).toList());

  Future<List<Review>> reviewsForListing(String listingId) =>
      _reviews((q) => q.eq('listing_id', listingId));

  Future<List<Review>> reviewsForUser(String userId) =>
      _reviews((q) => q.eq('reviewee_id', userId));

  Future<List<Review>> _reviews(
          PostgrestFilterBuilder<PostgrestList> Function(
                  PostgrestFilterBuilder<PostgrestList>)
              where) =>
      _run(() async {
        final rows = await where(c
                .from('reviews')
                .select('rating, body, created_at, reviewer_id')
                .eq('status', 'published'))
            .order('created_at', ascending: false)
            .limit(30);
        final ids = {for (final r in rows) r['reviewer_id'] as String};
        final people = <String, Map<String, dynamic>>{};
        if (ids.isNotEmpty) {
          try {
            final ps = await c
                .from('public_profiles')
                .select('id,first_name,last_name,avatar_url')
                .inFilter('id', ids.toList());
            for (final p in ps) {
              people[p['id'] as String] = Map<String, dynamic>.from(p);
            }
          } catch (_) {}
        }
        return [
          for (final r in rows)
            _review({
              ...Map<String, dynamic>.from(r),
              'reviewer': people[r['reviewer_id']],
            })
        ];
      });

  Review _review(Map<String, dynamic> r) {
    final p = r['reviewer'];
    return Review(
      author: p is Map
          ? '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim()
          : 'Seculate user',
      avatar: p is Map ? (p['avatar_url'] ?? '') as String : '',
      rating: (r['rating'] as num).toInt(),
      text: (r['body'] ?? '') as String,
      time: timeLabel(DateTime.tryParse('${r['created_at']}')),
    );
  }

  // recent searches live on the device only
  Future<List<String>> recentSearches() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList('recent_searches_$uid') ?? const [];
  }

  Future<void> addRecentSearch(String term) async {
    final t = term.trim();
    if (t.isEmpty) return;
    final p = await SharedPreferences.getInstance();
    final l = List<String>.from(p.getStringList('recent_searches_$uid') ?? []);
    l.removeWhere((e) => e.toLowerCase() == t.toLowerCase());
    l.insert(0, t);
    await p.setStringList('recent_searches_$uid', l.take(12).toList());
  }

  Future<void> clearRecentSearches() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('recent_searches_$uid');
  }

  // ───────────────────────── my listings & posting ─────────────────────────

  Future<List<Product>> myListings() => _run(() async {
        final rows = await c
            .from('listings')
            .select('*, listing_images(path, sort_order)')
            .eq('owner_id', uid)
            .neq('status', 'archived')
            .order('created_at', ascending: false);
        return [
          for (final r in rows)
            Product.fromListing(Map<String, dynamic>.from(r))
        ];
      });

  Future<List<ServiceItem>> myTasks() => _run(() async {
        final rows = await c
            .from('tasks')
            .select()
            .eq('requester_id', uid)
            .neq('status', 'cancelled')
            .order('created_at', ascending: false);
        return [
          for (final r in rows)
            ServiceItem.fromTask(Map<String, dynamic>.from(r))
        ];
      });

  Future<Map<String, dynamic>> planStatus() => _run(() async {
        final r = await c.rpc('my_plan_status');
        return Map<String, dynamic>.from(r as Map);
      });

  Future<List<Plan>> plans() => _run(() async {
        final rows = await c
            .from('subscription_plans')
            .select()
            .eq('is_active', true)
            .order('sort_order');
        return [
          for (final r in rows) Plan.fromRow(Map<String, dynamic>.from(r))
        ];
      });

  /// Creates the listing, uploads photos and submits it for admin review.
  /// It stays hidden from everyone else until an admin approves it.
  /// Returns the listing id.
  Future<String> createListing(ListingDraft d, {String? editingId}) =>
      _run(() async {
        final base = {
          'kind': d.kind,
          'title': d.title.trim(),
          'description': d.description.trim(),
          'category_label': d.categoryLabel,
          'sub_category': d.subCategory,
          'price_per_day': d.pricePerDay,
          'collateral': d.collateral,
          'security_fee': d.securityFee,
          'min_days': d.minDays,
          'max_days': d.maxDays,
          'stock': d.stock,
          'lending_period': d.lendingPeriod,
          'availability': d.availability,
          'delivery_option': d.deliveryOption,
          'location_label': d.locationLabel ?? currentProfile.city,
          'features': d.features,
          'lat': currentProfile.lat,
          'lng': currentProfile.lng,
        };
        String id;
        if (editingId == null) {
          final r = await c
              .from('listings')
              .insert({...base, 'owner_id': uid})
              .select('id')
              .single();
          id = r['id'] as String;
        } else {
          id = editingId;
          await c.from('listings').update(base).eq('id', id);
        }
        var n = 0;
        for (final path in d.photos) {
          final bytes = await File(path).readAsBytes();
          final ext = path.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
          final key =
              '$uid/$id/${DateTime.now().millisecondsSinceEpoch}_$n.$ext';
          await c.storage.from('listing-images').uploadBinary(key, bytes,
              fileOptions: FileOptions(
                  contentType: ext == 'png' ? 'image/png' : 'image/jpeg'));
          await c
              .from('listing_images')
              .insert({'listing_id': id, 'path': key, 'sort_order': n});
          n++;
        }
        await c.rpc('submit_listing', params: {'p_id': id});
        return id;
      }, 'Could not submit your listing.');

  /// Removes one of my own listings. Done by the database (a live listing
  /// cannot be edited directly by its owner), which also refuses when a
  /// deal is still in progress.
  Future<void> archiveListing(String id) => _run(() async {
        await c.rpc('archive_listing', params: {'p_id': id});
      }, 'Could not delete this listing. Please try again.');

  Future<String> createTask({
    required String title,
    required String description,
    required String categoryLabel,
    int? proposedPrice,
    String? locationLabel,
    DateTime? neededBy,
  }) =>
      _run(() async {
        final r = await c
            .from('tasks')
            .insert({
              'requester_id': uid,
              'title': title.trim(),
              'description': description.trim(),
              'category_label': categoryLabel,
              'proposed_price': proposedPrice,
              'location_label': locationLabel ?? currentProfile.city,
              'lat': currentProfile.lat,
              'lng': currentProfile.lng,
              'needed_by': neededBy?.toUtc().toIso8601String(),
            })
            .select('id')
            .single();
        final id = r['id'] as String;
        await c.rpc('submit_task', params: {'p_id': id});
        return id;
      }, 'Could not submit your request.');

  // ───────────────────────── chat ─────────────────────────

  Future<List<Conversation>> conversations() => _run(() async {
        final rows = await c.rpc('my_conversations');
        return [
          for (final r in (rows as List))
            Conversation.fromRow(Map<String, dynamic>.from(r as Map))
        ];
      }, 'Could not load your chats.');

  Future<String> startConversation(String otherId,
          {String? listingId, String? taskId}) =>
      _run(() async {
        final r = await c.rpc('start_conversation', params: {
          'p_other': otherId,
          'p_listing': listingId,
          'p_task': taskId
        });
        return r as String;
      }, 'Could not open the chat.');

  Future<List<ChatMessage>> messages(String conversationId) => _run(() async {
        final rows = await c
            .from('messages')
            .select()
            .eq('conversation_id', conversationId)
            .eq('hidden', false)
            .order('created_at')
            .limit(200);
        return [
          for (final r in rows)
            ChatMessage.fromRow(Map<String, dynamic>.from(r), uid)
        ];
      }, 'Could not load messages.');

  /// Live new messages for a conversation (Supabase Realtime).
  /// Cancel the subscription to leave the channel.
  Stream<ChatMessage> incomingMessages(String conversationId) {
    final ctrl = StreamController<ChatMessage>();
    final ch = c.channel('chat:$conversationId').onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'conversation_id',
              value: conversationId),
          callback: (p) {
            if (p.newRecord['hidden'] == true) return;
            ctrl.add(ChatMessage.fromRow(
                Map<String, dynamic>.from(p.newRecord), uid));
          },
        )..subscribe();
    ctrl.onCancel = () async {
      await c.removeChannel(ch);
      await ctrl.close();
    };
    return ctrl.stream;
  }

  /// Sends a text message. The server scans it for phone numbers, bank
  /// details, off-platform payment requests and abuse, and may block it or
  /// record a violation.
  Future<SendResult> sendMessage(String conversationId, String body) async {
    try {
      final r = await c
          .rpc('chat_send', params: {'p_conv': conversationId, 'p_body': body});
      final m = Map<String, dynamic>.from(r as Map);
      return SendResult(
        ok: m['ok'] == true,
        blocked: m['blocked'] == true,
        error: m['error'] as String?,
        flagged: m['flagged'] == true,
        id: m['id'] as String?,
      );
    } catch (e) {
      final err = _fail(e, 'Message not sent. Try again.');
      return SendResult(ok: false, error: err.message);
    }
  }

  Future<SendResult> sendImage(String conversationId, String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      if (bytes.length > 6 * 1024 * 1024) {
        return const SendResult(
            ok: false, error: 'Photo is too large (max 6 MB).');
      }
      final key =
          '$conversationId/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await c.storage.from('chat-attachments').uploadBinary(key, bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'));
      final r = await c.rpc('chat_send', params: {
        'p_conv': conversationId,
        'p_body': '',
        'p_kind': 'image',
        'p_attachment': key
      });
      final m = Map<String, dynamic>.from(r as Map);
      return SendResult(
          ok: m['ok'] == true,
          error: m['error'] as String?,
          id: m['id'] as String?);
    } catch (e) {
      return SendResult(
          ok: false, error: _fail(e, 'Photo not sent. Try again.').message);
    }
  }

  /// Private chat photos need a short-lived signed link.
  Future<String?> chatImageUrl(String path) async {
    try {
      return await c.storage
          .from('chat-attachments')
          .createSignedUrl(path, 3600);
    } catch (_) {
      return null;
    }
  }

  Future<void> markRead(String conversationId) async {
    try {
      await c.rpc('mark_conversation_read', params: {'p_conv': conversationId});
    } catch (_) {}
  }

  Future<void> reportMessage(String messageId, String reason) =>
      _run(() async => c.rpc('report_message',
          params: {'p_message': messageId, 'p_reason': reason}));

  Future<void> blockUser(String userId) => _run(() async {
        await c
            .from('user_blocks')
            .upsert({'blocker_id': uid, 'blocked_id': userId});
      });

  Future<void> reportUser(String userId, String reason, {String? details}) =>
      _run(() async {
        await c.from('reports').insert({
          'reporter_id': uid,
          'target_type': 'user',
          'target_id': userId,
          'reason': reason,
          'details': details,
        });
      });

  Future<void> reportListing(String listingId, String reason,
          {String? details}) =>
      _run(() async {
        await c.from('reports').insert({
          'reporter_id': uid,
          'target_type': 'listing',
          'target_id': listingId,
          'reason': reason,
          'details': details,
        });
      });

  // ───────────────────────── transactions ─────────────────────────

  /// Asks to borrow an item. Creates the chat + request message. The lender
  /// must accept before any payment is possible.
  Future<String> requestBorrow(String listingId, int days,
          {DateTime? start, String? note}) =>
      _run(() async {
        final r = await c.rpc('request_borrow', params: {
          'p_listing': listingId,
          'p_days': days,
          if (start != null)
            'p_start': start.toIso8601String().substring(0, 10),
          'p_note': note,
        });
        return r as String;
      }, 'Could not send your request.');

  Future<void> respondRequest(String txId, bool accept, {String? reason}) =>
      _run(() async {
        await c.rpc('respond_request',
            params: {'p_tx': txId, 'p_accept': accept, 'p_reason': reason});
      });

  Future<void> cancelTransaction(String txId, {String? reason}) =>
      _run(() async {
        await c.rpc('cancel_transaction',
            params: {'p_tx': txId, 'p_reason': reason});
      });

  Future<List<Txn>> myTransactions() => _run(() async {
        final rows = await c
            .from('transactions')
            .select()
            .order('created_at', ascending: false)
            .limit(100);
        return [
          for (final r in rows) Txn.fromRow(Map<String, dynamic>.from(r))
        ];
      });

  Future<Txn> transaction(String id) async {
    var t = await _run(() async {
      final r = await c.from('transactions').select().eq('id', id).single();
      return Txn.fromRow(Map<String, dynamic>.from(r));
    });
    // While waiting for payment, ask the server to confirm it with the provider.
    if (t.state == 'payment_pending') {
      final s = await syncEscrowPayment(id);
      if (s != null && s != t.state) {
        t = await _run(() async {
          final r = await c.from('transactions').select().eq('id', id).single();
          return Txn.fromRow(Map<String, dynamic>.from(r));
        });
      }
    }
    return t;
  }

  Stream<Txn> watchTransaction(String id) {
    final ctrl = StreamController<Txn>();
    final ch = c.channel('tx:$id').onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'transactions',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq, column: 'id', value: id),
          callback: (p) =>
              ctrl.add(Txn.fromRow(Map<String, dynamic>.from(p.newRecord))),
        )..subscribe();
    ctrl.onCancel = () async {
      await c.removeChannel(ch);
      await ctrl.close();
    };
    return ctrl.stream;
  }

  /// Starts a Flutterwave checkout for the escrow payment. Returns the
  /// hosted payment link to open in the browser. The amount is computed on
  /// the server from the transaction, never taken from the app.
  Future<String> startEscrowPayment(String txId) async {
    final d =
        await fn('payment-init', {'purpose': 'escrow', 'transaction_id': txId});
    final link = d['link'];
    if (link is String && link.isNotEmpty) return link;
    throw BackendError('Payment is not available right now.');
  }

  /// Starts a plan purchase checkout. Returns the hosted payment link.
  Future<String> startPlanPayment(String planId) async {
    final d = await fn(
        'payment-init', {'purpose': 'subscription', 'plan_id': planId});
    final link = d['link'];
    if (link is String && link.isNotEmpty) return link;
    throw BackendError('Payment is not available right now.');
  }

  /// Asks the server to look up a just-paid plan checkout (fallback if the
  /// provider's webhook is delayed). Returns true if a plan was applied.
  Future<bool> syncPlanPayment() async {
    try {
      final d = await fn('payment-init', {'purpose': 'subscription_sync'});
      return d['applied'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Asks the server to check with the escrow provider whether the payment
  /// arrived. Safe to call repeatedly; the server validates the amount.
  Future<String?> syncEscrowPayment(String txId) async {
    try {
      final d = await fn('escrow-sync', {'transaction_id': txId});
      return d['state'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> startFulfilment(String txId,
          {String condition = 'good',
          String? notes,
          List<String> photos = const []}) =>
      _run(() async {
        final keys = await _uploadAll('condition-photos', txId, photos);
        await c.rpc('start_fulfilment', params: {
          'p_tx': txId,
          'p_condition': condition,
          'p_notes': notes,
          'p_photos': keys
        });
      });

  Future<void> submitReturn(String txId,
          {String condition = 'good',
          String? notes,
          List<String> photos = const []}) =>
      _run(() async {
        final keys = await _uploadAll('condition-photos', txId, photos);
        await c.rpc('submit_return', params: {
          'p_tx': txId,
          'p_condition': condition,
          'p_notes': notes,
          'p_photos': keys
        });
      });

  Future<void> confirmReturn(String txId, bool ok, {String? notes}) =>
      _run(() async {
        await c.rpc('confirm_return',
            params: {'p_tx': txId, 'p_ok': ok, 'p_notes': notes});
      });

  Future<void> openDispute(String txId, String reason) => _run(() async {
        await c.rpc('open_dispute', params: {'p_tx': txId, 'p_reason': reason});
      });

  Future<void> createReview(String txId, int rating, {String? body}) =>
      _run(() async {
        await c.rpc('create_review',
            params: {'p_tx': txId, 'p_rating': rating, 'p_body': body});
      });

  /// Uploads photos for a deal to `<txId>/<uid>/...` (the only layout the
  /// storage policy accepts). Returns the storage keys.
  Future<List<String>> uploadTxPhotos(String txId, List<String> paths) =>
      _run(() => _uploadAll('condition-photos', txId, paths));

  Future<List<String>> _uploadAll(
      String bucket, String folder, List<String> paths) async {
    final keys = <String>[];
    var n = 0;
    for (final p in paths) {
      final bytes = await File(p).readAsBytes();
      final key =
          '$folder/$uid/${DateTime.now().millisecondsSinceEpoch}_${n++}.jpg';
      await c.storage.from(bucket).uploadBinary(key, bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'));
      keys.add(key);
    }
    return keys;
  }

  // counter-offers (errands / tasks)
  Future<String> makeTaskOffer(String taskId, int amount, {String? note}) =>
      _run(() async {
        final r = await c.rpc('make_task_offer',
            params: {'p_task': taskId, 'p_amount': amount, 'p_note': note});
        return r as String;
      });

  /// action: accept | reject | counter (counter needs [counter] amount).
  Future<void> respondOffer(String offerId, String action, {int? counter}) =>
      _run(() async {
        await c.rpc('respond_offer', params: {
          'p_offer': offerId,
          'p_action': action,
          'p_counter': counter
        });
      });

  Future<List<Offer>> offersForTask(String taskId) => _run(() async {
        final rows = await c
            .from('offers')
            .select()
            .eq('task_id', taskId)
            .order('created_at');
        return [
          for (final r in rows) Offer.fromRow(Map<String, dynamic>.from(r))
        ];
      });

  // ───────────────────────── notifications ─────────────────────────

  Future<List<AppNotification>> notifications() => _run(() async {
        final rows = await c
            .from('notifications')
            .select()
            .order('created_at', ascending: false)
            .limit(100);
        return [
          for (final r in rows)
            AppNotification.fromRow(Map<String, dynamic>.from(r))
        ];
      }, 'Could not load notifications.');

  Future<int> unreadNotificationCount() async {
    try {
      final r = await c
          .from('notifications')
          .select('id')
          .isFilter('read_at', null)
          .limit(100);
      return (r as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markNotificationsRead() async {
    try {
      await c.from('notifications').update({
        'read_at': DateTime.now().toUtc().toIso8601String()
      }).isFilter('read_at', null);
    } catch (_) {}
  }

  /// Fires whenever a new notification arrives for the signed-in user.
  Stream<AppNotification> incomingNotifications() {
    final ctrl = StreamController<AppNotification>();
    final ch = c.channel('notif:$uid').onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq, column: 'user_id', value: uid),
          callback: (p) => ctrl.add(
              AppNotification.fromRow(Map<String, dynamic>.from(p.newRecord))),
        )..subscribe();
    ctrl.onCancel = () async {
      await c.removeChannel(ch);
      await ctrl.close();
    };
    return ctrl.stream;
  }

  // ───────────────────────── support ─────────────────────────

  Future<List<SupportTicket>> tickets() => _run(() async {
        final rows = await c
            .from('support_tickets')
            .select()
            .order('created_at', ascending: false);
        return [
          for (final r in rows)
            SupportTicket.fromRow(Map<String, dynamic>.from(r))
        ];
      });

  Future<String> createTicket(String subject, String body,
          {String category = 'general', String? txId}) =>
      _run(() async {
        final r = await c.rpc('create_ticket', params: {
          'p_subject': subject,
          'p_body': body,
          'p_category': category,
          'p_tx': txId
        });
        return r as String;
      }, 'Could not send your message.');

  Future<List<ChatMessage>> ticketMessages(String ticketId) => _run(() async {
        final rows = await c
            .from('support_messages')
            .select()
            .eq('ticket_id', ticketId)
            .eq('internal', false)
            .order('created_at');
        return [
          for (final r in rows)
            ChatMessage(
              id: r['id'] as String,
              text: (r['body'] ?? '') as String,
              mine: r['is_staff'] != true,
              time: timeLabel(DateTime.tryParse('${r['created_at']}')),
              createdAt: DateTime.tryParse('${r['created_at']}'),
            )
        ];
      });

  Future<void> replyTicket(String ticketId, String body) => _run(() async {
        await c.rpc('reply_ticket',
            params: {'p_ticket': ticketId, 'p_body': body});
      });

  // ───────────────────────── account ─────────────────────────

  Future<String?> uploadAvatar(String filePath) => _run(() async {
        final Uint8List bytes = await File(filePath).readAsBytes();
        final key = '$uid/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await c.storage.from('avatars').uploadBinary(key, bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'));
        final url = c.storage.from('avatars').getPublicUrl(key);
        await c.from('profiles').update({'avatar_url': url}).eq('id', uid);
        currentProfile.avatarUrl = url;
        return url;
      }, 'Could not upload your photo.');

  /// Starts deactivation. Records are retained by policy; the account is
  /// closed after the grace review.
  Future<void> requestAccountDeletion({String? reason}) => _run(() async {
        await c.rpc('request_account_deletion', params: {'p_reason': reason});
      });

  Future<void> registerPushToken(String token, String platform) async {
    try {
      await c
          .from('push_tokens')
          .upsert({'user_id': uid, 'token': token, 'platform': platform});
    } catch (_) {}
  }

  Future<void> signOut() async {
    await AuthService.instance.signOut();
    currentProfile.clear();
  }
}

/// The app-wide instance. Tests assign a fake subclass.
Backend backend = Backend();
