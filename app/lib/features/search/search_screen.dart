import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/back_arrow.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/market_cards.dart';
import '../../core/widgets/tappable.dart';
import '../../core/widgets/state_views.dart';
import '../../data/backend.dart';
import '../../data/models.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<Product> _results = const [];
  List<String> _recent = const [];
  String _query = '';
  bool _loading = true;
  String? _error;
  Timer? _debounce;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    _load('');
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final r = await backend.recentSearches();
    if (mounted) setState(() => _recent = r);
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _load(q));
  }

  Future<void> _load(String q) async {
    final seq = ++_seq;
    setState(() {
      _query = q;
      _loading = true;
      _error = null;
    });
    try {
      final r = await backend.products(query: q);
      if (!mounted || seq != _seq) return;
      setState(() {
        _results = r;
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

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _useTerm(String t) async {
    _debounce?.cancel();
    _controller.text = t;
    _controller.selection = TextSelection.collapsed(offset: t.length);
    FocusScope.of(context).unfocus();
    _load(t);
    await backend.addRecentSearch(t);
    _loadRecent();
  }

  Future<void> _clearRecent() async {
    await backend.clearRecentSearches();
    if (mounted) setState(() => _recent = const []);
  }

  @override
  Widget build(BuildContext context) {
    final searching = _query.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(27, 16, 28, 28),
          child: FadeSlideIn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 24, child: BackArrow()),
                    const SizedBox(width: 14),
                    Expanded(
                        child: _SearchField(
                      controller: _controller,
                      onChanged: _onChanged,
                      onSubmitted: _useTerm,
                    )),
                  ],
                ),
                if (!searching && _recent.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent searches',
                          style: AppText.body
                              .copyWith(color: AppColors.black, fontSize: 13)),
                      Tappable(
                        onTap: _clearRecent,
                        child: Text('Clear',
                            style: AppText.body.copyWith(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      for (final t in _recent)
                        Tappable(
                          onTap: () => _useTerm(t),
                          scale: 0.94,
                          child: Text(t,
                              style: AppText.body.copyWith(
                                  color: AppColors.neutral50, fontSize: 12.5)),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      searching ? 'Results' : 'Items to Borrow',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: AppColors.black,
                      ),
                    ),
                    if (!searching)
                      Row(children: [
                        Text('See all',
                            style: AppText.body.copyWith(fontSize: 12)),
                        SvgPicture.asset('assets/icons/chevron_right.svg',
                            width: 18, height: 18),
                      ]),
                  ],
                ),
                const SizedBox(height: 14),
                if (_loading)
                  const LoadingView()
                else if (_error != null)
                  StateMessage(message: _error!, onAction: () => _load(_query))
                else if (_results.isEmpty)
                  StateMessage(
                      message: searching
                          ? 'No items found for “$_query”'
                          : 'No items near you yet')
                else
                  LayoutBuilder(builder: (context, c) {
                    final w = (c.maxWidth - 9) / 2;
                    return Wrap(
                      spacing: 9,
                      runSpacing: 9,
                      children: [
                        for (final p in _results)
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField(
      {required this.controller,
      required this.onChanged,
      required this.onSubmitted});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.black, width: 1),
      ),
      child: Row(
        children: [
          SvgPicture.asset('assets/icons/search.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                  AppColors.neutral200, BlendMode.srcIn)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: false,
              textInputAction: TextInputAction.search,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              cursorColor: AppColors.primary,
              style: AppText.title1,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: 'Gas cooker......',
                hintStyle: AppText.body.copyWith(color: AppColors.neutral100),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
