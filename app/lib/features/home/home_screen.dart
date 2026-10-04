import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/market_cards.dart';
import '../../core/widgets/tappable.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/state_views.dart';
import '../../data/backend.dart';
import '../../data/models.dart';
import '../../data/user_profile.dart';
import '../shell/bell_button.dart';
import '../shell/main_shell.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Exactly the ten tiles in the Figma Home frame, in order. [labels] are the
  /// server category names a tile filters Items to Borrow by.
  static const _tiles = <_Tile>[
    _Tile('popular', 'Popular', 'assets/icons/fire.svg', _Go.all),
    _Tile(
        'electronics',
        'Electronics',
        'assets/images/categories/electronics.png',
        _Go.items,
        ['Electronics & Appliances']),
    _Tile('fashion', 'Fashion', 'assets/images/categories/fashion.png',
        _Go.items, ['Fashion & Style']),
    _Tile('furniture', 'Furniture', 'assets/images/categories/furniture.png',
        _Go.items, ['Furniture']),
    _Tile('tools', 'Tools', 'assets/images/categories/tools.png', _Go.items,
        ['Tools & Equipment']),
    _Tile('cleaning', 'Cleaning\n& Utility',
        'assets/images/categories/cleaning.png', _Go.services),
    _Tile('media', 'Media &\nGadgets', 'assets/images/categories/media.png',
        _Go.items, ['Photography & Media', 'Mobile & Gadgets']),
    _Tile('services', 'Services', 'assets/images/categories/services.png',
        _Go.services),
    _Tile('home', 'Home &\nAppliances',
        'assets/images/categories/appliances.png', _Go.items, ['Kitchenware']),
    _Tile('post', 'Post add', null, _Go.post),
  ];

  List<Product> _products = const [];
  List<ServiceItem> _tasks = const [];
  _Tile? _selected;
  bool _loading = true;
  String? _error;
  bool _loadingItems = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<Product> _nearestFirst(List<Product> l) {
    final r = List<Product>.of(l);
    r.sort((a, b) {
      final x = a.distanceKm, y = b.distanceKm;
      if (x == null && y == null) return 0;
      if (x == null) return 1;
      if (y == null) return -1;
      return x.compareTo(y);
    });
    return r;
  }

  Future<List<Product>> _fetchItems() async {
    final labels = _selected?.labels ?? const <String>[];
    if (labels.isEmpty) {
      return _nearestFirst(await backend.products(kind: 'item'));
    }
    final lists = await Future.wait(
        [for (final l in labels) backend.products(kind: 'item', category: l)]);
    return _nearestFirst([for (final l in lists) ...l]);
  }

  Future<void> _load() async {
    if (_products.isEmpty) setState(() => _loading = true);
    try {
      final res = await Future.wait<Object>([
        _fetchItems(),
        backend.tasks(limit: 8).catchError((_) => <ServiceItem>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _products = res[0] as List<Product>;
        _tasks = res[1] as List<ServiceItem>;
        _error = null;
        _loading = false;
      });
    } on BackendError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load items. Pull to retry.';
        _loading = false;
      });
    }
  }

  Future<void> _selectCategory(_Tile? c) async {
    setState(() {
      _selected = c;
      _loadingItems = true;
    });
    try {
      final r = await _fetchItems();
      if (!mounted || _selected != c) return;
      setState(() {
        _products = r;
        _loadingItems = false;
      });
    } on BackendError catch (e) {
      if (!mounted) return;
      setState(() => _loadingItems = false);
      AppToast.show(context, e.message);
    }
  }

  void _onCategory(_Tile t, ShellController? shell) {
    switch (t.go) {
      case _Go.post:
        shell?.goTo(2);
      case _Go.services:
        shell?.goTo(3);
      case _Go.all:
        _selectCategory(null);
      case _Go.items:
        _selectCategory(t);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shell = ShellController.maybeOf(context);
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeSlideIn(
                  child: _Greeting(
                      onSearch: () =>
                          Navigator.of(context).pushNamed(Routes.search))),
              const SizedBox(height: 24),
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child: _BannerCarousel(
                    onAction: (i) => shell?.goTo(const [1, 2, 3][i])),
              ),
              const SizedBox(height: 24),
              FadeSlideIn(
                delay: const Duration(milliseconds: 140),
                child: _CategoryGrid(
                  tiles: _tiles,
                  selectedId: _selected?.id ?? 'popular',
                  onTap: (c) => _onCategory(c, shell),
                ),
              ),
              const SizedBox(height: 28),
              _SectionHeader('Items to Borrow', onSeeAll: () => shell?.goTo(1)),
              const SizedBox(height: 16),
              if (_loading)
                const LoadingView()
              else if (_error != null)
                StateMessage(
                    message: _error!, actionLabel: 'Try again', onAction: _load)
              else if (_loadingItems)
                const LoadingView()
              else if (_products.isEmpty)
                StateMessage(
                    message: _selected == null
                        ? 'No items near you yet'
                        : 'No ${_selected!.label.replaceAll('\n', ' ')} items near you yet')
              else
                _CardGrid(
                  children: [
                    for (final p in _products)
                      ProductCard(
                        product: p,
                        onBorrow: () => Navigator.of(context)
                            .pushNamed(Routes.itemDetail, arguments: p),
                      ),
                  ],
                ),
              if (!_loading && _error == null && _tasks.isNotEmpty) ...[
                const SizedBox(height: 32),
                _SectionHeader('Services Available',
                    onSeeAll: () => shell?.goTo(3)),
                const SizedBox(height: 16),
                _CardGrid(
                  children: [
                    for (final s in _tasks.take(4))
                      ServiceCard(
                        service: s,
                        onRequest: () => Navigator.of(context)
                            .pushNamed(Routes.serviceDetail, arguments: s),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.onSearch});
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            '${UserProfile.greeting()}${currentProfile.firstName.isEmpty ? '' : ', ${currentProfile.firstName}'} 👋\nWhat do you need today?',
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: AppColors.black,
            ),
          ),
        ),
        _IconTap('assets/icons/search.svg', onSearch),
        const SizedBox(width: 6),
        const BellButton(),
      ],
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

