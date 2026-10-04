import '../core/supabase/supabase_config.dart';

/// Public URL for a file in a public storage bucket.
String publicUrl(String bucket, String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http') || path.startsWith('assets/')) return path;
  return SupabaseConfig.client.storage.from(bucket).getPublicUrl(path);
}

num _n(dynamic v) => v is num ? v : (num.tryParse('${v ?? 0}') ?? 0);

/// Plain data models built from server rows; the UI only depends on these.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.location,
    required this.availability,
    required this.collateral,
    required this.rating,
    required this.image,
    this.categories = const [],
    this.categoryLabel = 'Electronics & Appliances',
    this.description = '',
    this.features = const [],
    this.inStock = 1,
    this.reviewCount = 0,
    this.images = const [],
    this.ownerId = '',
    this.ownerName = '',
    this.ownerAvatar,
    this.ownerVerified = false,
    this.pricePerDay = 0,
    this.kind = 'item',
    this.status = 'live',
    this.reviewNote,
    this.distanceKm,
    this.featured = false,
    this.subCategory,
    this.deliveryOption,
    this.lendingPeriod,
    this.securityFee = 0,
    this.minDays,
    this.maxDays,
  });

  /// Builds a card from a `search_listings` row.
  factory Product.fromSearch(Map<String, dynamic> r) {
    final img = publicUrl('listing-images', r['image_path'] as String?);
    return Product(
      id: r['id'] as String,
      name: (r['title'] ?? '') as String,
      location: (r['location_label'] ?? '') as String,
      availability: (r['availability'] ?? '') as String,
      collateral: _n(r['collateral']).toInt(),
      rating: _n(r['rating_avg']).toDouble(),
      reviewCount: _n(r['rating_count']).toInt(),
      image: img,
      images: img.isEmpty ? const [] : [img],
      categoryLabel: (r['category_label'] ?? '') as String,
      subCategory: r['sub_category'] as String?,
      description: (r['description'] ?? '') as String,
      features: List<String>.from((r['features'] as List?) ?? const []),
      inStock: _n(r['stock']).toInt(),
      ownerId: (r['owner_id'] ?? '') as String,
      ownerName: (r['owner_name'] ?? '') as String,
      ownerAvatar: r['owner_avatar'] as String?,
      ownerVerified: r['owner_verified'] == true,
      pricePerDay: _n(r['price_per_day']).toInt(),
      kind: (r['kind'] ?? 'item') as String,
      distanceKm: (r['distance_km'] as num?)?.toDouble(),
      featured: r['featured'] == true,
      lendingPeriod: r['lending_period'] as String?,
    );
  }

  /// Builds from a `listings` row (optionally with embedded listing_images).
  factory Product.fromListing(Map<String, dynamic> r) {
    final imgs = <String>[
      for (final i
          in ((r['listing_images'] as List?) ?? const [])
              .cast<Map<String, dynamic>>()
            ..sort(
                (a, b) => _n(a['sort_order']).compareTo(_n(b['sort_order']))))
        publicUrl('listing-images', i['path'] as String?)
    ];
    final p = r['profiles'] ?? r['public_profiles'];
    return Product(
      id: r['id'] as String,
      name: (r['title'] ?? '') as String,
      location: (r['location_label'] ?? '') as String,
      availability: (r['availability'] ?? '') as String,
      collateral: _n(r['collateral']).toInt(),
      rating: _n(r['rating_avg']).toDouble(),
      reviewCount: _n(r['rating_count']).toInt(),
      image: imgs.isEmpty ? '' : imgs.first,
      images: imgs,
      categoryLabel: (r['category_label'] ?? '') as String,
      subCategory: r['sub_category'] as String?,
      description: (r['description'] ?? '') as String,
      features: List<String>.from((r['features'] as List?) ?? const []),
      inStock: _n(r['stock']).toInt(),
      ownerId: (r['owner_id'] ?? '') as String,
      ownerName: p is Map
          ? '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim()
          : '',
      ownerAvatar: p is Map ? p['avatar_url'] as String? : null,
      ownerVerified: p is Map && p['verification_status'] == 'verified',
      pricePerDay: _n(r['price_per_day']).toInt(),
      kind: (r['kind'] ?? 'item') as String,
      status: (r['status'] ?? 'live') as String,
      reviewNote: r['review_note'] as String?,
      deliveryOption: r['delivery_option'] as String?,
      lendingPeriod: r['lending_period'] as String?,
      securityFee: _n(r['security_fee']).toInt(),
      minDays: (r['min_days'] as num?)?.toInt(),
      maxDays: (r['max_days'] as num?)?.toInt(),
    );
  }

  final List<String> images;
  final String ownerId;
  final String ownerName;
  final String? ownerAvatar;
  final bool ownerVerified;
  final int pricePerDay;

  /// 'item' or 'service'.
  final String kind;

  /// draft / pending_review / changes_requested / live / rejected ...
  final String status;
  final String? reviewNote;
  final double? distanceKm;
  final bool featured;
  final String? subCategory;
  final String? deliveryOption;
  final String? lendingPeriod;

  /// Non-refundable fee the lender charges once per rental (₦).
  final int securityFee;

  /// Lender's rental limits in days (null = no limit).
  final int? minDays;
  final int? maxDays;

  bool get isLive => status == 'live' || status == 'reserved';

  String get priceLabel =>
      pricePerDay <= 0 ? '' : '₦${_money(pricePerDay)}/day';

  String get distanceLabel {
    final d = distanceKm;
    if (d == null) return '';
    return d < 1
        ? '${(d * 1000).round()} m away'
        : '${d.toStringAsFixed(1)} km away';
  }

  final String id;
  final String name;
  final String location;
  final String availability;
  final int collateral;
  final double rating;

  /// Category ids this item belongs to (see mock categories).
  final List<String> categories;

  final String categoryLabel;
  final String description;
  final List<String> features;
  final int inStock;
  final int reviewCount;

  /// Photos for the detail page.
  List<String> get gallery => images.isNotEmpty ? images : [image];

  /// Days the item can be borrowed for, parsed from [availability].
  int get availabilityDays {
    final m = RegExp(r'(\d+)\s*(day|week|month)', caseSensitive: false)
        .firstMatch(availability);
    if (m == null) return 0;
    final n = int.parse(m.group(1)!);
    switch (m.group(2)!.toLowerCase()) {
      case 'week':
        return n * 7;
      case 'month':
        return n * 30;
      default:
        return n;
    }
  }

  /// First photo (a network URL; empty when there is none).
  final String image;

  String get collateralLabel => '${_money(collateral)} Collateral';
}

