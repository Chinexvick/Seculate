// ignore_for_file: curly_braces_in_flow_control_structures
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_arrow.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/radio_sheet.dart';
import '../../data/backend.dart';
import '../../data/backend_wallet.dart';
import '../wallet/certificates_screen.dart';
import 'problem_flow.dart';
import '../../data/models.dart';
import 'tx_widgets.dart';

/// Status page for one transaction with role-appropriate actions.
class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key, required this.txId});
  final String txId;

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen>
    with WidgetsBindingObserver {
  Txn? _tx;
  bool _loading = true;
  String? _error;
  bool _busy = false;
  bool _awaitingPayment = false;
  StreamSubscription<Txn>? _sub;
  Map<String, dynamic>? _dispute;
  List<Map<String, dynamic>> _events = const [];
  Timer? _tick;

  static const _steps = [
    'Requested',
    'Accepted',
    'Paid (escrow)',
    'In use',
    'Returned',
    'Confirmed',
    'Released',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _sub = backend.watchTransaction(widget.txId).listen(_set, onError: (_) {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed && _tx != null) _load(silent: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  /// Dispute status + activity log for the deal (best effort; the page works without them).
  Future<void> _loadExtras() async {
    try {
      final r = await Future.wait([
        backend.disputeForTx(widget.txId),
        backend.txTimeline(widget.txId),
      ]);
      if (!mounted) return;
      setState(() {
        _dispute = r[0] as Map<String, dynamic>?;
        _events = r[1] as List<Map<String, dynamic>>;
      });
      _tick?.cancel();
      if (_payDeadline() != null) {
        _tick = Timer.periodic(const Duration(seconds: 30),
            (_) => mounted ? setState(() {}) : null);
      }
    } catch (_) {}
  }

  /// Payment must be made within 2 hours of the deal being agreed.
  DateTime? _payDeadline() {
    final t = _tx;
    if (t == null || (t.state != 'payment_pending' && t.state != 'accepted')) {
      return null;
    }
    for (final e in _events.reversed) {
      if (e['to_state'] == 'payment_pending' || e['to_state'] == 'accepted') {
        final at = DateTime.tryParse('${e['created_at']}');
        if (at != null) return at.add(const Duration(hours: 2));
      }
    }
    return null;
  }

  String _countdown(DateTime d) {
    final left = d.difference(DateTime.now());
    if (left.isNegative) return 'The payment window has ended.';
    final h = left.inHours, m = left.inMinutes % 60;
    return 'Pay within ${h > 0 ? '${h}h ' : ''}${m}m or this deal is cancelled.';
  }

  void _set(Txn t) {
    if (!mounted) return;
    final changed = _tx?.state != t.state;
    if (changed) _loadExtras();
    setState(() {
      _tx = t;
      _loading = false;
      _error = null;
      if (t.state != 'accepted' && t.state != 'payment_pending')
        _awaitingPayment = false;
    });
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = _tx == null;
        _error = null;
      });
    }
    try {
      _set(await backend.transaction(widget.txId));
      if (_events.isEmpty) _loadExtras();
    } on BackendError catch (e) {
      if (mounted && !silent)
        setState(() {
          _loading = false;
          _error = e.message;
        });
    }
  }

  Future<void> _do(Future<void> Function() f, {String? done}) async {
    setState(() => _busy = true);
    try {
      await f();
      if (!mounted) return;
      if (done != null) AppToast.show(context, done);
      await _load(silent: true);
    } on BackendError catch (e) {
      if (mounted) AppToast.show(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pay() async {
    setState(() => _busy = true);
    final ok = await payForTransaction(context, widget.txId);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _awaitingPayment = true;
    });
  }

  Future<void> _fulfil(Txn t) async {
    final r = await showModalBottomSheet<_Condition>(
      context: context,
      isScrollControlled: true,
      shape: sheetShape,
      backgroundColor: Colors.white,
      builder: (_) => _ConditionSheet(
        title: t.kind == 'borrow'
            ? 'Item condition on receipt'
            : 'Before work starts',
        button: t.kind == 'borrow' ? 'Confirm item received' : 'Start work',
      ),
    );
    if (r == null) return;
    _do(
        () => backend.startFulfilment(t.id,
            condition: r.condition, notes: r.notes, photos: r.photos),
        done: 'Saved.');
  }

  Future<void> _return(Txn t) async {
    final r = await showModalBottomSheet<_Condition>(
      context: context,
      isScrollControlled: true,
      shape: sheetShape,
      backgroundColor: Colors.white,
      builder: (_) => _ConditionSheet(
        title:
            t.kind == 'borrow' ? 'Item condition on return' : 'Completed work',
        button: t.kind == 'borrow' ? 'Return item' : 'Submit work',
      ),
    );
    if (r == null) return;
    _do(
        () => backend.submitReturn(t.id,
            condition: r.condition, notes: r.notes, photos: r.photos),
        done: 'Submitted.');
  }

  void _cert(Txn t) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => CertificateScreen(txId: t.id)));

  Future<void> _report(Txn t) async {
    final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => ReportProblemScreen(txId: t.id)));
    if (ok == true) {
      await _load(silent: true);
      _loadExtras();
    }
  }

  Future<void> _review(Txn t) async {
    final r = await showModalBottomSheet<_ReviewData>(
      context: context,
      isScrollControlled: true,
      shape: sheetShape,
      backgroundColor: Colors.white,
      builder: (_) => const _ReviewSheet(),
    );
    if (r == null) return;
    _do(() => backend.createReview(t.id, r.rating, body: r.body),
        done: 'Thanks for your review.');
  }

  Future<void> _confirmCancel(Txn t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this request?',
            style: TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cancel request',
                  style: TextStyle(color: AppColors.alert))),
        ],
      ),
    );
    if (ok == true)
      _do(() => backend.cancelTransaction(t.id), done: 'Cancelled.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 12),
              child: Row(
                children: const [
                  SizedBox(width: 24, child: BackArrow()),
                  SizedBox(width: 20),
                  Text('Transaction',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 22,
                        color: AppColors.black,
                      )),
                ],
              ),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2));
    }
    final t = _tx;
    if (t == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? 'Could not load this transaction.',
                  textAlign: TextAlign.center, style: AppText.body),
              const SizedBox(height: 16),
              PillButton('Retry', _load, filled: true, width: 120),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _load(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
        children: [
          FadeSlideIn(offset: 8, child: _header(t)),
          const SizedBox(height: 20),
          FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              offset: 8,
              child: _details(t)),
          const SizedBox(height: 24),
          FadeSlideIn(
              delay: const Duration(milliseconds: 120),
              offset: 8,
              child: _tracker(t)),
          const SizedBox(height: 24),
          ..._actions(t),
          DealTimeline(events: _events),
        ],
      ),
    );
  }

  Widget _header(Txn t) {
    final bad = const {'cancelled', 'disputed', 'refunded'}.contains(t.state);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.title.isEmpty ? 'Transaction' : t.title,
            style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w500,
                fontSize: 18,
                color: AppColors.black)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bad ? const Color(0xFFFDECEC) : const Color(0xFFECFCE8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(t.stateLabel,
              style: AppText.body.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: bad ? AppColors.alert : AppColors.primaryDark)),
        ),
        if ((t.cancelReason ?? '').isNotEmpty && t.state == 'cancelled')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Reason: ${t.cancelReason}',
                style: AppText.body.copyWith(fontSize: 12)),
          ),
      ],
    );
  }

  Widget _details(Txn t) {
    Widget row(String l, String v, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Expanded(child: Text(l, style: AppText.body)),
              Text(v,
                  style: AppText.title1.copyWith(
                      fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          row(t.kind == 'borrow' ? 'Rental amount' : 'Amount',
              naira(t.amount - t.securityFee)),
          if (t.securityFee > 0)
            row('Security fee (non-refundable)', naira(t.securityFee)),
          if (t.platformFee > 0) row('Service fee', naira(t.platformFee)),
          if (t.collateral > 0)
            row('Collateral (refundable)', naira(t.collateral)),
          const Divider(height: 16, color: AppColors.neutral40),
          row('Total', naira(t.total), bold: true),
          if (t.rentalDays > 0)
            row('Duration',
                '${t.rentalDays} day${t.rentalDays == 1 ? '' : 's'}'),
          if (t.startDate != null) row('Start', dateLabel(t.startDate)),
          if (t.dueDate != null) row('Due', dateLabel(t.dueDate)),
          if (t.txRef != null) row('Reference', t.txRef!),
        ],
      ),
    );
  }

  int _stepIndex(Txn t) {
    switch (t.state) {
      case 'requested':
        return 0;
      case 'accepted':
      case 'payment_pending':
        return 1;
      case 'escrow_held':
        return 2;
      case 'active':
        return 3;
      case 'return_pending':
        return 4;
      case 'confirmed':
      case 'release_pending':
        return 5;
      case 'released':
        return _steps.length;
      default:
        return -1;
    }
  }

  Widget _tracker(Txn t) {
    final idx = _stepIndex(t);
    if (idx < 0) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _steps.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < idx ? AppColors.primary : Colors.white,
                      border: Border.all(
                          color: i <= idx
                              ? AppColors.primary
                              : AppColors.neutral50,
                          width: 1.5),
                    ),
                    child: i < idx
                        ? const Icon(Icons.check, size: 13, color: Colors.white)
                        : i == idx
                            ? Center(
                                child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle)))
                            : null,
                  ),
                  if (i < _steps.length - 1)
                    Container(
                        width: 2,
                        height: 22,
                        color:
                            i < idx ? AppColors.primary : AppColors.neutral40),
                ],
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(_steps[i],
                    style: AppText.title1.copyWith(
                        fontWeight:
                            i == idx ? FontWeight.w500 : FontWeight.w400,
                        color:
                            i <= idx ? AppColors.black : AppColors.neutral100)),
              ),
            ],
          ),
      ],
    );
  }

  List<Widget> _actions(Txn t) {
    final out = <Widget>[];
    void add(Widget w) {
      out.add(w);
      out.add(const SizedBox(height: 12));
    }

    Widget btn(String label, VoidCallback f,
            {Color color = AppColors.primary, bool outline = false}) =>
        AppButton(
          label: label,
          loading: _busy,
          onPressed: _busy ? null : f,
          color: outline ? Colors.white : color,
          textColor: outline ? color : Colors.white,
        );

    final payer = isPayer(t);
    final payee = isPayee(t);
    switch (t.state) {
      case 'requested':
        if (payee) {
          add(btn(
              'Accept request',
              () => _do(() => backend.respondRequest(t.id, true),
                  done: 'Request accepted.')));
          add(btn(
              'Decline', () => _do(() => backend.respondRequest(t.id, false)),
              color: AppColors.alert, outline: true));
        } else if (payer) {
          add(btn('Cancel request', () => _confirmCancel(t),
              color: AppColors.alert, outline: true));
        }
        break;
      case 'accepted':
      case 'payment_pending':
        if (payer) {
          if (_awaitingPayment) {
            add(_info('Waiting for payment confirmation...', spinner: true));
          }
          final dl = _payDeadline();
          if (dl != null) add(_info(_countdown(dl)));
          add(btn(_awaitingPayment ? 'Pay again' : 'Pay securely', _pay));
          add(btn('Cancel request', () => _confirmCancel(t),
              color: AppColors.alert, outline: true));
        } else {
          add(_info('Waiting for the other person to pay into escrow.'));
          add(btn('Cancel request', () => _confirmCancel(t),
              color: AppColors.alert, outline: true));
        }
        break;
      case 'escrow_held':
        if (isWorker(t)) {
          add(btn(t.kind == 'borrow' ? 'Confirm item received' : 'Start work',
              () => _fulfil(t)));
        } else {
          add(_info(t.kind == 'borrow'
              ? 'Payment is secured. Hand the item over; the borrower confirms receipt.'
              : 'Payment is secured. Waiting for the work to start.'));
        }
        break;
      case 'active':
        if (isWorker(t)) {
          add(btn(t.kind == 'borrow' ? 'Return item' : 'Submit work',
              () => _return(t)));
        } else {
          add(_info(
              'In progress. You will be asked to confirm when it is returned.'));
        }
        break;
      case 'return_pending':
        if (isConfirmer(t)) {
          add(btn(
              'Confirm return OK',
              () => _do(() => backend.confirmReturn(t.id, true),
                  done: 'Confirmed.')));
          add(btn('Report a problem', () => _report(t),
              color: AppColors.alert, outline: true));
        } else {
          add(_info('Waiting for the other person to confirm.'));
        }
        break;
      case 'confirmed':
      case 'release_pending':
        add(_info('Funds are queued for release after review.'));
        add(btn('Leave a review', () => _review(t)));
        break;
      case 'released':
        add(btn('Leave a review', () => _review(t)));
        add(btn('View agreement certificate', () => _cert(t),
            color: AppColors.black, outline: true));
        break;
      case 'refunded':
        add(btn('View agreement certificate', () => _cert(t),
            color: AppColors.black, outline: true));
        break;
      case 'disputed':
        if (_dispute != null) {
          out.add(DisputeCard(
              txId: t.id,
              d: _dispute!,
              onChanged: () {
                _load(silent: true);
                _loadExtras();
              }));
        } else {
          add(_info(
              'A problem was reported. Funds are protected while our team reviews it.'));
        }
        break;
      default:
        break;
    }
    const disputable = {
      'escrow_held',
      'active',
      'return_pending',
      'confirmed',
      'release_pending'
    };
    if (disputable.contains(t.state) && (payer || payee)) {
      add(btn('Report a problem', () => _report(t),
          color: AppColors.alert, outline: true));
    }
    return out;
  }

  Widget _info(String text, {bool spinner = false}) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6F7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (spinner) ...[
              const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary)),
              const SizedBox(width: 10),
            ],
            Expanded(
                child: Text(text, style: AppText.body.copyWith(fontSize: 13))),
          ],
        ),
      );
}