class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel({required this.onAction});
  final ValueChanged<int> onAction;

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  static const _count = 3;
  final _controller = PageController(viewportFraction: 0.94);
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.animateToPage((_page + 1) % _count,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1002 / 504 * 0.99,
          child: PageView.builder(
            controller: _controller,
            padEnds: false,
            itemCount: _count,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _BannerCard(index: i, onAction: () => widget.onAction(i)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _count; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 31 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color:
                      i == _page ? AppColors.neutral200 : AppColors.neutral50,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.index, required this.onAction});
  final int index;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth, h = c.maxHeight;
      return Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/banners/banner_${index + 1}.png',
              fit: BoxFit.fill,
              cacheWidth: 900,
              gaplessPlayback: true,
            ),
          ),
          // Invisible hit area over the baked-in white button.
          Positioned(
            left: w * 0.30,
            top: h * 0.60,
            width: w * 0.40,
            height: h * 0.28,
            child: Tappable(onTap: onAction, child: const SizedBox.expand()),
          ),
        ],
      );
    });
  }
}

enum _Go { all, items, services, post }

class _Tile {
  const _Tile(this.id, this.label, this.icon, this.go,
      [this.labels = const <String>[]]);
  final String id;
  final String label;
  final String? icon;
  final _Go go;
  final List<String> labels;
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid(
      {required this.tiles, required this.onTap, required this.selectedId});
  final List<_Tile> tiles;
  final ValueChanged<_Tile> onTap;
  final String selectedId;

  @override
  Widget build(BuildContext context) {
    Widget row(List<_Tile> r) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final t in r)
              _CategoryTile(t, () => onTap(t), selected: t.id == selectedId),
          ],
        );
    return Column(
      children: [
        row(tiles.sublist(0, 5)),
        const SizedBox(height: 16),
        row(tiles.sublist(5, 10)),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile(this.tile, this.onTap, {this.selected = false});
  final _Tile tile;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final icon = tile.icon;
    final isPost = tile.go == _Go.post;
    Widget inner;
    if (isPost) {
      inner = SvgPicture.asset('assets/icons/plus_white.svg',
          width: 24, height: 24);
    } else if (icon != null && icon.endsWith('.svg')) {
      inner = SvgPicture.asset(icon, width: 24, height: 24);
    } else {
      inner = Padding(
        padding: const EdgeInsets.all(9),
        child: Image.asset(icon!, fit: BoxFit.contain, cacheWidth: 120),
      );
    }
    return Tappable(
      onTap: onTap,
      scale: 0.92,
      child: SizedBox(
        width: 56,
        child: Column(
          children: [
            Container(
              width: 50.7,
              height: 51.7,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color:
                    isPost ? const Color(0xFFF2A33A) : const Color(0xFFEEF0FF),
                borderRadius: BorderRadius.circular(12),
                border: selected && !isPost
                    ? Border.all(color: AppColors.primary, width: 1.2)
                    : null,
              ),
              child: inner,
            ),
            const SizedBox(height: 5),
            Text(
              tile.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 9,
                height: 1.3,
                color: AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {required this.onSeeAll});
  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: AppColors.black,
          ),
        ),
        Tappable(
          onTap: onSeeAll,
          child: Row(
            children: [
              Text('See all', style: AppText.body.copyWith(fontSize: 12.5)),
              SvgPicture.asset('assets/icons/chevron_right.svg',
                  width: 20, height: 20),
            ],
          ),
        ),
      ],
    );
  }
}

/// Two-column grid of fixed-height cards.
class _CardGrid extends StatelessWidget {
  const _CardGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = (c.maxWidth - 9) / 2;
      return Wrap(
        spacing: 9,
        runSpacing: 9,
        children: [for (final ch in children) SizedBox(width: w, child: ch)],
      );
    });
  }
}
