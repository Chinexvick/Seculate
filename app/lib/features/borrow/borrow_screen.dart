import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/market_cards.dart';
import '../../core/widgets/price_sheet.dart';
import '../../core/widgets/radio_sheet.dart';
import '../../core/widgets/tappable.dart';
import '../../core/widgets/state_views.dart';
import '../../data/backend.dart';
import '../../data/models.dart';
import '../shell/bell_button.dart';

/// "Listed items" tab: filter chips + two-column product grid.
class BorrowScreen extends StatefulWidget {
  const BorrowScreen({super.key});

  @override
  State<BorrowScreen> createState() => _BorrowScreenState();
}

class _BorrowScreenState extends State<BorrowScreen> {
  static const _availability = [
    SheetOption('any', 'Any'),
    SheetOption('1', '24 hours'),
    SheetOption('2', '2 days'),
    SheetOption('3', '3 days'),
    SheetOption('5', '5 days'),
    SheetOption('7', '1 weeks'),
    SheetOption('14', '2 weeks'),
    SheetOption('21', '3 weeks'),
    SheetOption('30', '1 month'),
  ];

  List<SheetOption> _categories = const [SheetOption('popular', 'Popular')];
  List<Product> _all = const [];
  String _category = 'popular';
  String _avail = 'any';
  PriceFilter _price = PriceFilter.none;
  bool _loading = true;
  String? _error;
  int _seq = 0;

  bool get _priceActive => _price.active;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _load();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await backend.categories();
      if (!mounted) return;
      setState(() => _categories = [
            const SheetOption('popular', 'Popular'),
            for (final c in cats.where((c) => c.kind != 'service'))
              SheetOption(c.label, c.label),
          ]);
    } catch (_) {}
  }

  Future<void> _load() async {
    final seq = ++_seq;
    if (_all.isEmpty) setState(() => _loading = true);
    try {
      final r = await backend.products(
        kind: 'item',
        category: _category == 'popular' ? null : _category,
        minPrice: _price.from > 0 ? _price.from : null,
        maxPrice: _price.to,
      );
      if (!mounted || seq != _seq) return;
      setState(() {
        _all = r;
        _error = null;
        _loading = false;
      });
    } on BackendError catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  List<Product> get _visible {
    var list = List<Product>.of(_all);
    if (_avail != 'any') {
      final d = int.parse(_avail);
      list = list.where((p) => p.availabilityDays >= d).toList();
    }
    return list;
  }

  Future<void> _pickCategory() async {
    final r = await showRadioSheet(context,
        title: 'Categories', options: _categories, selectedId: _category);
    if (r != null && r != _category) {
      setState(() => _category = r);
      _all = const [];
      _load();
    }
  }

  Future<void> _pickAvailability() async {
    final r = await showRadioSheet(context,
        title: 'Availability',
        options: _availability.sublist(1),
        selectedId: _avail);
    if (r != null) setState(() => _avail = r);
  }

  Future<void> _pickPrice() async {
    final r = await showPriceSheet(context, current: _price);
    if (r != null) {
      setState(() => _price = r);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 20, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Listed items',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 22,
                        color: AppColors.black,
                      )),
                ),
                _IconTap('assets/icons/search.svg',
                    () => Navigator.of(context).pushNamed(Routes.search)),
                const SizedBox(width: 6),
                const BellButton(),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              children: [
                _Chip('Popular',
                    active: _category != 'popular', onTap: _pickCategory),
                const SizedBox(width: 10),
                _Chip('Availability',
                    active: _avail != 'any', onTap: _pickAvailability),
                const SizedBox(width: 10),
                _Chip('Price', active: _priceActive, onTap: _pickPrice),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _error != null
                    ? StateMessage(
                        message: _error!,
                        actionLabel: 'Try again',
                        onAction: _load)
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _load,
                        child: items.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  const SizedBox(height: 80),
                                  StateMessage(
                                      message: _all.isEmpty &&
                                              _category == 'popular' &&
                                              !_priceActive
                                          ? 'No items near you yet'
                                          : 'No items match these filters'),
                                ],
                              )
                            : SingleChildScrollView(
                                physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics()),
                                padding:
                                    const EdgeInsets.fromLTRB(28, 0, 28, 24),
                                child: LayoutBuilder(builder: (context, c) {
                                  final w = (c.maxWidth - 9) / 2;
                                  return AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 220),
                                    child: Wrap(
                                      key: ValueKey(
                                          '${items.length}-$_category-$_avail-${_price.from}-${_price.to}'),
                                      spacing: 9,
                                      runSpacing: 9,
                                      children: [
                                        for (final p in items)
                                          SizedBox(
                                            width: w,
                                            child: ProductCard(
                                              product: p,
                                              onBorrow: () =>
                                                  Navigator.of(context)
                                                      .pushNamed(
                                                          Routes.itemDetail,
                                                          arguments: p),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _IconTap extends StatelessWidget {
  const _IconTap(this.asset, this.onTap);
  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      scale: 0.88,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SvgPicture.asset(asset, width: 24, height: 24),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, {required this.onTap, this.active = false});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 38,
        padding: const EdgeInsets.only(left: 16, right: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEAFBEF) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: active ? AppColors.primary : AppColors.neutral50),
        ),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14,
                  color: AppColors.black,
                )),
            const SizedBox(width: 2),
            SvgPicture.asset('assets/icons/chevron_down.svg',
                width: 22, height: 22),
          ],
        ),
      ),
    );
  }
}