class _Condition {
  const _Condition(this.condition, this.notes, this.photos);
  final String condition;
  final String? notes;
  final List<String> photos;
}

class _ConditionSheet extends StatefulWidget {
  const _ConditionSheet({required this.title, required this.button});
  final String title;
  final String button;

  @override
  State<_ConditionSheet> createState() => _ConditionSheetState();
}

class _ConditionSheetState extends State<_ConditionSheet> {
  String _cond = 'good';
  final _notes = TextEditingController();
  final List<String> _photos = [];
  final _picker = ImagePicker();

  static const _opts = {
    'excellent': 'Excellent',
    'good': 'Good',
    'fair': 'Fair',
    'damaged': 'Damaged',
  };

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _add(ImageSource s) async {
    if (_photos.length >= 4) return;
    try {
      final f =
          await _picker.pickImage(source: s, imageQuality: 80, maxWidth: 1600);
      if (f != null && mounted) setState(() => _photos.add(f.path));
    } catch (_) {
      if (mounted) AppToast.show(context, 'Could not open the photo picker.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          28, 20, 28, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SheetHeader(title: widget.title),
            const SizedBox(height: 16),
            Text('Condition', style: AppText.body),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in _opts.entries)
                  GestureDetector(
                    onTap: () => setState(() => _cond = e.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color:
                            _cond == e.key ? AppColors.primary : Colors.white,
                        border: Border.all(
                            color: _cond == e.key
                                ? AppColors.primary
                                : AppColors.neutral50),
                      ),
                      child: Text(e.value,
                          style: AppText.body.copyWith(
                              color: _cond == e.key
                                  ? Colors.white
                                  : AppColors.neutral200)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notes,
              maxLines: 3,
              style: AppText.title1,
              decoration: InputDecoration(
                hintText: 'Notes (optional)',
                hintStyle: AppText.body,
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.neutral50)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Photos (up to 4)', style: AppText.body),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _photos.length; i++)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(_photos[i]),
                            width: 64, height: 64, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: -6,
                        top: -6,
                        child: GestureDetector(
                          onTap: () => setState(() => _photos.removeAt(i)),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                                color: AppColors.black, shape: BoxShape.circle),
                            child: const Icon(Icons.close,
                                size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (_photos.length < 4) ...[
                  _AddBox(Icons.photo_library_outlined,
                      () => _add(ImageSource.gallery)),
                  _AddBox(Icons.photo_camera_outlined,
                      () => _add(ImageSource.camera)),
                ],
              ],
            ),
            const SizedBox(height: 20),
            AppButton(
              label: widget.button,
              onPressed: () => Navigator.pop(
                  context,
                  _Condition(
                      _cond,
                      _notes.text.trim().isEmpty ? null : _notes.text.trim(),
                      List.of(_photos))),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddBox extends StatelessWidget {
  const _AddBox(this.icon, this.onTap);
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.neutral50),
        ),
        child: Icon(icon, color: AppColors.neutral200),
      ),
    );
  }
}

class _ReviewData {
  const _ReviewData(this.rating, this.body);
  final int rating;
  final String? body;
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet();
  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int _rating = 0;
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          28, 20, 28, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHeader(title: 'Leave a review'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                GestureDetector(
                  onTap: () => setState(() => _rating = i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                        i <= _rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 38,
                        color: i <= _rating
                            ? const Color(0xFFFFB800)
                            : AppColors.neutral50),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _c,
            maxLines: 3,
            style: AppText.title1,
            decoration: InputDecoration(
              hintText: 'Share your experience (optional)',
              hintStyle: AppText.body,
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.neutral50)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary)),
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Submit review',
            onPressed: _rating == 0
                ? null
                : () => Navigator.pop(
                    context,
                    _ReviewData(_rating,
                        _c.text.trim().isEmpty ? null : _c.text.trim())),
          ),
        ],
      ),
    );
  }
}
