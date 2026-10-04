import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

class SheetOption {
  const SheetOption(this.id, this.label);
  final String id;
  final String label;
}

const sheetShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
);

/// Bottom sheet header: close (x) + title.
class SheetHeader extends StatelessWidget {
  const SheetHeader({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).maybePop(),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: SvgPicture.asset('assets/icons/x.svg',
                width: 24,
                height: 24,
                colorFilter:
                    const ColorFilter.mode(AppColors.black, BlendMode.srcIn)),
          ),
        ),
        const SizedBox(width: 12),
        Text(title,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: AppColors.black,
            )),
      ],
    );
  }
}

/// Single-choice list sheet with a Save button that appears after a change.
/// Returns the saved option id, or null when dismissed.
Future<String?> showRadioSheet(
  BuildContext context, {
  required String title,
  required List<SheetOption> options,
  required String selectedId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: sheetShape,
    builder: (_) =>
        _RadioSheet(title: title, options: options, initial: selectedId),
  );
}

class _RadioSheet extends StatefulWidget {
  const _RadioSheet(
      {required this.title, required this.options, required this.initial});
  final String title;
  final List<SheetOption> options;
  final String initial;

  @override
  State<_RadioSheet> createState() => _RadioSheetState();
}

class _RadioSheetState extends State<_RadioSheet> {
  late String _sel = widget.initial;

  @override
  Widget build(BuildContext context) {
    final changed = _sel != widget.initial;
    final maxH = MediaQuery.of(context).size.height * 0.82;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SheetHeader(title: widget.title),
              const SizedBox(height: 14),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    for (var i = 0; i < widget.options.length; i++)
                      _Row(
                        label: widget.options[i].label,
                        selected: widget.options[i].id == _sel,
                        divider: i < widget.options.length - 1,
                        onTap: () =>
                            setState(() => _sel = widget.options[i].id),
                      ),
                  ],
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: changed
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: AppButton(
                          label: 'Save',
                          onPressed: () => Navigator.of(context).pop(_sel),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(
      {required this.label,
      required this.selected,
      required this.divider,
      required this.onTap});
  final String label;
  final bool selected;
  final bool divider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          border: divider
              ? const Border(bottom: BorderSide(color: AppColors.neutral40))
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 15,
                    color: AppColors.black,
                  )),
            ),
            _Radio(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: selected ? AppColors.primary : AppColors.neutral50),
      ),
      child: AnimatedScale(
        scale: selected ? 1 : 0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        child: Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
              color: AppColors.primary, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
