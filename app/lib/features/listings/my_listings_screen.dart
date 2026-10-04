import 'package:flutter/material.dart';
import '../../data/backend_credits.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_arrow.dart';
import '../../core/widgets/tappable.dart';
import '../../core/widgets/app_image.dart';
import '../../data/backend.dart';
import '../../data/backend_mylistings.dart';
import '../../data/models.dart';
import '../post/list_item_screen.dart';

class _Listing {
  const _Listing(
      {required this.id,
      required this.name,
      required this.price,
      required this.image,
      required this.status,
      this.note,
      this.product,
      this.isTask = false});
  final String id;
  final String name;
  final int price;
  final String image;
  final String status;
  final String? note;
  final Product? product;
  final bool isTask;

  bool get pausable => !isTask && (status == 'live' || status == 'paused');

  bool get editable =>
      !isTask && (status == 'changes_requested' || status == 'rejected');
}

({String label, Color color}) _chip(String s) {
  switch (s) {
    case 'pending_review':
      return (label: 'Under review', color: const Color(0xFFE59B00));
    case 'changes_requested':
      return (label: 'Changes requested', color: const Color(0xFFE59B00));
    case 'live':
    case 'open':
      return (label: 'Live', color: AppColors.primary);
    case 'rejected':
      return (label: 'Rejected', color: AppColors.alert);
    case 'suspended':
      return (label: 'Suspended', color: AppColors.alert);
    case 'reserved':
      return (label: 'Borrowed', color: const Color(0xFF3B82F6));
    case 'paused':
      return (label: 'Paused', color: AppColors.neutral200);
    case 'draft':
      return (label: 'Draft', color: AppColors.neutral200);
    default:
      return (
        label: s.isEmpty
            ? 'Unknown'
            : '${s[0].toUpperCase()}${s.substring(1).replaceAll('_', ' ')}',
        color: AppColors.neutral200
      );
  }
}

