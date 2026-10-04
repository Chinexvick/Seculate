import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Pill button used across the app (green primary / black secondary).
/// Includes a subtle press-scale animation.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.primary,
    this.textColor = AppColors.white,
    this.disabledColor,
    this.disabledTextColor,
    this.inactive = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;

  /// When set, a null [onPressed] renders in these colors instead of fading.
  final Color? disabledColor;
  final Color? disabledTextColor;

  /// Renders in the disabled colors but still reports taps.
  final bool inactive;

  /// Shows a pulsing dot instead of the label and ignores taps.
  final bool loading;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final looksOn = (enabled && !widget.inactive) || widget.loading;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.loading ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: (looksOn || widget.disabledColor != null) ? 1 : 0.5,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: looksOn
                  ? widget.color
                  : (widget.disabledColor ?? widget.color),
              borderRadius: BorderRadius.circular(4000),
            ),
            alignment: Alignment.center,
            child: SizedBox(
              height: 24,
              child: widget.loading
                  ? const _PulseDot()
                  : Text(
                      widget.label,
                      style: AppText.button.copyWith(
                        color: looksOn
                            ? widget.textColor
                            : (widget.disabledTextColor ?? widget.textColor),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.6, end: 1.4)
            .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
        child: Container(
          width: 5,
          height: 5,
          decoration:
              const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
