import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Top pop-up notification (Figma "Pop ups notification"): light-green card
/// with check icon, message and close button. Slides in, auto-dismisses.
class AppToast {
  AppToast._();

  static OverlayEntry? _current;

  static void show(BuildContext context, String message,
      {Duration duration = const Duration(milliseconds: 2400)}) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _current?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastView(
        message: message,
        duration: duration,
        onDone: () {
          if (_current == entry) _current = null;
          entry.remove();
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }
}

class _ToastView extends StatefulWidget {
  const _ToastView(
      {required this.message, required this.duration, required this.onDone});
  final String message;
  final Duration duration;
  final VoidCallback onDone;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    reverseDuration: const Duration(milliseconds: 200),
  );
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _timer = Timer(widget.duration, _close);
  }

  Future<void> _close() async {
    if (_closing || !mounted) return;
    _closing = true;
    _timer?.cancel();
    await _c.reverse();
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final curved = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return Positioned(
      top: top + 26,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position:
              Tween<Offset>(begin: const Offset(0, -0.6), end: Offset.zero)
                  .animate(curved),
          child: Material(
            color: Colors.transparent,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFCE8),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF6DE546), width: 0.5),
              ),
              child: Row(
                children: [
                  SvgPicture.asset('assets/icons/check.svg',
                      width: 24, height: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        height: 20 / 12,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _close,
                    child: SvgPicture.asset('assets/icons/x.svg',
                        width: 24, height: 24),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