/// "My listings" table: product, price, status and actions.
class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  final _search = TextEditingController();
  List<_Listing>? _all;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await Future.wait([backend.myListings(), backend.myTasks()]);
      final items = r[0] as List<Product>;
      final tasks = r[1] as List<ServiceItem>;
      if (!mounted) return;
      setState(() {
        _error = null;
        _all = [
          for (final p in items)
            if (p.status != 'archived')
              _Listing(
                  id: p.id,
                  name: p.name,
                  price: p.pricePerDay,
                  image: p.image,
                  status: p.status,
                  note: p.reviewNote,
                  product: p),
          for (final t in tasks)
            if (t.status != 'cancelled')
              _Listing(
                  id: t.id,
                  name: t.name,
                  price: t.price ?? 0,
                  image: '',
                  status: t.status,
                  note: t.reviewNote,
                  isTask: true),
        ];
      });
    } on BackendError catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _pause(_Listing l) async {
    final pause = l.status != 'paused';
    try {
      await backend.setListingPaused(l.id, pause);
      if (!mounted) return;
      AppToast.show(
          context,
          pause
              ? 'Listing paused. People can\'t see it.'
              : 'Listing is live again.');
      _load();
    } on BackendError catch (e) {
      if (mounted) AppToast.show(context, e.message);
    }
  }

  Future<void> _edit(_Listing l) async {
    final p = l.product;
    if (p == null) return;
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ListItemScreen(editing: p)));
    if (mounted) _load();
  }

  Future<void> _delete(_Listing l) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Delete this listing?',
              style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: AppColors.black)),
          const SizedBox(height: 8),
          Text(l.name, textAlign: TextAlign.center, style: AppText.body),
          const SizedBox(height: 22),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    side: const BorderSide(color: AppColors.neutral50),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.black)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.alert,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Delete'),
              ),
            ),
          ]),
        ]),
      ),
    );
    if (ok == true && mounted) {
      try {
        if (l.isTask) {
          await backend.archiveTask(l.id);
        } else {
          await backend.archiveListing(l.id);
        }
        if (!mounted) return;
        setState(() => _all?.removeWhere((x) => x.id == l.id));
        AppToast.show(context, 'Listing deleted');
      } on BackendError catch (e) {
        if (mounted) AppToast.show(context, e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final all = _all ?? const <_Listing>[];
    final rows = q.isEmpty
        ? all
        : all.where((l) => l.name.toLowerCase().contains(q)).toList();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Row(children: [
                    const SizedBox(width: 32, child: BackArrow()),
                    const SizedBox(width: 8),
                    const Text('My listings',
                        style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: AppColors.black)),
                    const Spacer(),
                    Container(
                      width: 150,
                      height: 24,
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: AppColors.neutral50)),
                      child: Row(children: [
                        Expanded(
                          child: TextField(
                            controller: _search,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 11,
                                color: AppColors.black),
                            decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'search',
                                hintStyle: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 10,
                                    color: AppColors.neutral100)),
                          ),
                        ),
                        SvgPicture.asset('assets/icons/search_gray.svg',
                            width: 14, height: 14),
                      ]),
                    ),
                  ]),
                ),
                Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: const BoxDecoration(
                    border: Border.symmetric(
                        horizontal: BorderSide(color: AppColors.neutral40)),
                  ),
                  child: const Row(children: [
                    Expanded(flex: 5, child: _Head('Product name')),
                    Expanded(flex: 2, child: _Head('Price')),
                    SizedBox(width: 92, child: _Head('Action', right: true)),
                  ]),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
                      children: [
                        if (_error != null && _all == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Column(children: [
                              Text(_error!,
                                  textAlign: TextAlign.center,
                                  style: AppText.body),
                              TextButton(
                                  onPressed: _load, child: const Text('Retry')),
                            ]),
                          )
                        else if (_all == null)
                          const Padding(
                              padding: EdgeInsets.only(top: 60),
                              child: Center(child: CircularProgressIndicator()))
                        else ...[
                          for (var i = 0; i < rows.length; i++)
                            _Row(
                              rows[i],
                              onEdit: rows[i].editable
                                  ? () => _edit(rows[i])
                                  : null,
                              onDelete: () => _delete(rows[i]),
                              onPause: rows[i].pausable
                                  ? () => _pause(rows[i])
                                  : null,
                            ),
                          if (rows.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: Center(
                                  child: Text('No listings found',
                                      style: AppText.body)),
                            ),
                        ],
                        const SizedBox(height: 18),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Tappable(
                            onTap: () async {
                              await Navigator.of(context)
                                  .pushNamed(Routes.listItem);
                              if (mounted) _load();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 7),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4000),
                                  border: Border.all(color: AppColors.primary)),
                              child: const Text('Add to list',
                                  style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 11,
                                      color: AppColors.black)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 22,
              bottom: 24,
              child: Tappable(
                onTap: () => Navigator.of(context).pushNamed(Routes.support),
                child: SvgPicture.asset('assets/icons/headset.svg',
                    width: 52, height: 52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Head extends StatelessWidget {
  const _Head(this.t, {this.right = false});
  final String t;
  final bool right;
  @override
  Widget build(BuildContext context) => Align(
        alignment: right ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(t,
            style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12,
                color: AppColors.black)),
      );
}

class _Row extends StatelessWidget {
  const _Row(this.l,
      {required this.onEdit, required this.onDelete, this.onPause});
  final _Listing l;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onPause;

  @override
  Widget build(BuildContext context) {
    const small = TextStyle(
        fontFamily: AppTheme.fontFamily, fontSize: 10, color: AppColors.black);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(children: [
        Expanded(
          flex: 5,
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: AppImage(l.image, width: 38, height: 30),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: small.copyWith(fontWeight: FontWeight.w500)),
                  Text(_chip(l.status).label,
                      style: small.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: _chip(l.status).color)),
                  if ((l.status == 'changes_requested' ||
                          l.status == 'rejected') &&
                      (l.note ?? '').isNotEmpty)
                    Text(l.note!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: small.copyWith(
                            fontSize: 8, color: AppColors.neutral200)),
                ],
              ),
            ),
          ]),
        ),
        Expanded(
          flex: 2,
          child: Text(naira(l.price), style: small),
        ),
        SizedBox(
          width: 92,
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                    color: _chip(l.status).color, shape: BoxShape.circle)),
            const SizedBox(width: 16),
            if (onEdit != null)
              Tappable(
                onTap: onEdit!,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: SvgPicture.asset('assets/icons/pencil.svg',
                      width: 16, height: 16),
                ),
              ),
            if (onEdit != null) const SizedBox(width: 6),
            if (onPause != null)
              Tappable(
                onTap: onPause!,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                      l.status == 'paused'
                          ? Icons.play_circle_outline
                          : Icons.pause_circle_outline,
                      size: 18,
                      color: AppColors.black),
                ),
              ),
            if (onPause != null) const SizedBox(width: 2),
            Tappable(
              onTap: onDelete,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: SvgPicture.asset('assets/icons/trash_red.svg',
                    width: 14, height: 14),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
