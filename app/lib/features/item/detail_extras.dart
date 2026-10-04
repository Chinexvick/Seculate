import 'package:flutter/material.dart';
import '../../core/widgets/trust_badge.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_arrow.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/market_cards.dart';
import '../../core/widgets/radio_sheet.dart' show sheetShape;
import '../../core/widgets/state_views.dart';
import '../../data/backend.dart';
import '../../data/models.dart';
import '../../data/user_profile.dart';
import '../chat/chat_screen.dart';
import 'detail_sheets.dart';

TextStyle _t(double size, FontWeight w, Color c) => TextStyle(
    fontFamily: AppTheme.fontFamily, fontSize: size, fontWeight: w, color: c);

String _date(DateTime d) {
  const m = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

/// Service / errand detail. Other users can make an offer on a request;
/// counter-offers continue in chat and notifications.
class ServiceDetailScreen extends StatefulWidget {
  const ServiceDetailScreen({super.key, required this.service});
  final ServiceItem service;

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  bool _busy = false;

  ServiceItem get _s => widget.service;
  bool get _isTask => _s.posterId.isNotEmpty;
  bool get _isOwn => _isTask && _s.posterId == currentProfile.id;

  Person get _poster => Person(
        id: _s.posterId,
        name: _s.posterName.isEmpty ? 'Seculate user' : _s.posterName,
        avatar: _s.posterAvatar ?? '',
        verified: _s.posterVerified,
      );

  Future<void> _offer() async {
    if (_busy || _isOwn) return;
    final amount = await showAmountSheet(context,
        title: 'Make an offer', action: 'Send offer', initial: _s.price);
    if (amount == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await backend.makeTaskOffer(_s.id, amount);
      if (!mounted) return;
      AppToast.show(context, 'Offer sent');
      await _openChat();
    } on BackendError catch (e) {
      if (mounted) AppToast.show(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openChat() async {
    try {
      final id = await backend.startConversation(_s.posterId, taskId: _s.id);
      if (!mounted) return;
      await Navigator.of(context).pushNamed(Routes.chat,
          arguments: ChatArgs(_poster, conversationId: id, taskId: _s.id));
    } on BackendError catch (e) {
      if (mounted) AppToast.show(context, e.message);
    }
  }

  Future<void> _chat() async {
    if (_busy || _isOwn) return;
    setState(() => _busy = true);
    await _openChat();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 10),
            child: Row(children: [
              const SizedBox(width: 32, child: BackArrow()),
              const SizedBox(width: 10),
              Expanded(
                child: Text(s.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _t(18, FontWeight.w500, AppColors.black)),
              ),
            ]),
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
              children: [
                if (s.image.isNotEmpty) ...[
                  FadeSlideIn(
                    child: AppImage(s.image,
                        height: 200, width: double.infinity, radius: 12),
                  ),
                  const SizedBox(height: 18),
                ],
                Text(s.name, style: _t(20, FontWeight.w500, AppColors.black)),
                const SizedBox(height: 8),
                Text(s.description, style: AppText.body.copyWith(height: 1.6)),
                const SizedBox(height: 16),
                if (s.price != null)
                  _Row('assets/icons/naira.svg',
                      'Offered price: ${naira(s.price!)}'),
                if (s.location.isNotEmpty)
                  _Row(
                      'assets/icons/location.svg',
                      s.distanceKm == null
                          ? s.location
                          : '${s.location} · ${s.distanceKm! < 1 ? '${(s.distanceKm! * 1000).round()} m' : '${s.distanceKm!.toStringAsFixed(1)} km'} away'),
                if (s.neededBy != null)
                  _Row('assets/icons/d_calendar.svg',
                      'Needed by ${_date(s.neededBy!)}'),
                if (_isTask) ...[
                  const SizedBox(height: 14),
                  Text('Posted by',
                      style: _t(14, FontWeight.w600, AppColors.black)),
                  const SizedBox(height: 8),
                  Row(children: [
                    AppImage(s.posterAvatar, width: 40, height: 40, radius: 20),
                    const SizedBox(width: 10),
                    Text(_poster.name,
                        style: AppText.body.copyWith(color: AppColors.black)),
                    if (s.posterVerified) ...[
                      const SizedBox(width: 6),
                      SvgPicture.asset('assets/icons/verified.svg',
                          width: 16, height: 16),
                    ],
                  ]),
                ] else
                  Row(children: [
                    SvgPicture.asset('assets/icons/verified.svg',
                        width: 18, height: 18),
                    const SizedBox(width: 8),
                    const Text('Verified local providers', style: AppText.body),
                  ]),
                const SizedBox(height: 28),
                if (_isOwn)
                  Center(
                      child: Text('This is your request.', style: AppText.body))
                else if (_isTask) ...[
                  AppButton(
                      label: 'Make an offer',
                      loading: _busy,
                      onPressed: _busy ? null : _offer),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Chat with poster',
                    color: Colors.white,
                    textColor: AppColors.primary,
                    onPressed: _busy ? null : _chat,
                  ),
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.icon, this.text);
  final String icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          SvgPicture.asset(icon, width: 16, height: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: _t(13, FontWeight.w400, const Color(0xFF354764)))),
        ]),
      );
}

/// Lender profile reached from the item detail page. Shows only public data
/// (never phone / email); messaging goes through chat.
class LenderProfileScreen extends StatefulWidget {
  const LenderProfileScreen({super.key, required this.person});
  final Person person;

  @override
  State<LenderProfileScreen> createState() => _LenderProfileScreenState();
}

class _LenderProfileScreenState extends State<LenderProfileScreen> {
  late Person _person = widget.person;
  List<Product> _items = const [];
  List<Review> _reviews = const [];
  bool _loading = true;
  String? _error;
  bool _busy = false;

