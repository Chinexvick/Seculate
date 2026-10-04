// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/back_arrow.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/tappable.dart';
import '../../data/backend.dart';
import '../../data/models.dart';
import 'tx_widgets.dart';

/// "My transactions": everything the user is borrowing, lending or working on.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Txn> _all = const [];
  bool _loading = true;
  String? _error;
  int _tab = 0;

  static const _tabs = ['Active', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final l = await backend.myTransactions();
      if (mounted)
        setState(() {
          _all = l;
          _loading = false;
        });
    } on BackendError catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = e.message;
        });
    }
  }

  bool _match(Txn t) {
    switch (_tab) {
      case 1:
        return t.state == 'released';
      case 2:
        return t.state == 'cancelled' || t.state == 'refunded';
      default:
        return t.state != 'released' &&
            t.state != 'cancelled' &&
            t.state != 'refunded';
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _all.where(_match).toList();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
              child: Row(
                children: const [
                  SizedBox(width: 24, child: BackArrow()),
                  SizedBox(width: 20),
                  Text('My transactions',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 22,
                        color: AppColors.black,
                      )),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
              child: Row(
                children: [
                  for (var i = 0; i < _tabs.length; i++) ...[
                    GestureDetector(
                      onTap: () => setState(() => _tab = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: _tab == i ? AppColors.primary : Colors.white,
                          border: Border.all(
                              color: _tab == i
                                  ? AppColors.primary
                                  : AppColors.neutral50),
                        ),
                        child: Text(_tabs[i],
                            style: AppText.body.copyWith(
                                color: _tab == i
                                    ? Colors.white
                                    : AppColors.neutral200)),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.neutral40),
            Expanded(child: _content(list)),
          ],
        ),
      ),
    );
  }

  Widget _content(List<Txn> list) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2));
    }
    Widget wrap(List<Widget> children) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
            children: children,
          ),
        );
    if (_error != null && _all.isEmpty) {
      return wrap([
        const SizedBox(height: 100),
        Center(
            child: Text(_error!,
                textAlign: TextAlign.center, style: AppText.body)),
        Center(
            child: TextButton(
                onPressed: _load,
                child: const Text('Retry',
                    style: TextStyle(color: AppColors.primary)))),
      ]);
    }
    if (list.isEmpty) {
      return wrap([
        const SizedBox(height: 100),
        Center(
            child: Text('No ${_tabs[_tab].toLowerCase()} transactions',
                style: AppText.body)),
      ]);
    }
    return wrap([
      for (var i = 0; i < list.length; i++)
        FadeSlideIn(
          delay: Duration(milliseconds: 40 * i),
          offset: 8,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _Row(list[i], () async {
              await Navigator.of(context)
                  .pushNamed(Routes.transaction, arguments: list[i].id);
              if (mounted) _load();
            }),
          ),
        ),
    ]);
  }
}

class _Row extends StatelessWidget {
  const _Row(this.t, this.onTap);
  final Txn t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bad = t.state == 'cancelled' ||
        t.state == 'disputed' ||
        t.state == 'refunded';
    return Tappable(
      onTap: onTap,
      scale: 0.985,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.title.isEmpty ? 'Transaction' : t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          AppText.title1.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                      '${isPayer(t) ? (t.kind == 'borrow' ? 'Borrowing' : 'Hiring') : (t.kind == 'borrow' ? 'Lending' : 'Working')} · ${dateLabel(t.createdAt)}',
                      style: AppText.body.copyWith(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(t.stateLabel,
                      style: AppText.body.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color:
                              bad ? AppColors.alert : AppColors.primaryDark)),
                ],
              ),
            ),
            Text(naira(t.total),
                style: AppText.title1.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