String _money(num v) {
  final s = v.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// Public money formatting used across screens.
String naira(num v) => '₦${_money(v)}';

/// A service category tile, or a posted service/task.
class ServiceItem {
  const ServiceItem({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    this.price,
    this.location = '',
    this.posterId = '',
    this.posterName = '',
    this.posterAvatar,
    this.posterVerified = false,
    this.neededBy,
    this.distanceKm,
    this.status = 'live',
    this.reviewNote,
    this.categoryLabel = '',
  });

  factory ServiceItem.fromTaskSearch(Map<String, dynamic> r) => ServiceItem(
        id: r['id'] as String,
        name: (r['title'] ?? '') as String,
        description: (r['description'] ?? '') as String,
        image: '',
        price: r['proposed_price'] == null
            ? null
            : _n(r['proposed_price']).toInt(),
        location: (r['location_label'] ?? '') as String,
        posterId: (r['requester_id'] ?? '') as String,
        posterName: (r['requester_name'] ?? '') as String,
        posterAvatar: r['requester_avatar'] as String?,
        posterVerified: r['requester_verified'] == true,
        neededBy: r['needed_by'] == null
            ? null
            : DateTime.parse(r['needed_by'] as String).toLocal(),
        distanceKm: (r['distance_km'] as num?)?.toDouble(),
        categoryLabel: (r['category_label'] ?? '') as String,
      );

  factory ServiceItem.fromTask(Map<String, dynamic> r) => ServiceItem(
        id: r['id'] as String,
        name: (r['title'] ?? '') as String,
        description: (r['description'] ?? '') as String,
        image: '',
        price: r['proposed_price'] == null
            ? null
            : _n(r['proposed_price']).toInt(),
        location: (r['location_label'] ?? '') as String,
        posterId: (r['requester_id'] ?? '') as String,
        neededBy: r['needed_by'] == null
            ? null
            : DateTime.parse(r['needed_by'] as String).toLocal(),
        status: (r['status'] ?? '') as String,
        reviewNote: r['review_note'] as String?,
        categoryLabel: (r['category_label'] ?? '') as String,
      );

  final String id;
  final String name;
  final String description;
  final String image;
  final int? price;
  final String location;
  final String posterId;
  final String posterName;
  final String? posterAvatar;
  final bool posterVerified;
  final DateTime? neededBy;
  final double? distanceKm;
  final String status;
  final String? reviewNote;
  final String categoryLabel;
}

class Category {
  const Category(
      {required this.id,
      required this.label,
      this.icon,
      this.isAction = false,
      this.kind = 'item'});

  final String id;
  final String label;

  /// Asset path (png or svg).
  final String? icon;

  /// The orange "Post ad" tile.
  final bool isAction;
  final String kind;
}

enum NotificationKind { message, rejected, offer, success, failed }

String timeLabel(DateTime? t) {
  if (t == null) return '';
  final l = t.toLocal();
  final now = DateTime.now();
  final sameDay =
      l.year == now.year && l.month == now.month && l.day == now.day;
  var h = l.hour % 12;
  if (h == 0) h = 12;
  final m = l.minute.toString().padLeft(2, '0');
  final ap = l.hour < 12 ? 'AM' : 'PM';
  if (sameDay) return '$h:$m$ap';
  final y = now.subtract(const Duration(days: 1));
  if (l.year == y.year && l.month == y.month && l.day == y.day) {
    return 'Yesterday';
  }
  return '${l.day}/${l.month}/${l.year % 100}';
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.time,
    this.isNew = true,
    this.refType,
    this.refId,
    this.rawKind = '',
  });

  factory AppNotification.fromRow(Map<String, dynamic> r) {
    final k = (r['kind'] ?? '') as String;
    final NotificationKind kind;
    if (k.contains('message')) {
      kind = NotificationKind.message;
    } else if (k.contains('reject') ||
        k.contains('declin') ||
        k.contains('changes')) {
      kind = NotificationKind.rejected;
    } else if (k.contains('fail') ||
        k.contains('refund') ||
        k.contains('suspend') ||
        k.contains('dispute')) {
      kind = NotificationKind.failed;
    } else if (k.contains('request') || k.contains('offer')) {
      kind = NotificationKind.offer;
    } else {
      kind = NotificationKind.success;
    }
    return AppNotification(
      id: r['id'] as String,
      kind: kind,
      title: (r['title'] ?? '') as String,
      body: (r['body'] ?? '') as String,
      time: timeLabel(DateTime.tryParse('${r['created_at']}')),
      isNew: r['read_at'] == null,
      refType: r['ref_type'] as String?,
      refId: r['ref_id'] as String?,
      rawKind: k,
    );
  }

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final String time;
  final bool isNew;
  final String? refType;
  final String? refId;
  final String rawKind;
}

