import 'package:flutter/material.dart';
import '../../core/widgets/trust_badge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/market_cards.dart';
import '../../core/widgets/tappable.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/radio_sheet.dart' show sheetShape;
import '../../data/backend.dart';
import '../../data/models.dart';
import '../../data/user_profile.dart';
import '../chat/chat_screen.dart';
import 'detail_sheets.dart';

const _ink = Color(0xFF505F79);
const _n600 = Color(0xFF354764);

TextStyle _t(double size, FontWeight w, Color c) => TextStyle(
      fontFamily: AppTheme.fontFamily,
      fontSize: size,
      fontWeight: w,
      color: c,
    );

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({super.key, required this.product});
  final Product product;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final _page = PageController();
  int _index = 0;
  bool _liked = false;
  bool _busy = false;
  bool _watching = false;

  late Product _p = widget.product;
  Person? _lender;
  List<Review> _reviews = const [];
  List<Product> _similar = const [];
  bool _loadingExtras = true;
  String? _error;

  bool get _isOwn => _p.ownerId.isNotEmpty && _p.ownerId == currentProfile.id;
  bool get _isService => _p.kind == 'service';
  bool get _unavailable => !_isService && _p.status == 'reserved';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loadingExtras = true;
      _error = null;
    });
    try {
      final fresh = await backend.listing(widget.product.id);
      if (!mounted) return;
      setState(() => _p = fresh);
    } on BackendError catch (e) {
      if (!mounted) return;
      // Keep showing the card data we already have; surface the problem.
      setState(() => _error = e.message);
    }
    final p = _p;
    if (!_isOwn && !_isService) {
      backend.isWatching(p.id).then((w) {
        if (mounted) setState(() => _watching = w);
      });
    }
    final res = await Future.wait<Object?>([
      p.ownerId.isEmpty
          ? Future<Person?>.value(null)
          : backend
              .person(p.ownerId)
              .then<Person?>((x) => x)
              .catchError((_) => null),
      backend.reviewsForListing(p.id).catchError((_) => <Review>[]),
      backend
          .products(
              category: p.categoryLabel.isEmpty ? null : p.categoryLabel,
              limit: 8)
          .catchError((_) => <Product>[]),
    ]);
    if (!mounted) return;
    setState(() {
      _lender = res[0] as Person?;
      _reviews = res[1] as List<Review>;
      _similar =
          (res[2] as List<Product>).where((x) => x.id != p.id).take(6).toList();
      _loadingExtras = false;
    });
  }

  Person get _lenderOrStub =>
      _lender ??
      Person(
        id: _p.ownerId,
        name: _p.ownerName.isEmpty ? 'Seculate user' : _p.ownerName,
        avatar: _p.ownerAvatar ?? '',
        verified: _p.ownerVerified,
      );

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _share() {
    Clipboard.setData(ClipboardData(text: 'https://seculate.ng/item/${_p.id}'));
    AppToast.show(context, 'Link copied');
  }

  Future<void> _toggleWatch() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await backend.watchListing(_p.id, !_watching);
      if (!mounted) return;
      setState(() => _watching = !_watching);
      AppToast.show(
          context,
          _watching
              ? 'We will tell you as soon as it is available'
              : 'Alert removed');
    } on BackendError catch (e) {
      if (mounted) AppToast.show(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _borrow() async {
    if (_busy || _isOwn) return;
    final days = await showDaysSheet(context,
        maxDays: _p.availabilityDays,
        pricePerDay: _p.pricePerDay,
        collateral: _p.collateral,
        securityFee: _p.securityFee,
        minDays: _p.minDays,
        lenderMaxDays: _p.maxDays);
    if (days == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final txId = await backend.requestBorrow(_p.id, days);
      String? convo;
      try {
        convo = (await backend.transaction(txId)).conversationId;
      } catch (_) {}
      if (!mounted) return;
      AppToast.show(context, 'Request sent');
      await Navigator.of(context).pushNamed(Routes.chat,
          arguments: ChatArgs(_lenderOrStub, conversationId: convo));
    } on BackendError catch (e) {
      if (mounted) AppToast.show(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chat() async {
    if (_busy || _isOwn || _p.ownerId.isEmpty) return;
    setState(() => _busy = true);
    try {
      final id = await backend.startConversation(_p.ownerId, listingId: _p.id);
      if (!mounted) return;
      await Navigator.of(context).pushNamed(Routes.chat,
          arguments: ChatArgs(_lenderOrStub, conversationId: id));
    } on BackendError catch (e) {
      if (mounted) AppToast.show(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _report() async {
    final reason = await pickReportReason(context, 'Report listing');
    if (reason == null || !mounted) return;
    try {
      await backend.reportListing(_p.id, reason);
      if (mounted) {
        AppToast.show(context, 'Thanks, we will review this listing');
      }
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    const Icon(Icons.flag_outlined, color: AppColors.alert),
                title: Text('Report listing',
                    style: _t(14, FontWeight.w400, AppColors.black)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _report();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.primary,
            edgeOffset: top + 60,
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.only(bottom: 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Hero(
                    images: p.gallery,
                    controller: _page,
                    index: _index,
                    onChanged: (i) => setState(() => _index = i),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(27, 12, 27, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_error != null) ...[
                          Text(_error!,
                              style: _t(12, FontWeight.w400, AppColors.alert)),
                          const SizedBox(height: 8),
                        ],
                        _Summary(product: p),
                        const SizedBox(height: 20),
                        _Block(
                            'Description',
                            Text(p.description,
                                style: _t(14, FontWeight.w400, _ink))),
                        if (p.features.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          _Block(
                            'Features:',
                            Text(p.features.join('\n'),
                                style: _t(14, FontWeight.w400, _ink)),
                          ),
                        ],
                        const SizedBox(height: 32),
                        _ReviewsBlock(
                            reviews: _reviews, loading: _loadingExtras),
                        const SizedBox(height: 32),
                        const _ReturnPolicy(),
                        const SizedBox(height: 32),
                        if (p.ownerId.isNotEmpty)
                          _LenderBlock(
                            lender: _lenderOrStub,
                            canChat: !_isOwn,
                            onChat: _chat,
                          ),
                        if (_similar.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Divider(height: 1, color: AppColors.neutral40),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Similar items you can borrow',
                                  style:
                                      _t(14, FontWeight.w600, AppColors.black)),
                              _SeeAll(onTap: () => Navigator.of(context).pop()),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(builder: (context, c) {
                            final w = (c.maxWidth - 9) / 2;
                            return Wrap(
                              spacing: 9,
                              runSpacing: 9,
                              children: [
                                for (final s in _similar)
                                  SizedBox(
                                    width: w,
                                    child: ProductCard(
                                      product: s,
                                      onBorrow: () => Navigator.of(context)
                                          .pushNamed(Routes.itemDetail,
                                              arguments: s),
                                    ),
                                  ),
                              ],
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Floating circular buttons.
          Positioned(
            top: top + 20,
            left: 28,
            child: _CircleBtn('assets/icons/d_back.svg',
                () => Navigator.of(context).maybePop()),
          ),
          Positioned(
            top: top + 20,
            right: 28,
            child: Row(
              children: [
                _CircleBtn(
                  'assets/icons/d_heart.svg',
                  () => setState(() => _liked = !_liked),
                  tint: _liked ? AppColors.alert : null,
                  filled: _liked,
                ),
                const SizedBox(width: 16),
                _CircleBtn('assets/icons/d_share.svg', _share),
                if (!_isOwn) ...[
                  const SizedBox(width: 16),
                  Tappable(
                    onTap: _menu,
                    scale: 0.88,
                    child: Container(
                      width: 39,
                      height: 39,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.more_horiz,
                          color: AppColors.black, size: 22),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomBar(
              label: _isService ? 'Price' : 'Total Collateral',
              value: _isService
                  ? (p.pricePerDay > 0 ? p.priceLabel : 'On request')
                  : naira(p.collateral),
              buttonLabel: _isOwn
                  ? 'Your listing'
                  : (_isService
                      ? 'Chat with provider'
                      : _unavailable
                          ? (_watching
                              ? 'Alert on (tap to cancel)'
                              : 'Notify me when available')
                          : 'Borrow'),
              loading: _busy,
              onPressed: _isOwn
                  ? null
                  : (_isService
                      ? _chat
                      : (_unavailable ? _toggleWatch : _borrow)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero(
      {required this.images,
      required this.controller,
      required this.index,
      required this.onChanged});
  final List<String> images;
  final PageController controller;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 453,
      child: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: controller,
              itemCount: images.length,
              onPageChanged: onChanged,
              itemBuilder: (_, i) => AppImage(images[i], fit: BoxFit.cover),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 71,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x00FFFFFF),
                      Color(0x8FFFFFFF),
                      Colors.white
                    ],
                    stops: [0, 0.49, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < images.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == index
                          ? AppColors.primary
                          : const Color(0xFFEBEDF0),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn(this.asset, this.onTap, {this.tint, this.filled = false});
  final String asset;
  final VoidCallback onTap;
  final Color? tint;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      scale: 0.88,
      child: Container(
        width: 39,
        height: 39,
        alignment: Alignment.center,
        decoration:
            const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
          child: filled
              ? const Icon(Icons.favorite,
                  key: ValueKey('on'), color: AppColors.alert, size: 22)
              : SvgPicture.asset(asset,
                  key: const ValueKey('off'), width: 24, height: 24),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEBEDF0),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Text(product.categoryLabel,
                  style: _t(10, FontWeight.w400, AppColors.black)),
            ),
            Row(
              children: [
                SvgPicture.asset('assets/icons/star.svg',
                    width: 24, height: 24),
                Text(product.rating.toStringAsFixed(1),
                    style: _t(12.4, FontWeight.w400, AppColors.black)),
                const SizedBox(width: 4),
                Text('(${product.reviewCount} reviews)',
                    style: _t(12.4, FontWeight.w400, AppColors.black)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(product.name, style: _t(22, FontWeight.w500, AppColors.black)),
        const SizedBox(height: 8),
        Text.rich(TextSpan(children: [
          TextSpan(
              text: 'In Stock:',
              style: _t(10, FontWeight.w400, const Color(0xFF42526D))),
          TextSpan(
              text: ' ${product.inStock} available',
              style: _t(10, FontWeight.w400, AppColors.black)),
        ])),
        const SizedBox(height: 8),
        _Info('assets/icons/location.svg', product.location),
        const SizedBox(height: 8),
        if (product.distanceKm != null) ...[
          _Info('assets/icons/location.svg', product.distanceLabel),
          const SizedBox(height: 8),
        ],
        if (product.pricePerDay > 0) ...[
          _Info('assets/icons/naira.svg', product.priceLabel),
          const SizedBox(height: 8),
        ],
        _Info('assets/icons/time.svg', product.availability),
      ],
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.icon, this.text);
  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(icon, width: 16, height: 16),
        const SizedBox(width: 8),
        Text(text, style: _t(10, FontWeight.w400, _n600)),
      ],
    );
  }
}

class _Block extends StatelessWidget {
  const _Block(this.title, this.child);
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _t(14, FontWeight.w600, AppColors.black)),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: child),
      ],
    );
  }
}

class _SeeAll extends StatelessWidget {
  const _SeeAll({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      child: Row(
        children: [
          Text('See all', style: _t(14, FontWeight.w400, AppColors.neutral100)),
          const SizedBox(width: 4),
          SvgPicture.asset('assets/icons/chevron_right_dark.svg',
              width: 24, height: 24),
        ],
      ),
    );
  }
}

class _ReviewsBlock extends StatelessWidget {
  const _ReviewsBlock({required this.reviews, this.loading = false});
  final List<Review> reviews;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Reviews', style: _t(14, FontWeight.w600, AppColors.black)),
          ],
        ),
        const SizedBox(height: 8),
        if (reviews.isEmpty)
          Text(loading ? 'Loading reviews…' : 'No reviews yet',
              style: _t(12, FontWeight.w400, _ink)),
        for (final r in reviews)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6F7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppImage(r.avatar, width: 45, height: 45, radius: 22.5),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.author,
                            style: _t(10, FontWeight.w500, AppColors.black)),
                        Row(
                          children: [
                            for (var i = 0; i < 5; i++)
                              SvgPicture.asset(
                                i < r.rating
                                    ? 'assets/icons/star.svg'
                                    : 'assets/icons/star_empty.svg',
                                width: 16,
                                height: 16,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(r.text, style: _t(10, FontWeight.w400, AppColors.black)),
              ],
            ),
          ),
      ],
    );
  }
}

class _ReturnPolicy extends StatelessWidget {
  const _ReturnPolicy();

  @override
  Widget build(BuildContext context) {
    final s = _t(14, FontWeight.w400, _ink);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Return Policy', style: _t(14, FontWeight.w600, AppColors.black)),
        const SizedBox(height: 8),
        Text('Please return items in good condition and on time.', style: s),
        const SizedBox(height: 8),
        Text(
            'Treat items with care as your own. This keeps the community safe and trustworthy.',
            style: s),
        const SizedBox(height: 8),
        Text(
            'If an item is returned damaged or late, a penalty fee will apply, and your account may be limited.',
            style: s),
        const SizedBox(height: 8),
        Text('✅ Keep it clean', style: s),
        const SizedBox(height: 8),
        Text('✅ Return on time', style: s),
        const SizedBox(height: 8),
        Text('✅ Avoid penalties', style: s),
      ],
    );
  }
}

class _LenderBlock extends StatelessWidget {
  const _LenderBlock(
      {required this.lender, required this.canChat, required this.onChat});
  final Person lender;
  final bool canChat;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lender', style: _t(14, FontWeight.w600, AppColors.black)),
        const SizedBox(height: 8),
        Tappable(
          onTap: () => Navigator.of(context)
              .pushNamed(Routes.lenderProfile, arguments: lender),
          scale: 0.99,
          child: Row(
            children: [
              SizedBox(
                width: 47,
                height: 47,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AppImage(lender.avatar,
                        width: 47, height: 47, radius: 23.5),
                    if (lender.verified)
                      Positioned(
                        left: 35,
                        top: 0,
                        child: SvgPicture.asset('assets/icons/verified.svg',
                            width: 16, height: 16),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lender.name,
                        style: _t(14, FontWeight.w400, AppColors.black)),
                    if (lender.ratingCount > 0)
                      Text(
                          '${lender.ratingAvg.toStringAsFixed(1)} (${lender.ratingCount} reviews)',
                          style: _t(14, FontWeight.w400, _ink))
                    else if (lender.city.isNotEmpty)
                      Text(lender.city, style: _t(14, FontWeight.w400, _ink)),
                    if (lender.trustBand.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: TrustBadge(band: lender.trustBand),
                      ),
                  ],
                ),
              ),
              if (canChat)
                Tappable(
                  onTap: onChat,
                  child: SvgPicture.asset('assets/icons/chat.svg',
                      width: 24, height: 24),
                ),
              const SizedBox(width: 20),
              SvgPicture.asset('assets/icons/chevron_right_dark.svg',
                  width: 24, height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.label,
    required this.value,
    required this.buttonLabel,
    required this.onPressed,
    this.loading = false,
  });
  final String label;
  final String value;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.neutral50, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: _t(14, FontWeight.w400, _ink)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: _t(18, FontWeight.w500, AppColors.primary)),
                ],
              ),
              SizedBox(
                width: 174,
                child: AppButton(
                  label: buttonLabel,
                  loading: loading,
                  onPressed: onPressed,
                  disabledColor: const Color(0xFFEBEDF0),
                  disabledTextColor: AppColors.neutral200,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
