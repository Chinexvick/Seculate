// ignore_for_file: curly_braces_in_flow_control_structures
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/back_arrow.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../app/routes.dart';
import '../../core/widgets/tappable.dart';
import '../../data/backend.dart';
import '../chat/chat_screen.dart' show ChatArgs;
import '../../data/models.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _all = const [];
  bool _loading = true;
  String? _error;
  StreamSubscription<AppNotification>? _sub;

  @override
  void initState() {
    super.initState();
    _load();
    _sub = backend.incomingNotifications().listen((n) {
      if (!mounted) return;
      if (_all.any((x) => x.id == n.id)) return;
      setState(() => _all = [n, ..._all]);
    }, onError: (_) {});
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final list = await backend.notifications();
      if (!mounted) return;
      setState(() {
        _all = list;
        _loading = false;
      });
      if (list.any((n) => n.isNew)) backend.markNotificationsRead();
    } on BackendError catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = e.message;
        });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _open(AppNotification n) async {
    final nav = Navigator.of(context);
    final id = n.refId;
    switch (n.refType) {
      case 'transaction':
        if (id != null) nav.pushNamed(Routes.transaction, arguments: id);
        return;
      case 'conversation':
        if (id != null) {
          try {
            final convs = await backend.conversations();
            final c = convs.where((c) => c.id == id).toList();
            if (c.isNotEmpty) {
              nav.pushNamed(Routes.chat,
                  arguments: ChatArgs(c.first.person, conversationId: id));
              return;
            }
          } catch (_) {}
        }
        nav.pushNamed(Routes.allChats);
        return;
      case 'listing':
        if (id != null && n.rawKind == 'listing_available') {
          try {
            final p = await backend.listing(id);
            nav.pushNamed(Routes.itemDetail, arguments: p);
            return;
          } catch (_) {}
        }
        nav.pushNamed(Routes.myListings);
        return;
      case 'task':
        nav.pushNamed(Routes.myListings);
        return;
      case 'ticket':
        nav.pushNamed(Routes.support);
        return;
      case 'request':
        if (id != null) nav.pushNamed(Routes.requestDetail, arguments: id);
        return;
      case 'credits':
        nav.pushNamed(Routes.credits);
        return;
      case 'wallet':
      case 'payment':
        nav.pushNamed(Routes.wallet);
        return;
      case 'subscription':
        nav.pushNamed(Routes.pricing);
        return;
      case 'verification':
        nav.pushNamed(Routes.profile);
        return;
      case 'dispute':
        nav.pushNamed(Routes.transactions);
        return;
    }
    if (n.kind == NotificationKind.message) nav.pushNamed(Routes.allChats);
  }

  @override
  Widget build(BuildContext context) {
    final fresh = _all.where((n) => n.isNew).toList();
    final old = _all.where((n) => !n.isNew).toList();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
            children: [
              Row(
                children: const [
                  SizedBox(width: 24, child: BackArrow()),
                  SizedBox(width: 20),
                  Text(
                    'Notification',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w500,
                      fontSize: 22,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2)),
                )
              else if (_error != null && _all.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Column(
                    children: [
                      Text(_error!,
                          textAlign: TextAlign.center, style: AppText.body),
                      TextButton(
                          onPressed: _load,
                          child: const Text('Retry',
                              style: TextStyle(color: AppColors.primary))),
                    ],
                  ),
                )
              else if (_all.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Center(
                      child: Text('No notifications yet', style: AppText.body)),
                )
              else ...[
                if (fresh.isNotEmpty) _Section('New', fresh, _open),
                if (fresh.isNotEmpty && old.isNotEmpty)
                  const SizedBox(height: 28),
                if (old.isNotEmpty) _Section('Earlier', old, _open),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.items, this.onOpen);
  final String title;
  final List<AppNotification> items;
  final void Function(AppNotification) onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.body.copyWith(color: AppColors.black)),
        const SizedBox(height: 12),
        for (var i = 0; i < items.length; i++) ...[
          FadeSlideIn(
            delay: Duration(milliseconds: 40 * i),
            offset: 8,
            child: Tappable(
                onTap: () => onOpen(items[i]),
                scale: 0.99,
                child: _Row(items[i])),
          ),
          if (i < items.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.n);
  final AppNotification n;

  Widget get _icon {
    switch (n.kind) {
      case NotificationKind.rejected:
      case NotificationKind.failed:
        return SvgPicture.asset('assets/icons/notif_reject.svg',
            width: 47, height: 47);
      case NotificationKind.offer:
        return SvgPicture.asset('assets/icons/notif_tag.svg',
            width: 47, height: 47);
      case NotificationKind.message:
      case NotificationKind.success:
        return Container(
          width: 47,
          height: 47,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
              color: Color(0xFF96E7AB), shape: BoxShape.circle),
          child: SvgPicture.asset('assets/icons/notif_inbox.svg',
              width: 21.5, height: 21.5),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _icon,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        n.title,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    Text(n.time, style: AppText.body.copyWith(fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(n.body, style: AppText.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
