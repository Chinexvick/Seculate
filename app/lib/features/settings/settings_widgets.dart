import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/back_arrow.dart';
import '../../core/widgets/radio_sheet.dart';
import '../../core/widgets/tappable.dart';

const _boxBorder = Color(0xFF8A8A8A);

/// Page chrome used by every Settings screen: back arrow + title (+ optional
/// trailing pill) with a soft shadow, and the green support button.
class SettingsScaffold extends StatelessWidget {
  const SettingsScaffold({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.support = true,
    this.scroll = true,
  });
  final String title;
  final Widget child;
  final Widget? trailing;
  final bool support;
  final bool scroll;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 20, 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 3,
                          offset: Offset(0, 1.5))
                    ],
                  ),
                  child: Row(children: [
                    const SizedBox(width: 32, child: BackArrow()),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 14,
                              color: AppColors.black)),
                    ),
                    if (trailing != null) trailing!,
                  ]),
                ),
                Expanded(
                  child: scroll
                      ? SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
                          child: child,
                        )
                      : child,
                ),
              ],
            ),
            if (support)
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

/// Small gray "save" pill that turns green "Saved".
class SavePill extends StatelessWidget {
  const SavePill({super.key, required this.saved, required this.onTap});
  final bool saved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: saved ? AppColors.primary : const Color(0xFFEAEAEA),
          borderRadius: BorderRadius.circular(4000),
        ),
        child: Text(saved ? 'Saved' : 'save',
            style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12,
                color: saved ? Colors.black : AppColors.neutral200)),
      ),
    );
  }
}

/// Rounded-rect button: gray when [active] is false, green when true.
class SoftButton extends StatelessWidget {
  const SoftButton(
      {super.key,
      required this.label,
      required this.onTap,
      this.active = true,
      this.width = 143});
  final String label;
  final VoidCallback onTap;
  final bool active;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: 43,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : const Color(0xFFEFEFEF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14,
                color: AppColors.black)),
      ),
    );
  }
}

/// Outlined input with the label shown as placeholder (wire-frame style).
class BoxField extends StatelessWidget {
  const BoxField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboard,
    this.obscure = false,
    this.formatters,
    this.onChanged,
    this.errorText,
    this.suffix,
    this.maxLength,
  });
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboard;
  final bool obscure;
  final List<TextInputFormatter>? formatters;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final Widget? suffix;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 62,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: errorText != null ? AppColors.alert : _boxBorder),
            ),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboard,
                  obscureText: obscure,
                  inputFormatters: formatters,
                  maxLength: maxLength,
                  onChanged: onChanged,
                  cursorColor: AppColors.primary,
                  style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 16,
                      color: AppColors.black),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    counterText: '',
                    hintText: hint,
                    hintStyle: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 15,
                        color: Color(0xFF9A9A9A)),
                  ),
                ),
              ),
              if (suffix != null) suffix!,
            ]),
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(errorText!, style: AppText.errorCaption),
            ),
        ],
      ),
    );
  }
}

/// Outlined dropdown that opens a radio sheet.
class DropBox extends StatelessWidget {
  const DropBox({
    super.key,
    required this.hint,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String hint;
  final String? value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final empty = value == null || value!.isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          FocusScope.of(context).unfocus();
          final r = await showRadioSheet(
            context,
            title: hint,
            options: [for (final o in options) SheetOption(o, o)],
            selectedId: value ?? '',
          );
          if (r != null) onChanged(r);
        },
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _boxBorder),
          ),
          child: Row(children: [
            Expanded(
              child: Text(empty ? hint : value!,
                  style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: empty ? 15 : 16,
                      color:
                          empty ? const Color(0xFF9A9A9A) : AppColors.black)),
            ),
            const Icon(Icons.arrow_drop_down,
                color: Color(0xFFD4D4D4), size: 28),
          ]),
        ),
      ),
    );
  }
}