class Person {
  const Person({
    required this.name,
    this.phone = '',
    this.avatar = '',
    this.verified = false,
    this.id = '',
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.city = '',
    this.bio = '',
    this.completedTransactions = 0,
    this.successfulReturns = 0,
    this.memberSince,
    this.trustBand = '',
    this.trustScore = 0,
  });

  factory Person.fromPublic(Map<String, dynamic> r) => Person(
        id: r['id'] as String,
        name: '${r['first_name'] ?? ''} ${r['last_name'] ?? ''}'.trim(),
        avatar: r['avatar_url'] as String? ?? '',
        verified: r['verification_status'] == 'verified',
        ratingAvg: _n(r['rating_avg']).toDouble(),
        ratingCount: _n(r['rating_count']).toInt(),
        city: (r['city'] ?? '') as String,
        bio: (r['bio'] ?? '') as String,
        completedTransactions: _n(r['completed_transactions']).toInt(),
        successfulReturns: _n(r['successful_returns']).toInt(),
        memberSince: DateTime.tryParse('${r['member_since']}'),
        trustBand: (r['trust_band'] ?? '') as String,
        trustScore: _n(r['trust_score']).toInt(),
      );

  final String id;
  final String name;

  /// Phone numbers are never shared between users (chat is the only channel).
  final String phone;
  final String avatar;
  final bool verified;
  final double ratingAvg;
  final int ratingCount;
  final String city;
  final String bio;
  final int completedTransactions;
  final int successfulReturns;
  final DateTime? memberSince;
  final String trustBand;
  final int trustScore;
}

