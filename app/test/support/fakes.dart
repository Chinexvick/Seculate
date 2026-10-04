import 'dart:async';

import 'package:seculate/data/auth_service.dart';
import 'package:seculate/data/backend.dart';
import 'package:seculate/data/models.dart';
import 'package:seculate/data/user_profile.dart';

/// Test-only fixtures (these used to be the app's mock data).
const _owner = Person(
    id: 'owner-1',
    name: 'Jacob Jones',
    verified: true,
    ratingAvg: 4.6,
    ratingCount: 12,
    city: 'Yaba, Lagos',
    completedTransactions: 9,
    successfulReturns: 9);

final fixtureProducts = <Product>[
  const Product(
      id: 'p1',
      name: 'Bowowert Toaster 2000',
      location: 'Yaba, Lagos',
      availability: '1 Week Available',
      collateral: 2000,
      rating: 4.8,
      image: '',
      description: 'A compact and efficient toaster.',
      features: ['2-slice capacity', 'Auto pop-up'],
      inStock: 2,
      ownerId: 'owner-1',
      ownerName: 'Jacob Jones',
      ownerVerified: true,
      pricePerDay: 500,
      reviewCount: 3,
      categoryLabel: 'Electronics & Appliances'),
  const Product(
      id: 'p2',
      name: 'Samsung 43” Smart LED TV',
      location: 'Surulere, Lagos',
      availability: '1 month Available',
      collateral: 10000,
      rating: 4.1,
      image: '',
      ownerId: 'owner-2',
      ownerName: 'Ada Obi',
      pricePerDay: 3000,
      distanceKm: 2.4),
];

final fixtureTasks = <ServiceItem>[
  const ServiceItem(
      id: 't1',
      name: 'Pick up a parcel from Ikeja',
      description: 'Need someone to collect a small parcel.',
      image: '',
      price: 3500,
      location: 'Ikeja, Lagos',
      posterId: 'owner-2',
      posterName: 'Ada Obi'),
];

class FakeAuth extends AuthService {
  FakeAuth({this.accept = '123456'});
  final String accept;
  final sent = <String>[];
  @override
  bool get signedIn => true;
  @override
  Future<String> onboardingStep() async => 'done';
  @override
  Future<OtpSendResult> sendOtp(String email, OtpPurpose purpose) async {
    sent.add('$email:${purpose.name}');
    return const OtpSendResult();
  }

  @override
  Future<bool> verifyOtp(String email, String code, OtpPurpose purpose) async {
    if (code != accept)
      throw AuthFailure('That code is invalid or has expired.');
    return true;
  }
}

class FakeBackend extends Backend {
  @override
  String get uid => 'me';

