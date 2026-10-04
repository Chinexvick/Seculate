import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/state_views.dart';
import '../../data/backend.dart';
import '../../data/backend_credits.dart';
import '../../data/models.dart';
import '../outcome/outcome_screen.dart';
import '../requests/req_widgets.dart';
import '../../data/backend_wallet.dart';

/// Credits: balance, buy a bundle, and history. Credits are spent to post an
/// item request and to unlock a request you want to bid on.
class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen>
    with WidgetsBindingObserver {
  Map<String, dynamic>? _d;
  String? _error;
  String? _paying;
  bool _awaiting = false;
  int _before = 0;
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
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaiting) _check();
  }

  int get _balance => (_d?['balance'] as num?)?.toInt() ?? 0;

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final d = await backend.myCredits();
      if (mounted) setState(() => _d = d);
    } on BackendError catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _check() async {
    await backend.syncCreditPayment();
    try {
      final d = await backend.myCredits();
      if (!mounted) return;
      setState(() => _d = d);
      if (_balance > _before) {
        _timer?.cancel();
        setState(() => _awaiting = false);
        final added = _balance - _before;
        await OutcomeScreen.show(context,
            title: 'Credits added',
            message:
                'Your payment went through and the credits are in your balance.',
            detail: '+$added ${added == 1 ? 'credit' : 'credits'}',
            buttonLabel: 'Back to credits');
      }
    } on BackendError {
      // keep polling quietly
    }
  }

  Future<void> _buyWithWallet(Map<String, dynamic> b) async {
    if (_paying != null) return;
    setState(() => _paying = '${b['id']}');
    try {
      final before = _balance;
      await backend.walletPayCredits('${b['id']}');
      final d = await backend.myCredits();
      if (!mounted) return;
      setState(() => _d = d);
      final added = _balance - before;
      await OutcomeScreen.show(context,
          title: 'Credits added',
          message: 'Paid from your wallet. The credits are in your balance.',
          detail: '+$added ${added == 1 ? 'credit' : 'credits'}',
          buttonLabel: 'Back to credits');
    } on BackendError catch (e) {
      if (mounted) {
        await OutcomeScreen.show(context,
            title: 'Payment not completed',
            message: e.message,
            ok: false,
            buttonLabel: 'Back to credits');
      }
    } finally {
      if (mounted) setState(() => _paying = null);
    }
  }

  Future<void> _buy(Map<String, dynamic> b) async {
    if (_paying != null) return;
    setState(() => _paying = '${b['id']}');
    try {
      final link = await backend.startCreditPayment('${b['id']}');
      final ok = await launchUrl(Uri.parse(link),
          mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (!ok) {
        AppToast.show(context, 'Could not open the payment page');
      } else {
        AppToast.show(
            context, 'Complete the payment, then come back to the app');
        _before = _balance;
        _polls = 0;
        _awaiting = true;
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 6), (t) {
          if (!mounted || !_awaiting || ++_polls > 20) {
            t.cancel();
            if (mounted) setState(() => _awaiting = false);
            return;
          }
          _check();
        });
      }
    } on BackendError catch (e) {
      if (mounted) AppToast.show(context, e.message);
    } catch (_) {
      if (mounted) AppToast.show(context, 'Could not open the payment page');
    } finally {
      if (mounted) setState(() => _paying = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          const ReqHeader('Credits'),
          Expanded(
            child: d == null
                ? (_error != null
                    ? StateMessage(message: _error!, onAction: _load)
                    : const LoadingView())
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                      children: _body(d),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }

  List<Widget> _body(Map<String, dynamic> d) {
    final bundles = (d['bundles'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final history = (d['history'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final unlock = d['unlock_cost'] ?? 1;
    final post = d['request_cost'] ?? 1;
    return [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Your balance',
              style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  color: Colors.white)),
          const SizedBox(height: 4),
          Text('$_balance ${_balance == 1 ? 'credit' : 'credits'}',
              style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w600,
                  fontSize: 30,
                  color: Colors.white)),
          if (_awaiting) ...[
            const SizedBox(height: 8),
            const Text('Waiting for your payment to confirm...',
                style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    color: Colors.white)),
          ],
        ]),
      ),
      const SizedBox(height: 14),
      Text(
          'Posting an item request costs $post ${post == 1 ? 'credit' : 'credits'}. '
          'Unlocking a request to see its details and make an offer costs $unlock. '
          'If a request is not approved or is cancelled before review, your credit is returned.',
          style: AppText.body.copyWith(fontSize: 13)),
      const SizedBox(height: 22),
      Text('Buy credits',
          style: AppText.title1.copyWith(fontWeight: FontWeight.w500)),
      const SizedBox(height: 10),
      if (bundles.isEmpty)
        Text('No credit bundles are on sale right now.', style: AppText.body),
      for (final b in bundles)
        ReqCard(
          child: Row(children: [
            Expanded(
              child: Text('${b['credits']} credits',
                  style: AppText.title1.copyWith(fontWeight: FontWeight.w500)),
            ),
            TextButton(
              onPressed: _paying == null ? () => _buyWithWallet(b) : null,
              child: const Text('Use wallet'),
            ),
            SizedBox(
              width: 120,
              child: AppButton(
                label: naira(b['price_ngn'] as num),
                loading: _paying == '${b['id']}',
                onPressed: _paying == null ? () => _buy(b) : null,
              ),
            ),
          ]),
        ),
      const SizedBox(height: 18),
      Text('History',
          style: AppText.title1.copyWith(fontWeight: FontWeight.w500)),
      const SizedBox(height: 10),
      if (history.isEmpty) Text('No credit activity yet.', style: AppText.body),
      for (final h in history)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${h['note'] ?? 'Credit activity'}',
                        style: AppText.title1.copyWith(fontSize: 14)),
                    Text(shortDate(h['created_at']),
                        style: AppText.body.copyWith(fontSize: 12)),
                  ]),
            ),
            Text('${(h['delta'] as num) > 0 ? '+' : ''}${h['delta']}',
                style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: (h['delta'] as num) > 0
                        ? AppColors.primaryDark
                        : AppColors.black)),
          ]),
        ),
    ];
  }
}
