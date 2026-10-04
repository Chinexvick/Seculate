import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_arrow.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../data/backend.dart';
import '../../data/backend_wallet.dart';
import '../../data/models.dart';
import '../outcome/outcome_screen.dart';

/// "Want to Lend More? Unlock More Power" upsell.
class UpgradeIntroScreen extends StatelessWidget {
  const UpgradeIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 14, 28, 24),
          child: Column(
            children: [
              const BackArrow(),
              const Spacer(flex: 3),
              FadeSlideIn(
                child: Image.asset('assets/images/upgrade.png',
                    width: double.infinity, fit: BoxFit.fitWidth),
              ),
              const Spacer(flex: 2),
              const FadeSlideIn(
                delay: Duration(milliseconds: 100),
                child: Text('Want to Lend More?\nUnlock More Power',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 24,
                        height: 1.3,
                        color: AppColors.black)),
              ),
              const SizedBox(height: 8),
              const FadeSlideIn(
                delay: Duration(milliseconds: 150),
                child: Text(
                    'Upgrade your plan to list more items and enjoy extra visibility and perks.',
                    textAlign: TextAlign.center,
                    style: AppText.body),
              ),
              const SizedBox(height: 28),
              AppButton(
                label: 'Upgrade account',
                onPressed: () =>
                    Navigator.of(context).pushNamed(Routes.pricing),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PricingPlansScreen extends StatefulWidget {
  const PricingPlansScreen({super.key});

  @override
  State<PricingPlansScreen> createState() => _PricingPlansScreenState();
}

class _PricingPlansScreenState extends State<PricingPlansScreen>
    with WidgetsBindingObserver {
  final _scroll = ScrollController();
  final _listKey = GlobalKey();
  List<Plan>? _plans;
  Map<String, dynamic>? _status;
  String? _error;
  String? _paying; // plan id being purchased
  String? _awaiting; // plan id we are waiting to become active
  String? _fromPlan; // plan id before the purchase
  int _polls = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaiting != null) _check();
  }

  String? get _currentId {
    final p = _status?['plan'];
    return p is Map ? p['id'] as String? : null;
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final r = await Future.wait([backend.plans(), backend.planStatus()]);
      if (!mounted) return;
      setState(() {
        _plans = r[0] as List<Plan>;
        _status = r[1] as Map<String, dynamic>;
      });
    } on BackendError catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _check() async {
    try {
      if (_awaiting != null) await backend.syncPlanPayment();
      final st = await backend.planStatus();
      if (!mounted) return;
      setState(() => _status = st);
      final target = _awaiting;
      final now = (st['plan'] is Map) ? (st['plan'] as Map)['id'] : null;
      if (target != null &&
          (now == target || (now != _fromPlan && now != null))) {
        _timer?.cancel();
        setState(() => _awaiting = null);
        final nm = (st['plan'] is Map) ? '${(st['plan'] as Map)['name']}' : '';
        await OutcomeScreen.show(context,
            title: 'Plan active',
            message: 'Your $nm plan is now active on your account.',
            buttonLabel: 'Back to plans');
      }
    } on BackendError {
      // keep polling quietly
    }
  }

  void _startPolling(String planId) {
    _awaiting = planId;
    _fromPlan = _currentId;
    _polls = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 6), (t) {
      if (!mounted || _awaiting == null || ++_polls > 20) {
        t.cancel();
        if (mounted && _awaiting != null) setState(() => _awaiting = null);
        return;
      }
      _check();
    });
    setState(() {});
  }

  Future<void> _payWallet(Plan plan) async {
    setState(() => _paying = plan.id);
    try {
      await backend.walletPayPlan(plan.id);
      await _load();
      if (!mounted) return;
      await OutcomeScreen.show(context,
          title: 'Plan active',
          message:
              'Paid from your wallet. Your ${plan.name} plan is now active.',
          buttonLabel: 'Back to plans');
    } on BackendError catch (e) {
      if (mounted) {
        await OutcomeScreen.show(context,
            title: 'Payment not completed',
            message: e.message,
            ok: false,
            buttonLabel: 'Back to plans');
      }
    } finally {
      if (mounted) setState(() => _paying = null);
    }
  }

  Future<void> _choose(Plan plan) async {
    if (_paying != null) return;
    if (plan.price > 0) {
      final w = await showModalBottomSheet<bool>(
        context: context,
        builder: (c) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
                title: const Text('Pay with wallet'),
                onTap: () => Navigator.pop(c, true)),
            ListTile(
                title: const Text('Pay with card or bank transfer'),
                onTap: () => Navigator.pop(c, false)),
          ]),
        ),
      );
      if (w == null) return;
      if (w) return _payWallet(plan);
    }
    setState(() => _paying = plan.id);
    try {
      final link = await backend.startPlanPayment(plan.id);
      final ok = await launchUrl(Uri.parse(link),
          mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (!ok) {
        AppToast.show(context, 'Could not open the payment page');
      } else {
        AppToast.show(
            context, 'Complete the payment, then come back to the app');
        _startPolling(plan.id);
      }
    } on BackendError catch (e) {
      if (mounted) AppToast.show(context, e.message);
    } catch (_) {
      if (mounted) AppToast.show(context, 'Could not open the payment page');
    } finally {
      if (mounted) setState(() => _paying = null);
    }
  }

  String _date(String? iso) {
    final d = DateTime.tryParse(iso ?? '')?.toLocal();
    return d == null ? '' : '${d.day}/${d.month}/${d.year}';
  }

  Widget _currentCard() {
    final plans = _plans!;
    final cur = _status?['plan'];
    final id = cur is Map ? cur['id'] : null;
    final idx = plans.indexWhere((p) => p.id == id);
    final name = cur is Map ? '${cur['name']}' : '';
    final limit = cur is Map ? cur['item_limit_per_month'] : null;
    final used = (_status?['used_this_month'] as num?)?.toInt() ?? 0;
    final end = _date(_status?['period_end'] as String?);
    final price = cur is Map ? ((cur['price_ngn'] as num?) ?? 0) : 0;
    const w = TextStyle(
        fontFamily: AppTheme.fontFamily, fontSize: 10, color: Colors.white);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
          color: const Color(0xFF2BCF55),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Text('${idx < 0 ? 1 : idx + 1}',
              style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w500,
                  fontSize: 32,
                  color: Colors.white)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current level', style: w),
                Text(
                    'LV.${idx < 0 ? 1 : idx + 1}  $name${price == 0 ? ' (Free)' : ''}',
                    style:
                        w.copyWith(fontWeight: FontWeight.w500, fontSize: 14)),
                Text(
                    limit == null
                        ? '$used listed this month'
                        : '$used of $limit listed this month',
                    style: w),
                if (end.isNotEmpty) Text('Renews / ends $end', style: w),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              final ctx = _listKey.currentContext;
              if (ctx != null) {
                Scrollable.ensureVisible(ctx,
                    duration: const Duration(milliseconds: 300));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4000)),
              child: const Text('Upgrade',
                  style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: AppColors.primary)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plans = _plans;
    final curPrice = ((_status?['plan'] is Map
            ? (_status!['plan'] as Map)['price_ngn']
            : 0) as num?) ??
        0;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(28, 14, 28, 28),
            child: Column(
              children: [
                const Align(
                    alignment: Alignment.centerLeft, child: BackArrow()),
                const SizedBox(height: 4),
                const Text('Pricing Plans',
                    style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
                        color: AppColors.black)),
                const SizedBox(height: 8),
                const SizedBox(
                  width: 260,
                  child: Text(
                      'List for free. Upgrade to post more items and get noticed.',
                      textAlign: TextAlign.center,
                      style: AppText.body),
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Column(children: [
                      Text(_error!,
                          textAlign: TextAlign.center, style: AppText.body),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ]),
                  )
                else if (plans == null)
                  const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(child: CircularProgressIndicator()))
                else ...[
                  FadeSlideIn(child: _currentCard()),
                  if (_awaiting != null)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text('Waiting for your payment to be confirmed…',
                          textAlign: TextAlign.center, style: AppText.body),
                    ),
                  SizedBox(key: _listKey, height: 14),
                  for (var i = 0; i < plans.length; i++)
                    FadeSlideIn(
                      delay: Duration(milliseconds: 60 * (i + 1)),
                      child: _PlanCard(
                        plans[i],
                        current: plans[i].id == _currentId,
                        canChoose: plans[i].price > curPrice,
                        busy: _paying == plans[i].id,
                        onChoose: () => _choose(plans[i]),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard(this.plan,
      {required this.current,
      required this.canChoose,
      required this.busy,
      required this.onChoose});
  final Plan plan;
  final bool current;
  final bool canChoose;
  final bool busy;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    const t = TextStyle(
        fontFamily: AppTheme.fontFamily, fontSize: 13, color: AppColors.black);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: current ? AppColors.primary : AppColors.neutral40),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${plan.emoji} ${plan.name}',
              style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: AppColors.black)),
          const SizedBox(height: 8),
          Text(plan.priceLabel,
              style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14,
                  color: AppColors.black)),
          const SizedBox(height: 14),
          for (final p in plan.perks)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('✔ $p', style: t),
            ),
          if (current)
            const Text('Your current plan',
                style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: AppColors.primary))
          else if (canChoose) ...[
            const SizedBox(height: 6),
            AppButton(label: 'Choose plan', onPressed: onChoose, loading: busy),
          ],
        ],
      ),
    );
  }
}