  @override
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
  }) async =>
      fixtureProducts
          .where((p) =>
              query.isEmpty ||
              p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();

  @override
  Future<Product> listing(String id) async =>
      fixtureProducts.firstWhere((p) => p.id == id);

  @override
  Future<List<Category>> categories() async => const [
        Category(
            id: 'electronics-appliances', label: 'Electronics & Appliances'),
        Category(id: 'fashion-style', label: 'Fashion & Style'),
        Category(id: 'furniture', label: 'Furniture'),
      ];

  @override
  Future<List<ServiceItem>> serviceCategories() async => const [
        ServiceItem(
            id: 'plumber',
            name: 'Plumber',
            description: 'Find plumbers',
            image: ''),
      ];

  @override
  Future<List<ServiceItem>> tasks(
          {String query = '', int limit = 30, int offset = 0}) async =>
      fixtureTasks;

  @override
  Future<Person> person(String id) async => _owner;

  @override
  Future<List<Product>> listingsOf(String ownerId) async => fixtureProducts;

  @override
  Future<List<Review>> reviewsForListing(String listingId) async => const [
        Review(
            author: 'Chinelo Adebayo',
            avatar: '',
            rating: 4,
            text: 'Works great.',
            time: '9:30AM'),
      ];

  @override
  Future<List<Review>> reviewsForUser(String userId) => reviewsForListing('');

  @override
  Future<List<String>> recentSearches() async => ['Fridge', 'Blender'];
  @override
  Future<void> addRecentSearch(String term) async {}
  @override
  Future<void> clearRecentSearches() async {}

  @override
  Future<List<Product>> myListings() async => [
        fixtureProducts.first,
        const Product(
            id: 'p9',
            name: 'Pending drill',
            location: 'Yaba',
            availability: '',
            collateral: 0,
            rating: 0,
            image: '',
            status: 'pending_review'),
        const Product(
            id: 'p10',
            name: 'Rejected lamp',
            location: 'Yaba',
            availability: '',
            collateral: 0,
            rating: 0,
            image: '',
            status: 'rejected',
            reviewNote: 'Photos are unclear.'),
      ];

  @override
  Future<List<ServiceItem>> myTasks() async => const [];

  @override
  Future<Map<String, dynamic>> planStatus() async => {
        'plan': {'id': 'on_code', 'name': 'On Code', 'item_limit_per_month': 3},
        'used_this_month': 1,
        'period_end': null,
        'status': 'active',
      };

  @override
  Future<List<Plan>> plans() async => const [
        Plan(
            id: 'on_code',
            name: 'On Code',
            emoji: '🔰',
            price: 0,
            perks: ['Item Limit: List up to 3 items/month']),
        Plan(
            id: 'active',
            name: 'Active',
            emoji: '✅',
            price: 500,
            perks: ['Item Limit: List up to 5 items/month']),
        Plan(
            id: 'hustler',
            name: 'Hustler',
            emoji: '🚀',
            price: 1500,
            perks: ['Item Limit: List up to 10 items/month']),
        Plan(
            id: 'top_lender',
            name: 'Top Lender',
            emoji: '👑',
            price: 5000,
            perks: ['Item Limit: Unlimited']),
      ];

  @override
  Future<List<Conversation>> conversations() async => const [
        Conversation(
            id: 'c1',
            person: Person(id: 'u2', name: 'Chijioke Okafor'),
            lastMessage: 'Request item',
            time: '9:33AM',
            unread: 1,
            isRequest: true),
        Conversation(
            id: 'c2',
            person: Person(id: 'u3', name: 'Chinelo Okafor', verified: true),
            lastMessage: 'Thank you for the item.',
            time: 'Yesterday'),
      ];

  @override
  Future<String> startConversation(String otherId,
          {String? listingId, String? taskId}) async =>
      'c1';

  @override
  Future<List<ChatMessage>> messages(String conversationId) async => [
        const ChatMessage(
            id: 'm1',
            text: 'Hi, is this item still available?',
            mine: true,
            time: '9:30AM'),
        const ChatMessage(
            id: 'm2', text: 'Yes it is.', mine: false, time: '9:31AM'),
      ];

  @override
  Stream<ChatMessage> incomingMessages(String conversationId) =>
      const Stream.empty();

  @override
  Future<SendResult> sendMessage(String conversationId, String body) async {
    if (RegExp(r'\d{9,}').hasMatch(body)) {
      return const SendResult(
          ok: false,
          blocked: true,
          error: 'For your safety, phone numbers can’t be shared in chat.');
    }
    return const SendResult(ok: true, id: 'new');
  }

  @override
  Future<void> markRead(String conversationId) async {}

  @override
  Future<List<AppNotification>> notifications() async => const [
        AppNotification(
            id: 'n1',
            kind: NotificationKind.message,
            title: 'New message',
            body: 'Monday James sent you a message',
            time: '9:33AM'),
        AppNotification(
            id: 'n2',
            kind: NotificationKind.rejected,
            title: 'Listing needs changes',
            body: 'Your listing needs changes',
            time: '9:33AM',
            isNew: false),
      ];

  @override
  Future<int> unreadNotificationCount() async => 1;
  @override
  Future<void> markNotificationsRead() async {}
  @override
  Stream<AppNotification> incomingNotifications() => const Stream.empty();

  @override
  Future<List<SupportTicket>> tickets() async => const [];
  @override
  Future<List<ChatMessage>> ticketMessages(String ticketId) async => const [];

  @override
  Future<List<Txn>> myTransactions() async => [_tx];

  @override
  Future<Txn> transaction(String id) async => _tx;

  @override
  Stream<Txn> watchTransaction(String id) => const Stream.empty();

  @override
  Future<List<Offer>> offersForTask(String taskId) async => const [];

  @override
  Future<String> startEscrowPayment(String txId) async =>
      throw BackendError('Payments aren’t switched on yet.',
          code: 'not_configured');

  static const _tx = Txn(
      id: 'tx1',
      kind: 'borrow',
      title: 'Bowowert Toaster 2000',
      state: 'payment_pending',
      amount: 3500,
      collateral: 2000,
      payerId: 'me',
      payeeId: 'owner-1',
      rentalDays: 7);
}

/// Sets up the globals the screens read.
void installFakes({FakeAuth? auth}) {
  backend = FakeBackend();
  AuthService.instance = auth ?? FakeAuth();
  currentProfile
    ..clear()
    ..id = 'me'
    ..firstName = 'Bright'
    ..lastName = 'Moses'
    ..email = 'bright@example.com'
    ..lat = 6.5
    ..lng = 3.4;
}
