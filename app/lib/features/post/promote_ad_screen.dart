import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_arrow.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../data/backend.dart';
import '../../data/models.dart';

/// "Promote your ad": shows the perks of the user's real plan. No separate
/// paid promotion exists; visibility is included with higher plans.
class PromoteAdScreen extends StatefulWidget {
  const PromoteAdScreen({super.key});

  @override
  State<PromoteAdScreen> createState() => _PromoteAdScreenState();
}

class _PromoteAdScreenState extends State<PromoteAdScreen> {
  List<(String, String)>? _rows;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final st = await backend.planStatus();
      final plan = st['plan'];
      if (plan is! Map) throw BackendError('Could not load your plan.');
      final limit = plan['item_limit_per_month'];
      final days = plan['listing_duration_days'];
      final feats = plan['features'] is List
          ? List<String>.from(plan['features'] as List)
          : <String>[];
      final vis = feats.firstWhere((f) => f.startsWith('Visibility:'),
          orElse: () => 'Visibility: Standard');
      final price = Plan.fromRow(Map<String, dynamic>.from(plan)).price;
      if (!mounted) return;
      setState(() => _rows = [
            ('Current plan:', '${plan['emoji'] ?? ''} ${plan['name']}'.trim()),
            ('Price per month:', price == 0 ? '₦0' : naira(price)),
            ('Duration:', days == null ? 'Unlimited' : '$days days'),
            ('Visibility:', vis.replaceFirst('Visibility: ', '')),
            (
              'Ad Posting Limit',
              limit == null ? 'Unlimited' : '$limit per month'
            ),
          ]);
    } on BackendError catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _promote() {
    AppToast.show(
        context, 'Promotion is included with the Hustler and Top Lender plans');
    Navigator.of(context).pushNamed(Routes.pricing);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 14),
              Row(children: const [
                SizedBox(width: 32, child: BackArrow()),
                SizedBox(width: 12),
                Text('Promote your ad',
                    style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 22,
                        color: AppColors.black)),
              ]),
              const SizedBox(height: 28),
              FadeSlideIn(
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF4F5F7),
                      borderRadius: BorderRadius.circular(4)),
                  child: _error != null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(children: [
                            Text(_error!,
                                textAlign: TextAlign.center,
                                style: AppText.body),
                            TextButton(
                                onPressed: _load, child: const Text('Retry')),
                          ]),
                        )
                      : _rows == null
                          ? const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: CircularProgressIndicator()))
                          : Column(
                              children: [
                                for (final r in _rows!)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(r.$1,
                                            style: AppText.body
                                                .copyWith(fontSize: 15)),
                                        Text(r.$2,
                                            style: AppText.title1.copyWith(
                                                color: AppColors.black)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 32),
              AppButton(label: 'Promote ad', onPressed: _promote),
              const SizedBox(height: 14),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pushNamed(Routes.upgrade),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Upgrade plan',
                      style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: AppColors.primary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