class Review {
  const Review(
      {required this.author,
      required this.avatar,
      required this.rating,
      required this.text,
      this.time = ''});
  final String author;
  final String avatar;
  final int rating;
  final String text;
  final String time;
}

class Conversation {
  const Conversation({
    required this.id,
    required this.person,
    required this.lastMessage,
    required this.time,
    this.unread = 0,
    this.online = false,
    this.isRequest = false,
    this.listingId,
    this.taskId,
    this.transactionId,
  });

  factory Conversation.fromRow(Map<String, dynamic> r) {
    final kind = (r['last_kind'] ?? 'text') as String;
    return Conversation(
      id: r['conversation_id'] as String,
      person: Person(
        id: (r['other_id'] ?? '') as String,
        name: (r['other_name'] ?? 'Seculate user') as String,
        avatar: (r['other_avatar'] ?? '') as String,
        verified: r['other_verified'] == true,
      ),
      lastMessage: kind == 'borrow_request'
          ? 'Request item'
          : kind == 'image'
              ? 'Photo'
              : (r['last_body'] ?? '') as String,
      time: timeLabel(DateTime.tryParse('${r['last_at']}')),
      unread: _n(r['unread']).toInt(),
      isRequest: kind == 'borrow_request',
      listingId: r['listing_id'] as String?,
      taskId: r['task_id'] as String?,
      transactionId: r['transaction_id'] as String?,
    );
  }

  /// Last message is an incoming borrow request (shown in italics).
  final bool isRequest;
  final String id;
  final Person person;
  final String lastMessage;
  final String time;
  final int unread;
  final bool online;
  final String? listingId;
  final String? taskId;
  final String? transactionId;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    this.mine = true,
    this.product,
    this.cancelled = false,
    this.accepted = false,
    this.time = '',
    this.kind = 'text',
    this.refId,
    this.attachmentUrl,
    this.hidden = false,
    this.createdAt,
  });

  factory ChatMessage.fromRow(Map<String, dynamic> r, String me) => ChatMessage(
        id: r['id'] as String,
        text: (r['body'] ?? '') as String,
        mine: r['sender_id'] == me,
        kind: (r['kind'] ?? 'text') as String,
        refId: r['ref_id'] as String?,
        attachmentUrl: r['attachment_path'] as String?,
        hidden: r['hidden'] == true,
        createdAt: DateTime.tryParse('${r['created_at']}'),
        time: timeLabel(DateTime.tryParse('${r['created_at']}')),
      );

  final String id;
  final String text;
  final bool mine;

  /// text / image / borrow_request / offer / system.
  final String kind;
  final String? refId;
  final String? attachmentUrl;
  final bool hidden;
  final DateTime? createdAt;

  /// Set for "request to borrow" messages.
  final Product? product;
  final bool cancelled;

  /// The lender accepted this (incoming) borrow request.
  final bool accepted;
  final String time;

  ChatMessage copyWith({bool? cancelled, bool? accepted, Product? product}) =>
      ChatMessage(
        id: id,
        text: text,
        mine: mine,
        kind: kind,
        refId: refId,
        attachmentUrl: attachmentUrl,
        hidden: hidden,
        createdAt: createdAt,
        product: product ?? this.product,
        cancelled: cancelled ?? this.cancelled,
        accepted: accepted ?? this.accepted,
        time: time,
      );
}

/// Escrow-backed borrow / task transaction.
class Txn {
  const Txn({
    required this.id,
    required this.kind,
    required this.title,
    required this.state,
    required this.amount,
    required this.collateral,
    this.securityFee = 0,
    this.platformFee = 0,
    required this.payerId,
    required this.payeeId,
    this.listingId,
    this.taskId,
    this.conversationId,
    this.rentalDays = 0,
    this.startDate,
    this.dueDate,
    this.cancelReason,
    this.txRef,
    this.createdAt,
  });

  factory Txn.fromRow(Map<String, dynamic> r) => Txn(
        id: r['id'] as String,
        kind: (r['kind'] ?? 'borrow') as String,
        title: (r['title'] ?? '') as String,
        state: (r['state'] ?? '') as String,
        amount: _n(r['amount']).toInt(),
        collateral: _n(r['collateral']).toInt(),
        securityFee: _n(r['security_fee']).toInt(),
        platformFee: _n(r['platform_fee']).toInt(),
        payerId: (r['payer_id'] ?? '') as String,
        payeeId: (r['payee_id'] ?? '') as String,
        listingId: r['listing_id'] as String?,
        taskId: r['task_id'] as String?,
        conversationId: r['conversation_id'] as String?,
        rentalDays: _n(r['rental_days']).toInt(),
        startDate: DateTime.tryParse('${r['start_date']}'),
        dueDate: DateTime.tryParse('${r['due_date']}'),
        cancelReason: r['cancel_reason'] as String?,
        txRef: r['tx_ref'] as String?,
        createdAt: DateTime.tryParse('${r['created_at']}'),
      );

