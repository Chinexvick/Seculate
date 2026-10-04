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
import 'post_request_screen.dart';
import 'req_widgets.dart';

/// One request. The requester sees offers and can accept, counter or decline.
/// A lender unlocks it (credits), then makes an offer and negotiates.
class RequestDetailScreen extends StatefulWidget {
  const RequestDetailScreen({super.key, required this.id});
  final String id;

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  Map<String, dynamic>? _d;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await backend.requestDetail(widget.id);
      if (mounted) {
        setState(() {
          _d = d;
          _error = null;
        });
      }
    } on BackendError catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _do(Future<void> Function() f, {String? done}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await f();
      if (done != null && mounted) AppToast.show(context, done);
      await _load();
    } on BackendError catch (e) {
      if (mounted) AppToast.show(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _goDeal(String? txId) {
    if (txId == null) return;
    Navigator.of(context).pushNamed(Routes.transaction, arguments: txId);
  }

  Future<void> _unlock() async {
    final d = _d!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlock this request?'),
        content: const Text(
            'Unlocking uses credits and lets you see the full details and make an offer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Unlock',
                  style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
    if (ok != true) return;
    await _do(() async {
      try {
        await backend.unlockRequest('${d['id']}');
      } on BackendError catch (e) {
        if (e.message.contains('Not enough credits') && mounted) {
          Navigator.of(context).pushNamed(Routes.credits);
          throw BackendError('You need more credits to unlock this request.');
        }
        rethrow;
      }
    }, done: 'Unlocked');
  }

  /// Price + message sheet used for a first offer and for counter offers.
  Future<void> _priceSheet(
      {required String title,
      required String action,
      num? initial,
      bool deposit = false,
      required Future<void> Function(num price, num deposit, String msg)
          onSend}) async {
    final price =
        TextEditingController(text: initial == null ? '' : '$initial');
    final dep = TextEditingController();
    final msg = TextEditingController();
    final go = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 22, 24, 22 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Align(
              alignment: Alignment.centerLeft,
              child: Text(title,
                  style: AppText.title1
                      .copyWith(fontWeight: FontWeight.w500, fontSize: 18))),
          const SizedBox(height: 14),
          ReqField(
              label: 'Price for the whole period',
              controller: price,
              prefix: '₦ ',
              keyboard: TextInputType.number,
              digitsOnly: true),
          if (deposit)
            ReqField(
                label: 'Deposit you want held (optional)',
                controller: dep,
                prefix: '₦ ',
                keyboard: TextInputType.number,
                digitsOnly: true),
          ReqField(
              label: 'Message (optional)',
              controller: msg,
              maxLines: 2,
              maxLength: 300,
              hint: 'No phone numbers or links'),
          AppButton(label: action, onPressed: () => Navigator.pop(ctx, true)),
        ]),
      ),
    );
    final p = num.tryParse(price.text.trim());
    final dp = num.tryParse(dep.text.trim()) ?? 0;
    final m = msg.text.trim();
    price.dispose();
    dep.dispose();
    msg.dispose();
    if (go != true) return;
    if (p == null) {
      if (mounted) AppToast.show(context, 'Enter a price');
      return;
    }
    await _do(() => onSend(p, dp, m), done: 'Sent');
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          const ReqHeader('Request'),
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
                      children: [
                        _summary(d),
                        const SizedBox(height: 16),
                        if (d['mine'] == true) ..._owner(d) else ..._lender(d),
                      ],
                    ),
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _summary(Map<String, dynamic> d) {
    final budget = (d['budget_ngn'] as num?) ?? 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: Text('${d['title']}',
              style: AppText.title1
                  .copyWith(fontWeight: FontWeight.w500, fontSize: 20)),
        ),
        if (d['mine'] == true) StatusPill('${d['status']}'),
      ]),
      const SizedBox(height: 8),
      Text(
          [
            if (budget > 0) 'Budget ${naira(budget)}',
            '${d['duration_days']} ${d['duration_days'] == 1 ? 'day' : 'days'}',
            'From ${shortDate(d['needed_from'])}',
            if ('${d['area'] ?? ''}'.isNotEmpty) '${d['area']}',
          ].join('  ·  '),
          style: AppText.body.copyWith(fontSize: 13)),
      if (d['status'] == 'open')
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(expiresIn(d['expires_at']),
              style: AppText.body
                  .copyWith(fontSize: 12, color: AppColors.primaryDark)),
        ),
      const SizedBox(height: 14),
      if (d['unlocked'] == true)
        Text(
            ('${d['description'] ?? ''}').isEmpty
                ? 'No extra details.'
                : '${d['description']}',
            style: AppText.title1.copyWith(fontSize: 14))
      else
        Text('Details are hidden until you unlock this request.',
            style: AppText.body),
    ]);
  }

  // ───────── requester ─────────

  List<Widget> _owner(Map<String, dynamic> d) {
    final status = '${d['status']}';
    final bids = (d['bids'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final out = <Widget>[];
    if ((d['review_note'] ?? '').toString().isNotEmpty &&
        (status == 'changes_requested' || status == 'rejected')) {
      out.add(ReqCard(
          child: Text('From our team: ${d['review_note']}',
              style: AppText.body.copyWith(color: AppColors.black))));
    }
    if (status == 'pending_review') {
      out.add(Text(
          'We are checking your request. Nearby lenders will see it once it is approved.',
          style: AppText.body));
    }
    if (status == 'matched') {
      out.add(Text(
          'You found a lender. Open the deal from My transactions to pay into escrow.',
          style: AppText.body));
    }
    if (status == 'expired') {
      out.add(
          Text('This request expired without a deal.', style: AppText.body));
    }
    if (status == 'open' || status == 'matched') {
      out.add(const SizedBox(height: 8));
      out.add(Text('Offers (${bids.length})',
          style: AppText.title1.copyWith(fontWeight: FontWeight.w500)));
      out.add(const SizedBox(height: 10));
      if (bids.isEmpty) {
        out.add(Text(
            'No offers yet. We will notify you when someone makes one.',
            style: AppText.body));
      }
      for (final b in bids) {
        out.add(_bidCard(b, status == 'open'));
      }
    }
    if (status == 'open' ||
        status == 'pending_review' ||
        status == 'changes_requested') {
      out.add(const SizedBox(height: 14));
      out.add(AppButton(
          label: 'Edit request',
          loading: _busy,
          onPressed: _busy
              ? null
              : () async {
                  final ok = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                          builder: (_) => PostRequestScreen(editing: d)));
                  if (ok == true) _load();
                }));
      if (status == 'open' && bids.isNotEmpty) {
        out.add(Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
                'Editing sends it back for review and clears current offers.',
                style: AppText.body.copyWith(fontSize: 12))));
      }
      out.add(const SizedBox(height: 10));
      out.add(AppButton(
          label: 'Cancel request',
          color: AppColors.black,
          loading: _busy,
          onPressed: _busy
              ? null
              : () => _do(() => backend.cancelRequest('${d['id']}'),
                  done: 'Request cancelled')));
    }
    if (status == 'expired') {
      out.add(const SizedBox(height: 14));
      out.add(AppButton(
          label: 'Reuse for free (once)',
          loading: _busy,
          onPressed: _busy
              ? null
              : () => _do(() async {
                    await backend.reuseRequest('${d['id']}');
                    if (mounted) Navigator.of(context).pop();
                  }, done: 'Request is live again')));
    }
    return out;
  }

  Widget _bidCard(Map<String, dynamic> b, bool open) {
    final status = '${b['status']}';
    final counter = status == 'counter_offered';
    final byMe = b['counter_by_me'] == true;
    final round = (b['counter_round'] as num?)?.toInt() ?? 0;
    final deposit = (b['deposit_ngn'] as num?) ?? 0;
    return ReqCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text('${b['lender']}'.trim(),
                style: AppText.title1.copyWith(fontWeight: FontWeight.w500)),
          ),
          StatusPill(status),
        ]),
        const SizedBox(height: 4),
        Text(
            '${naira(b['price_ngn'] as num)}'
            '${deposit > 0 ? '  ·  Deposit ${naira(deposit)}' : ''}'
            '${(b['rating'] as num?) != null && (b['rating'] as num) > 0 ? '  ·  ★ ${(b['rating'] as num).toStringAsFixed(1)}' : ''}',
            style: AppText.body.copyWith(color: AppColors.black)),
        if ('${b['message'] ?? ''}'.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('${b['message']}', style: AppText.body.copyWith(fontSize: 13)),
        ],
        if (counter) ...[
          const SizedBox(height: 6),
          Text(
              '${byMe ? 'You countered' : 'They countered'} at ${naira(b['counter_price'] as num)} (round $round of 3)'
              '${'${b['counter_message'] ?? ''}'.isNotEmpty ? ': ${b['counter_message']}' : ''}',
              style: AppText.body
                  .copyWith(fontSize: 13, color: AppColors.primaryDark)),
        ],
        if (open && (status == 'submitted' || (counter && !byMe))) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: AppButton(
                  label: counter ? 'Accept counter' : 'Accept',
                  onPressed: _busy
                      ? null
                      : () => _do(() async {
                            final tx = counter
                                ? await backend.respondCounter(
                                    '${b['id']}', true)
                                : await backend.acceptBid('${b['id']}');
                            _goDeal(tx);
                          },
                              done:
                                  'Deal agreed. Pay into escrow to secure it.')),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            if (round < 3)
              Expanded(
                child: AppButton(
                    label: 'Counter',
                    color: AppColors.black,
                    onPressed: _busy
                        ? null
                        : () => _priceSheet(
                            title: 'Counter offer',
                            action: 'Send counter',
                            initial: counter
                                ? b['counter_price'] as num
                                : b['price_ngn'] as num,
                            onSend: (p, _, m) =>
                                backend.counterBid('${b['id']}', p, m))),
              ),
            if (round < 3) const SizedBox(width: 8),
            Expanded(
              child: AppButton(
                  label: 'Decline',
                  color: AppColors.alert,
                  onPressed: _busy
                      ? null
                      : () => _do(() async {
                            if (counter) {
                              await backend.respondCounter('${b['id']}', false);
                            } else {
                              await backend.rejectBid('${b['id']}');
                            }
                          }, done: 'Declined')),
            ),
          ]),
        ],
        if (open && counter && byMe)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Waiting for the lender to respond.',
                style: AppText.body.copyWith(fontSize: 12)),
          ),
      ]),
    );
  }

  // ───────── lender ─────────

  static const _cancelPick = '__cancel__';

  /// Lets a lender attach one of their live items to the offer (optional).
  /// Returns the listing id, null for "no item", or [_cancelPick] if dismissed.
  Future<String?> _pickListing() async {
    List<Product> mine = const [];
    try {
      mine = (await backend.myListings())
          .where((p) => p.status == 'live')
          .toList();
    } catch (_) {}
    if (mine.isEmpty || !mounted) return null;
    final r = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => SafeArea(
        child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Offer one of your items?', style: AppText.h5),
              const SizedBox(height: 6),
              Text(
                  'Attach a listing so the requester can see exactly what you would lend. This is optional.',
                  style: AppText.body.copyWith(fontSize: 13)),
              const SizedBox(height: 8),
              for (final p in mine)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(p.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${naira(p.pricePerDay)} / day'),
                  onTap: () => Navigator.pop(c, p.id),
                ),
              TextButton(
                  onPressed: () => Navigator.pop(c, ''),
                  child: const Text('Continue without an item')),
            ]),
      ),
    );
    if (r == null) return _cancelPick;
    return r.isEmpty ? null : r;
  }

  List<Widget> _lender(Map<String, dynamic> d) {
    final status = '${d['status']}';
    final bid = d['my_bid'] is Map
        ? Map<String, dynamic>.from(d['my_bid'] as Map)
        : null;
    if (status != 'open' && bid == null) {
      return [Text('This request is no longer open.', style: AppText.body)];
    }
    if (d['unlocked'] != true) {
      return [
        AppButton(
            label: 'Unlock to make an offer',
            loading: _busy,
            onPressed: _busy ? null : _unlock),
      ];
    }
    if (bid == null || ['rejected', 'withdrawn'].contains(bid['status'])) {
      return [
        if (bid != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
                bid['status'] == 'rejected'
                    ? 'Your last offer was declined. You can make a new one.'
                    : 'You withdrew your last offer.',
                style: AppText.body),
          ),
        AppButton(
            label: 'Make an offer',
            onPressed: _busy
                ? null
                : () async {
                    final listing = await _pickListing();
                    if (!mounted || listing == _cancelPick) return;
                    _priceSheet(
                        title: 'Your offer',
                        action: 'Send offer',
                        deposit: true,
                        onSend: (p, dp, m) => backend.submitBid('${d['id']}',
                            price: p,
                            deposit: dp,
                            message: m,
                            listingId: listing));
                  }),
      ];
    }
    final st = '${bid['status']}';
    final counter = st == 'counter_offered';
    final byMe = bid['counter_by_me'] == true;
    final round = (bid['counter_round'] as num?)?.toInt() ?? 0;
    return [
      ReqCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text('Your offer: ${naira(bid['price_ngn'] as num)}',
                  style: AppText.title1.copyWith(fontWeight: FontWeight.w500)),
            ),
            StatusPill(st),
          ]),
          if (counter) ...[
            const SizedBox(height: 6),
            Text(
                '${byMe ? 'You countered' : 'The requester countered'} at ${naira(bid['counter_price'] as num)} (round $round of 3)',
                style: AppText.body
                    .copyWith(fontSize: 13, color: AppColors.primaryDark)),
          ],
          if (st == 'accepted') ...[
            const SizedBox(height: 6),
            Text('Your offer was accepted. Open the deal to continue.',
                style: AppText.body.copyWith(fontSize: 13)),
          ],
        ]),
      ),
      if (counter && !byMe) ...[
        Row(children: [
          Expanded(
            child: AppButton(
                label: 'Accept counter',
                onPressed: _busy
                    ? null
                    : () => _do(() async {
                          final tx = await backend.respondCounter(
                              '${bid['id']}', true);
                          _goDeal(tx);
                        }, done: 'Deal agreed. Waiting for payment.')),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          if (round < 3)
            Expanded(
              child: AppButton(
                  label: 'Counter',
                  color: AppColors.black,
                  onPressed: _busy
                      ? null
                      : () => _priceSheet(
                          title: 'Counter offer',
                          action: 'Send counter',
                          initial: bid['counter_price'] as num,
                          onSend: (p, _, m) =>
                              backend.counterBid('${bid['id']}', p, m))),
            ),
          if (round < 3) const SizedBox(width: 8),
          Expanded(
            child: AppButton(
                label: 'Decline',
                color: AppColors.alert,
                onPressed: _busy
                    ? null
                    : () => _do(
                        () => backend.respondCounter('${bid['id']}', false),
                        done: 'Declined')),
          ),
        ]),
      ] else if (st == 'submitted' || counter) ...[
        AppButton(
            label: 'Withdraw offer',
            color: AppColors.black,
            onPressed: _busy
                ? null
                : () => _do(() => backend.withdrawBid('${bid['id']}'),
                    done: 'Offer withdrawn')),
      ],
      if (st == 'accepted' && bid['transaction_id'] != null)
        AppButton(
            label: 'Open deal',
            onPressed: () => _goDeal('${bid['transaction_id']}')),
    ];
  }
}
