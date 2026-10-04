import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/tappable.dart';
import '../../data/backend.dart';

/// Notification bell with a live unread badge.
class BellButton extends StatefulWidget {
  const BellButton({super.key, this.padding = const EdgeInsets.all(8)});
  final EdgeInsets padding;

  @override
  State<BellButton> createState() => _BellButtonState();
}

class _BellButtonState extends State<BellButton> {
  int _count = 0;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _refresh();
    try {
      _sub = backend
          .incomingNotifications()
          .listen((_) => _refresh(), onError: (_) {});
    } catch (_) {}
  }

  Future<void> _refresh() async {
    final n = await backend.unreadNotificationCount();
    if (mounted) setState(() => _count = n);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: () async {
        await Navigator.of(context).pushNamed(Routes.notifications);
        if (mounted) _refresh();
      },
      scale: 0.88,
      child: Padding(
        padding: widget.padding,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SvgPicture.asset('assets/icons/bell.svg', width: 24, height: 24),
            if (_count > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.alert,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