  bool get _isOwn => _person.id == currentProfile.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.person.id;
    if (id.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await Future.wait<Object>([
        backend.person(id),
        backend.listingsOf(id).catchError((_) => <Product>[]),
        backend.reviewsForUser(id).catchError((_) => <Review>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _person = res[0] as Person;
        _items = res[1] as List<Product>;
        _reviews = res[2] as List<Review>;
        _loading = false;
      });
    } on BackendError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _message() async {
    if (_busy || _person.id.isEmpty) return;
    setState(() => _busy = true);
    try {
      final id = await backend.startConversation(_person.id);
      if (!mounted) return;
      await Navigator.of(context).pushNamed(Routes.chat,
          arguments: ChatArgs(_person, conversationId: id));
    } on BackendError catch (e) {
      if (mounted) AppToast.show(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _report() async {
    final reason = await pickReportReason(context, 'Report user');
    if (reason == null || !mounted) return;
    try {
      await backend.reportUser(_person.id, reason);
      if (mounted) AppToast.show(context, 'Thanks, we will review this report');
    } on BackendError catch (e) {
      if (mounted) AppToast.show(context, e.message);
    }
  }

  Future<void> _block() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Block ${_person.name}?'),
        content: const Text(
            'They will no longer be able to message you or request your items.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Block',
                  style: TextStyle(color: AppColors.alert))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await backend.blockUser(_person.id);
      if (!mounted) return;
      AppToast.show(context, '${_person.name} has been blocked');
      Navigator.of(context).maybePop();
    } on BackendError catch (e) {
      if (mounted) AppToast.show(context, e.message);
    }
  }

  void _menu() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: sheetShape,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: AppColors.alert),
              title: Text('Report user',
                  style: _t(14, FontWeight.w400, AppColors.black)),
              onTap: () {
                Navigator.of(ctx).pop();
                _report();
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: AppColors.alert),
              title: Text('Block user',
                  style: _t(14, FontWeight.w400, AppColors.black)),
              onTap: () {
                Navigator.of(ctx).pop();
                _block();
              },
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final person = _person;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _load,
          child: ListView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 32, child: BackArrow()),
                  if (!_isOwn && person.id.isNotEmpty)
                    GestureDetector(
                      onTap: _menu,
                      child:
                          const Icon(Icons.more_horiz, color: AppColors.black),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Center(
                  child: AppImage(person.avatar,
                      width: 96, height: 96, radius: 48)),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Flexible(
                  child: Text(person.name,
                      overflow: TextOverflow.ellipsis,
                      style: _t(18, FontWeight.w500, AppColors.black)),
                ),
                if (person.verified) ...[
                  const SizedBox(width: 6),
                  SvgPicture.asset('assets/icons/verified.svg',
                      width: 18, height: 18),
                ],
              ]),
              const SizedBox(height: 4),
              if (person.city.isNotEmpty)
                Center(child: Text(person.city, style: AppText.body)),
              if (person.trustBand.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Center(
                      child: TrustBadge(
                          band: person.trustBand, score: person.trustScore)),
                ),
              if (person.ratingCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Center(
                    child: Text(
                        '${person.ratingAvg.toStringAsFixed(1)} · ${person.ratingCount} reviews',
                        style: AppText.body),
                  ),
                ),
              if (person.memberSince != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Center(
                      child: Text(
                          'Member since ${_date(person.memberSince!.toLocal())}',
                          style: AppText.body)),
                ),
              if (person.completedTransactions > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Center(
                      child: Text(
                          '${person.completedTransactions} completed · ${person.successfulReturns} successful returns',
                          style: AppText.body)),
                ),
              if (person.bio.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(person.bio,
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(height: 1.5)),
              ],
              if (!_isOwn && person.id.isNotEmpty) ...[
                const SizedBox(height: 18),
                AppButton(
                    label: 'Message',
                    loading: _busy,
                    onPressed: _busy ? null : _message),
              ],
              const SizedBox(height: 26),
              if (_loading)
                const LoadingView()
              else if (_error != null)
                StateMessage(message: _error!, onAction: _load)
              else ...[
                Text('Listed items',
                    style: _t(16, FontWeight.w500, AppColors.black)),
                const SizedBox(height: 12),
                if (_items.isEmpty)
                  Text('No items listed yet', style: AppText.body)
                else
                  LayoutBuilder(builder: (context, c) {
                    final w = (c.maxWidth - 10) / 2;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final p in _items)
                          SizedBox(
                            width: w,
                            child: ProductCard(
                              product: p,
                              onBorrow: () => Navigator.of(context)
                                  .pushNamed(Routes.itemDetail, arguments: p),
                            ),
                          ),
                      ],
                    );
                  }),
                const SizedBox(height: 26),
                Text('Reviews',
                    style: _t(16, FontWeight.w500, AppColors.black)),
                const SizedBox(height: 12),
                if (_reviews.isEmpty)
                  Text('No reviews yet', style: AppText.body),
                for (final r in _reviews)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6F7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          AppImage(r.avatar, width: 36, height: 36, radius: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.author,
                                    style: _t(
                                        11, FontWeight.w500, AppColors.black)),
                                Row(children: [
                                  for (var i = 0; i < 5; i++)
                                    SvgPicture.asset(
                                      i < r.rating
                                          ? 'assets/icons/star.svg'
                                          : 'assets/icons/star_empty.svg',
                                      width: 14,
                                      height: 14,
                                    ),
                                ]),
                              ],
                            ),
                          ),
                        ]),
                        if (r.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(r.text,
                              style: _t(11, FontWeight.w400, AppColors.black)),
                        ],
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
