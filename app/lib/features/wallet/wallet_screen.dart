import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/state_views.dart';
import '../../data/backend.dart';
import '../../data/backend_wallet.dart';
import '../../data/models.dart';
import '../outcome/outcome_screen.dart';
import '../requests/req_widgets.dart';

/// Wallet: balance, top up with a card/bank, withdraw to a bank account, and history.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with WidgetsBindingObserver {
  Map<String, dynamic>? _d;
  String? _error;
  bool _awaiting = false;
  num _before = 0;
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

  num get _balance => (_d?['balance'] as num?) ?? 0;
  Map<String, dynamic> get _settings =>
      Map<String, dynamic>.from((_d?['settings'] as Map?) ?? const {});

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final d = await backend.myWallet();
      if (mounted) setState(() => _d = d);
    } on BackendError catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _check() async {
    await backend.syncTopup();
    try {
      final d = await backend.myWallet();
      if (!mounted) return;
      final nb = (d['balance'] as num?) ?? 0;
      setState(() => _d = d);
      if (nb > _before) {
        _timer?.cancel();
        setState(() => _awaiting = false);
        await OutcomeScreen.show(context,
            title: 'Wallet topped up',
            message:
                'You added money to your wallet. Your new balance is shown on the wallet screen.',
            detail: '+${naira(nb - _before)}',
            buttonLabel: 'View balance');
      }
    } on BackendError {
      // keep polling quietly
    }
  }

  Future<void> _topUp() async {
    final min = (_settings['min_topup'] as num?) ?? 100;
    final amount = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AmountSheet(
          title: 'Top up wallet',
          cta: 'Continue to payment',
          min: min.toInt(),
          max: ((_settings['max_topup'] as num?) ?? 10000000).toInt()),
    );
    if (amount == null || !mounted) return;
    try {
      final link = await backend.startTopup(amount);
      final ok = await launchUrl(Uri.parse(link),
          mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (!ok) {
        AppToast.show(context, 'Could not open the payment page');
        return;
      }
      AppToast.show(context, 'Complete the payment, then come back to the app');
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
      setState(() {});
    } on BackendError catch (e) {
      if (mounted) AppToast.show(context, e.message);
    }
  }

  Future<void> _withdraw() async {
    if (_d?['verified'] != true) {
      final go = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Verify your identity first'),
          content: const Text(
              'To protect your money, withdrawals are only for verified accounts. It takes about a minute.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Not now')),
            TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Verify')),
          ],
        ),
      );
      if (go == true && mounted) {
        await Navigator.of(context)
            .pushNamed(Routes.identityVerification, arguments: false);
        _load();
      }
      return;
    }
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _WithdrawSheet(balance: _balance, settings: _settings),
    );
    if (done == true && mounted) {
      await _load();
      if (!mounted) return;
      await OutcomeScreen.show(context,
          title: 'Withdrawal requested',
          message:
              'Your withdrawal is on its way to your bank. We will email you when it lands, and you can follow it under withdrawals.',
          buttonLabel: 'Done');
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          const ReqHeader('Wallet'),
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
    final ledger = (d['ledger'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final wds = (d['withdrawals'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final fee = (_settings['withdrawal_fee'] as num?) ?? 0;
    return [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Wallet balance',
              style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  color: Colors.white)),
          const SizedBox(height: 4),
          Text(naira(_balance),
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
      Row(children: [
        Expanded(child: AppButton(label: 'Top up', onPressed: _topUp)),
        const SizedBox(width: 12),
        Expanded(
            child: AppButton(
                label: 'Withdraw',
                color: AppColors.black,
                onPressed: _withdraw)),
      ]),
      const SizedBox(height: 12),
      Text(
          'Use your wallet to buy credits and plans without a card. Withdrawals go to your own bank account'
          '${fee > 0 ? ' and cost ${naira(fee)}' : ''}. Escrow payments are paid by card or bank on the payment page.',
          style: AppText.body.copyWith(fontSize: 13)),
      const SizedBox(height: 22),
      if (wds.isNotEmpty) ...[
        Text('Withdrawals',
            style: AppText.title1.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        for (final w in wds)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${w['bank_name'] ?? 'Bank'} ••${'${w['account_number']}'.substring('${w['account_number']}'.length - 4)}',
                          style: AppText.title1.copyWith(fontSize: 14)),
                      Text(
                          '${_wdLabel('${w['status']}')} · ${shortDate(w['created_at'])}',
                          style: AppText.body.copyWith(fontSize: 12)),
                    ]),
              ),
              Text(naira(w['amount'] as num),
                  style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.black)),
            ]),
          ),
        const SizedBox(height: 10),
      ],
      Text('History',
          style: AppText.title1.copyWith(fontWeight: FontWeight.w500)),
      const SizedBox(height: 10),
      if (ledger.isEmpty)
        Text('No wallet activity yet. Top up to get started.',
            style: AppText.body),
      for (final h in ledger)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${h['note'] ?? 'Wallet activity'}',
                        style: AppText.title1.copyWith(fontSize: 14)),
                    Text(shortDate(h['created_at']),
                        style: AppText.body.copyWith(fontSize: 12)),
                  ]),
            ),
            Text(
                '${(h['delta'] as num) > 0 ? '+' : '-'}${naira((h['delta'] as num).abs())}',
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

  String _wdLabel(String s) => switch (s) {
        'successful' => 'Sent',
        'failed' => 'Failed, refunded',
        _ => 'Processing',
      };
}

