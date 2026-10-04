import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/market_cards.dart';
import '../../core/widgets/state_views.dart';
import '../../data/backend.dart';
import '../../data/models.dart';
import '../shell/bell_button.dart';

/// "Available Services" tab (bottom nav → Services).
class ServicesTab extends StatefulWidget {
  const ServicesTab({super.key});

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  List<ServiceItem>? _list;
  List<Product> _services = const [];
  int _mode = 0; // 0 = services people offer, 1 = errands people need done
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await Future.wait<Object>([
        backend.tasks(limit: 50),
        backend.products(kind: 'service', limit: 50),
      ]);
      if (!mounted) return;
      setState(() {
        _list = res[0] as List<ServiceItem>;
        _services = res[1] as List<Product>;
        _error = null;
      });
    } on BackendError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Available Services',
                      style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w500,
                          fontSize: 22,
                          color: AppColors.black)),
                ),
                _Icon('assets/icons/search.svg',
                    () => Navigator.of(context).pushNamed(Routes.search)),
                const SizedBox(width: 12),
                const BellButton(padding: EdgeInsets.all(4)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
            child: Row(children: [
              for (final e in const [(0, 'Services'), (1, 'Errands')])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(e.$2),
                    selected: _mode == e.$1,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                        color: _mode == e.$1 ? Colors.white : AppColors.black),
                    onSelected: (_) => setState(() => _mode = e.$1),
                  ),
                ),
            ]),
          ),
          Expanded(
            child: Builder(
              builder: (_) {
                final list = _list;
                if (list == null && _error == null) return const LoadingView();
                if (list == null) {
                  return StateMessage(
                      message: _error!,
                      actionLabel: 'Try again',
                      onAction: _load);
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _load,
                  child: _mode == 0
                      ? (_services.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 80),
                                StateMessage(
                                    message: 'No services near you yet'),
                              ],
                            )
                          : LayoutBuilder(builder: (_, c) {
                              final w = (c.maxWidth - 56 - 9) / 2;
                              return SingleChildScrollView(
                                physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics()),
                                padding:
                                    const EdgeInsets.fromLTRB(28, 4, 28, 24),
                                child:
                                    Wrap(spacing: 9, runSpacing: 9, children: [
                                  for (final p in _services)
                                    SizedBox(
                                      width: w,
                                      child: ProductCard(
                                        product: p,
                                        onBorrow: () => Navigator.of(context)
                                            .pushNamed(Routes.itemDetail,
                                                arguments: p),
                                      ),
                                    ),
                                ]),
                              );
                            }))
                      : list.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 80),
                                StateMessage(
                                    message: 'No errands near you yet'),
                              ],
                            )
                          : GridView.builder(
                              physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics()),
                              padding: const EdgeInsets.fromLTRB(28, 4, 28, 24),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                mainAxisExtent: 262,
                              ),
                              itemCount: list.length,
                              itemBuilder: (_, i) => FadeSlideIn(
                                delay: Duration(
                                    milliseconds: 40 * (i < 6 ? i : 6)),
                                child: ServiceCard(
                                  service: list[i],
                                  onRequest: () => Navigator.of(context)
                                      .pushNamed(Routes.serviceDetail,
                                          arguments: list[i]),
                                ),
                              ),
                            ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Icon extends StatelessWidget {
  const _Icon(this.asset, this.onTap);
  final String asset;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SvgPicture.asset(asset, width: 24, height: 24),
      );
}
