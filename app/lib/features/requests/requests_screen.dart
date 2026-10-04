import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/state_views.dart';
import '../../data/backend.dart';
import '../../data/backend_credits.dart';
import '../../data/models.dart';
import 'req_widgets.dart';

/// Item requests: things people near you are looking to borrow, and your own.
class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  int _tab = 0;
  List<Map<String, dynamic>>? _nearby;
  List<Map<String, dynamic>>? _mine;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final r =
          await Future.wait([backend.nearbyRequests(), backend.myRequests()]);
      if (mounted) {
        setState(() {
          _nearby = r[0];
          _mine = r[1];
        });
      }
    } on BackendError catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _open(String id) async {
    await Navigator.of(context).pushNamed(Routes.requestDetail, arguments: id);
    if (mounted) _load();
  }

  Future<void> _post() async {
    final ok = await Navigator.of(context).pushNamed(Routes.postRequest);
    if (ok == true && mounted) {
      AppToast.show(context, 'Request sent for review');
      setState(() => _tab = 1);
    }
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    const tabs = ['Nearby requests', 'My requests'];
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          const ReqHeader('Item requests'),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
            child: Row(children: [
              for (var i = 0; i < tabs.length; i++) ...[
                GestureDetector(
                  onTap: () => setState(() => _tab = i),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: _tab == i ? AppColors.primary : Colors.white,
                      border: Border.all(
                          color: _tab == i
                              ? AppColors.primary
                              : AppColors.neutral50),
                    ),
                    child: Text(tabs[i],
                        style: AppText.body.copyWith(
                            color: _tab == i
                                ? Colors.white
                                : AppColors.neutral200)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ]),
          ),
          const Divider(height: 1, color: AppColors.neutral40),
          Expanded(child: _content()),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
            child: AppButton(label: 'Post a request', onPressed: _post),
          ),
        ]),
      ),
    );
  }

  Widget _content() {
    final list = _tab == 0 ? _nearby : _mine;
    if (list == null) {
      return _error != null
          ? StateMessage(message: _error!, onAction: _load)
          : const LoadingView();
    }
    final empty = _tab == 0
        ? 'No requests near you right now. Check back soon.'
        : 'You have not posted a request yet. Tell people nearby what you need to borrow.';
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
        children: [
          if (list.isEmpty) ...[
            const SizedBox(height: 80),
            Center(
                child: Text(empty,
                    textAlign: TextAlign.center, style: AppText.body)),
          ],
          for (final r in list)
            _RequestRow(r, mine: _tab == 1, onTap: () => _open('${r['id']}')),
        ],
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow(this.r, {required this.mine, required this.onTap});
  final Map<String, dynamic> r;
  final bool mine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final budget = (r['budget_ngn'] as num?) ?? 0;
    final bids = (r['bid_count'] as num?)?.toInt() ?? 0;
    final dist = r['distance_km'];
    return ReqCard(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text('${r['title']}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.title1.copyWith(fontWeight: FontWeight.w500)),
          ),
          if (mine) StatusPill('${r['status']}'),
        ]),
        const SizedBox(height: 6),
        Text(
            [
              if (budget > 0) 'Budget ${naira(budget)}',
              '${r['duration_days']} ${r['duration_days'] == 1 ? 'day' : 'days'}',
              if (!mine && dist != null) '$dist km away',
              if ('${r['area'] ?? ''}'.isNotEmpty) '${r['area']}',
            ].join('  ·  '),
            style: AppText.body.copyWith(fontSize: 12)),
        const SizedBox(height: 4),
        Text(
            [
              if (mine && r['status'] == 'open')
                '$bids ${bids == 1 ? 'offer' : 'offers'}',
              if (r['status'] == 'open') expiresIn(r['expires_at']),
              if (!mine && r['my_bid'] != null) 'You made an offer',
              if (!mine && r['unlocked'] == true && r['my_bid'] == null)
                'Unlocked',
            ].where((e) => e.isNotEmpty).join('  ·  '),
            style: AppText.body.copyWith(
                fontSize: 12,
                color: AppColors.primaryDark,
                fontFamily: AppTheme.fontFamily)),
      ]),
    );
  }
}