  final String id;

  /// 'borrow' or 'task'.
  final String kind;
  final String title;

  /// requested, accepted, payment_pending, escrow_held, active, return_pending,
  /// confirmed, release_pending, released, cancelled, disputed, refunded.
  final String state;
  final int amount;
  final int collateral;
  final int securityFee;
  final int platformFee;
  final String payerId;
  final String payeeId;
  final String? listingId;
  final String? taskId;
  final String? conversationId;
  final int rentalDays;
  final DateTime? startDate;
  final DateTime? dueDate;
  final String? cancelReason;
  final String? txRef;
  final DateTime? createdAt;

  int get total => amount + collateral + platformFee;

  String get stateLabel {
    switch (state) {
      case 'requested':
        return 'Awaiting response';
      case 'accepted':
      case 'payment_pending':
        return 'Awaiting payment';
      case 'escrow_held':
        return 'Payment secured in escrow';
      case 'active':
        return 'In progress';
      case 'return_pending':
        return 'Return pending';
      case 'confirmed':
      case 'release_pending':
        return 'Release pending approval';
      case 'released':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'disputed':
        return 'Under dispute';
      case 'refunded':
        return 'Refunded';
      default:
        return state;
    }
  }
}

class Offer {
  const Offer({
    required this.id,
    required this.fromUser,
    required this.toUser,
    required this.amount,
    required this.status,
    this.note,
    this.taskId,
    this.listingId,
    this.parentId,
    this.createdAt,
  });

  factory Offer.fromRow(Map<String, dynamic> r) => Offer(
        id: r['id'] as String,
        fromUser: (r['from_user'] ?? '') as String,
        toUser: (r['to_user'] ?? '') as String,
        amount: _n(r['amount']).toInt(),
        status: (r['status'] ?? '') as String,
        note: r['note'] as String?,
        taskId: r['task_id'] as String?,
        listingId: r['listing_id'] as String?,
        parentId: r['parent_offer_id'] as String?,
        createdAt: DateTime.tryParse('${r['created_at']}'),
      );

  final String id;
  final String fromUser;
  final String toUser;
  final int amount;

  /// pending / accepted / rejected / countered / expired.
  final String status;
  final String? note;
  final String? taskId;
  final String? listingId;
  final String? parentId;
  final DateTime? createdAt;
}

/// A subscription plan row.
class Plan {
  const Plan({
    required this.id,
    required this.name,
    required this.emoji,
    required this.price,
    required this.perks,
    this.itemLimit,
    this.durationDays,
  });

  factory Plan.fromRow(Map<String, dynamic> r) {
    final limit = r['item_limit_per_month'] as int?;
    final days = r['listing_duration_days'] as int?;
    final feats = (r['features'] is List)
        ? List<String>.from(r['features'] as List)
        : <String>[];
    final price = _n(r['price_ngn']).toInt();
    return Plan(
      id: r['id'] as String,
      name: (r['name'] ?? '') as String,
      emoji: (r['emoji'] ?? '') as String,
      price: price,
      itemLimit: limit,
      durationDays: days,
      perks: feats,
    );
  }

  final String id;
  final String name;
  final String emoji;
  final int price;
  final List<String> perks;
  final int? itemLimit;
  final int? durationDays;

  String get priceLabel => price == 0 ? '₦0 /month' : '${naira(price)} /month';
}

class SupportTicket {
  const SupportTicket(
      {required this.id,
      required this.subject,
      required this.status,
      required this.createdAt});
  factory SupportTicket.fromRow(Map<String, dynamic> r) => SupportTicket(
        id: r['id'] as String,
        subject: (r['subject'] ?? '') as String,
        status: (r['status'] ?? 'open') as String,
        createdAt: DateTime.tryParse('${r['created_at']}'),
      );
  final String id;
  final String subject;
  final String status;
  final DateTime? createdAt;
}
