/// A store address / delivery option with business hours.
class StoreInfo {
  StoreInfo({
    required this.name,
    required this.region,
    required this.address,
    this.from,
    this.to,
    this.days = const [],
  });
  final String name;
  final String region;
  final String address;
  final String? from;
  final String? to;
  final List<int> days;
}

/// The signed-in user's profile, cached in memory from the server
/// (see ProfileService.load). Nothing here is a mock value.
class UserProfile {
  String id = '';
  String firstName = '';
  String lastName = '';
  String location = '';
  String city = '';
  String birthday = '';
  String sex = '';
  String document = '';
  String phone = '';
  String email = '';
  String address = '';
  String addressDoc = '';
  String businessName = '';
  String about = '';
  String link = '';
  String storeName = '';
  String region = '';
  String? avatarUrl;
  double? lat;
  double? lng;
  String verificationStatus = 'unverified';
  double ratingAvg = 0;
  int ratingCount = 0;
  String accountStatus = 'active';
  bool mustChangePassword = false;

  bool phoneVerified = false;
  String language = 'English UK';
  bool chatEnabled = true;
  bool feedbackEnabled = true;
  final Map<String, bool> notifications = {
    'Hot deals and recommendation': true,
    'Info about your ads': true,
    'Premium pacakages': true,
    'your subscription': true,
    'Messages': true,
    'Feedback': true,
    'SMS info notification': true,
  };

  final List<StoreInfo> stores = [];
  final List<StoreInfo> deliveries = [];

  String get displayName => '$firstName $lastName'.trim();

  /// "Good morning", "Good afternoon" or "Good evening" for the local time.
  static String greeting([DateTime? now]) {
    final h = (now ?? DateTime.now()).hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void clear() {
    id = '';
    firstName = lastName = location = city = birthday = sex = '';
    document = phone = email = address = addressDoc = '';
    businessName = about = link = storeName = region = '';
    avatarUrl = null;
    lat = lng = null;
    verificationStatus = 'unverified';
    ratingAvg = 0;
    ratingCount = 0;
    phoneVerified = false;
    stores.clear();
    deliveries.clear();
  }
}

final UserProfile currentProfile = UserProfile();

const profileSexOptions = ['Male', 'Female'];
const profileDocumentOptions = [
  'NIN- ********456',
  'International passport',
];
const profileAddressDocOptions = [
  'Electricity bill',
  'Water bill',
  'Bank statement',
  'Tenancy agreement',
];
const profileCountries = ['Nigeria', 'Ghana', 'Kenya', 'South Africa'];