class _AmountSheet extends StatefulWidget {
  const _AmountSheet(
      {required this.title,
      required this.cta,
      required this.min,
      required this.max});
  final String title, cta;
  final int min, max;

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  final _c = TextEditingController();
  int? get _v => int.tryParse(_c.text);
  bool get _ok => _v != null && _v! >= widget.min && _v! <= widget.max;

  @override
  void initState() {
    super.initState();
    _c.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          28, 24, 28, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(widget.title, style: AppText.h5),
        const SizedBox(height: 14),
        ReqField(
            label: 'Amount (₦)',
            controller: _c,
            hint: 'Min ${naira(widget.min)}',
            keyboard: TextInputType.number,
            digitsOnly: true,
            maxLength: 9),
        Wrap(spacing: 8, children: [
          for (final a in const [1000, 5000, 10000, 50000])
            ActionChip(
                label: Text(naira(a)),
                onPressed: () => setState(() => _c.text = '$a')),
        ]),
        const SizedBox(height: 16),
        AppButton(
            label: widget.cta,
            inactive: !_ok,
            onPressed: () {
              if (_ok) {
                Navigator.pop(context, _v);
              } else {
                AppToast.show(context,
                    'Enter ${naira(widget.min)} to ${naira(widget.max)}');
              }
            }),
      ]),
    );
  }
}

class _WithdrawSheet extends StatefulWidget {
  const _WithdrawSheet({required this.balance, required this.settings});
  final num balance;
  final Map<String, dynamic> settings;

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final _acct = TextEditingController();
  final _amt = TextEditingController();
  List<Map<String, String>> _banks = [];
  Map<String, String>? _bank;
  String? _name;
  String? _resolveError;
  bool _resolving = false, _busy = false, _loadingBanks = true;

  num get _fee => (widget.settings['withdrawal_fee'] as num?) ?? 0;
  int get _min => ((widget.settings['min_withdrawal'] as num?) ?? 1000).toInt();
  int? get _v => int.tryParse(_amt.text);
  bool get _amountOk =>
      _v != null && _v! >= _min && _v! + _fee <= widget.balance;
  bool get _ok => _bank != null && _name != null && _amountOk;

  @override
  void initState() {
    super.initState();
    _acct.addListener(_onAcct);
    _amt.addListener(() => setState(() {}));
    backend.banks().then((b) {
      if (mounted) {
        setState(() {
          _banks = b;
          _loadingBanks = false;
        });
      }
    }).catchError((_) {
      if (mounted) {
        setState(() => _loadingBanks = false);
        AppToast.show(context, 'Could not load banks. Try again.');
      }
    });
  }

