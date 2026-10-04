import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Labelled input with a leading SVG icon, optional password toggle,
/// clear (x) button, valid check and inline error text — all states from
/// the Figma login frames.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.leadingIcon,
    this.password = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onFocusLost,
    this.hint,
    this.errorText,
    this.showValid = false,
    this.showClear = true,
    this.leadingWidget,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final String? leadingIcon;
  final bool password;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFocusLost;
  final String? hint;
  final String? errorText;

  /// Shows the green check next to the clear button.
  final bool showValid;

  /// Shows the clear (x) button while there is text.
  final bool showClear;

  /// Custom leading content (e.g. country flag + dial code); replaces [leadingIcon].
  final Widget? leadingWidget;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final FocusNode _focus = FocusNode();
  bool _hidden = true;
  bool _hadFocus = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (_hadFocus && !_focus.hasFocus) widget.onFocusLost?.call();
      _hadFocus = _focus.hasFocus;
      setState(() {});
    });
    widget.controller.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    _focus.dispose();
    super.dispose();
  }

  void _clear() {
    widget.controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final focused = _focus.hasFocus;
    final hasText = widget.controller.text.isNotEmpty;
    final borderColor = hasError
        ? AppColors.alert
        : (focused ? AppColors.primary : AppColors.neutral40);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppText.body),
        const SizedBox(height: 5),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              const SizedBox(width: 9),
              if (widget.leadingWidget != null) ...[
                widget.leadingWidget!,
                const SizedBox(width: 20),
              ] else if (widget.leadingIcon != null) ...[
                SvgPicture.asset(widget.leadingIcon!, width: 24, height: 24),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  obscureText: widget.password && _hidden,
                  obscuringCharacter: '•',
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  inputFormatters: widget.inputFormatters,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  cursorColor: AppColors.primary,
                  style: AppText.title1,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: widget.hint,
                    hintStyle: AppText.body,
                  ),
                ),
              ),
              if (hasText && widget.showClear) ...[
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _clear,
                  child: SvgPicture.asset(
                    'assets/icons/x.svg',
                    width: 24,
                    height: 24,
                    colorFilter: hasError
                        ? const ColorFilter.mode(
                            AppColors.alert, BlendMode.srcIn)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (widget.showValid && !hasError) ...[
                SvgPicture.asset('assets/icons/check.svg',
                    width: 24, height: 24),
                const SizedBox(width: 11),
              ],
              if (widget.password)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _hidden = !_hidden),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 11),
                    child: Opacity(
                      opacity: _hidden ? 1 : 0.55,
                      child: SvgPicture.asset(
                        'assets/icons/eye.svg',
                        width: 24,
                        height: 24,
                        colorFilter: hasError
                            ? const ColorFilter.mode(
                                AppColors.alert, BlendMode.srcIn)
                            : null,
                      ),
                    ),
                  ),
                )
              else if (!(widget.showValid && !hasError))
                const SizedBox(width: 11),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topLeft,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(widget.errorText!, style: AppText.errorCaption),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