  @override
  void dispose() {
    _acct.dispose();
    _amt.dispose();
    super.dispose();
  }

  Future<void> _pickBank() async {
    final b = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      builder: (_) => _BankPicker(banks: _banks),
    );
    if (b != null) {
      setState(() {
        _bank = b;
        _name = null;
      });
      _resolve();
    }
  }

  Future<void> _resolve() async {
    if (_bank == null || _acct.text.length != 10) {
      setState(() => _name = null);
      return;
    }
    setState(() {
      _resolving = true;
      _resolveError = null;
    });
    try {
      final n = await backend.resolveAccount(_bank!['code']!, _acct.text);
      if (mounted) setState(() => _name = n);
    } on BackendError catch (e) {
      if (mounted) setState(() => _resolveError = e.message);
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  Future<void> _go() async {
    if (!_ok || _busy) return;
    setState(() => _busy = true);
    try {
      final st = await backend.withdraw(
          amount: _v!,
          bankCode: _bank!['code']!,
          bankName: _bank!['name']!,
          account: _acct.text);
      if (!mounted) return;
      if (st == 'failed') {
        AppToast.show(context,
            'The bank could not accept this transfer. Your money was returned to your wallet.');
        Navigator.pop(context, false);
      } else {
        Navigator.pop(context, true);
      }
    } on BackendError catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        AppToast.show(context, e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          28, 24, 28, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Withdraw to bank', style: AppText.h5),
        const SizedBox(height: 6),
        Text('Available ${naira(widget.balance)}', style: AppText.body),
        const SizedBox(height: 14),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_bank?['name'] ?? 'Choose your bank'),
          trailing: _loadingBanks
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.expand_more),
          onTap: _loadingBanks ? null : _pickBank,
        ),
        const Divider(height: 1),
        const SizedBox(height: 14),
        ReqField(
            label: 'Account number',
            controller: _acct,
            keyboard: TextInputType.number,
            digitsOnly: true,
            maxLength: 10,
            hint: '10 digits'),
        if (_resolving)
          const Text('Checking account...', style: TextStyle(fontSize: 13)),
        if (_name != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Text('✓ $_name',
                style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark)),
          ),
        if (_resolveError != null)
          Align(
              alignment: Alignment.centerLeft,
              child: Text(_resolveError!,
                  style:
                      const TextStyle(color: Color(0xFFD6392B), fontSize: 13))),
        const SizedBox(height: 14),
        ReqField(
            label: 'Amount (₦)',
            controller: _amt,
            keyboard: TextInputType.number,
            digitsOnly: true,
            maxLength: 9,
            hint: 'Min ${naira(_min)}'),
        Text(
            'Fee ${naira(_fee)}. Total taken from wallet: ${naira((_v ?? 0) + _fee)}.',
            style: AppText.body.copyWith(fontSize: 12)),
        const SizedBox(height: 16),
        AppButton(
            label: 'Withdraw', loading: _busy, inactive: !_ok, onPressed: _go),
      ]),
    );
  }

  String _last = '';
  void _onAcct() {
    if (_acct.text == _last) return;
    _last = _acct.text;
    setState(() {
      _name = null;
      _resolveError = null;
    });
    if (_acct.text.length == 10) _resolve();
  }
}

class _BankPicker extends StatefulWidget {
  const _BankPicker({required this.banks});
  final List<Map<String, String>> banks;
  @override
  State<_BankPicker> createState() => _BankPickerState();
}

class _BankPickerState extends State<_BankPicker> {
  String _q = '';
  @override
  Widget build(BuildContext context) {
    final list = widget.banks
        .where((b) => b['name']!.toLowerCase().contains(_q.toLowerCase()))
        .toList();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          autofocus: true,
          decoration: const InputDecoration(
              hintText: 'Search bank', prefixIcon: Icon(Icons.search)),
          onChanged: (v) => setState(() => _q = v),
        ),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) => ListTile(
            title: Text(list[i]['name']!),
            onTap: () => Navigator.pop(context, list[i]),
          ),
        ),
      ),
    ]);
  }
}
