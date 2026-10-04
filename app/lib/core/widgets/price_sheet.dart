import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';
import 'radio_sheet.dart';

String formatMoney(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// A price filter with no ceiling: [from] is the lowest price (0 = none) and
/// [to] the highest, or null for "no upper limit".
class PriceFilter {
  const PriceFilter({this.from = 0, this.to});
  static const none = PriceFilter();
  final double from;
  final double? to;
  bool get active => from > 0 || to != null;

  @override
  bool operator ==(Object other) =>
      other is PriceFilter && other.from == from && other.to == to;
  @override
  int get hashCode => Object.hash(from, to);
}

/// Price sheet. Returns the saved filter, [PriceFilter.none] after Reset, or
/// null when dismissed. Amounts can be typed freely; the slider only grows
/// forward from zero and has no fixed ceiling in practice (₦500 to ₦50m).
Future<PriceFilter?> showPriceSheet(
  BuildContext context, {
  required PriceFilter current,
}) {
  return showModalBottomSheet<PriceFilter>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: sheetShape,
    builder: (_) => _PriceSheet(initial: current),
  );
}

class _PriceSheet extends StatefulWidget {
  const _PriceSheet({required this.initial});
  final PriceFilter initial;

  @override
  State<_PriceSheet> createState() => _PriceSheetState();
}

// Slider position 0..1 <-> naira, on a log scale: 500 * 10^(t*5).
const _sliderBase = 500.0;
const _sliderDecades = 5.0;

double _toNaira(double t) {
  final raw = _sliderBase * math.pow(10, t * _sliderDecades);
  final step =
      raw < 10000 ? 100 : (raw < 100000 ? 1000 : (raw < 1e6 ? 10000 : 100000));
  return ((raw / step).round() * step).toDouble();
}

double _toSlider(double naira) {
  if (naira <= _sliderBase) return 0;
  final t = math.log(naira / _sliderBase) / math.ln10 / _sliderDecades;
  return t.clamp(0.0, 1.0);
}

class _PriceSheetState extends State<_PriceSheet> {
  late double _fromV = widget.initial.from;
  late double? _toV = widget.initial.to;
  late final _from = TextEditingController(
      text: _fromV > 0 ? formatMoney(_fromV.round()) : '');
  late final _to = TextEditingController(
      text: _toV != null ? formatMoney(_toV!.round()) : '');

  PriceFilter get _value => PriceFilter(from: _fromV, to: _toV);
  bool get _changed => _value != widget.initial;

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  void _typed() {
    final f = double.tryParse(_from.text.replaceAll(',', ''));
    final t = double.tryParse(_to.text.replaceAll(',', ''));
    setState(() {
      _fromV = f ?? 0;
      _toV = (t == null || t <= 0) ? null : t;
    });
  }

  void _reset() {
    setState(() {
      _fromV = 0;
      _toV = null;
      _from.clear();
      _to.clear();
    });
  }

  bool get _invalid => _toV != null && _fromV > _toV!;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(28, 28, 28, 14),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: SheetHeader(title: 'Price (₦)')),
            ),
            const Divider(height: 1, color: AppColors.neutral40),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2.5,
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.neutral40,
                  thumbColor: AppColors.primary,
                  overlayColor: AppColors.primary.withValues(alpha: 0.12),
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 10),
                ),
                child: Slider(
                  value: _toV == null ? 1 : _toSlider(_toV!),
                  onChanged: (t) {
                    final v = _toNaira(t);
                    setState(() => _toV = v);
                    _to.text = formatMoney(v.round());
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 14, 28, 6),
              child: Row(
                children: [
                  Expanded(
                      child: _MoneyField(
                          label: 'From',
                          hint: '0',
                          controller: _from,
                          onChanged: _typed)),
                  const SizedBox(width: 24),
                  Expanded(
                      child: _MoneyField(
                          label: 'To',
                          hint: 'No limit',
                          controller: _to,
                          onChanged: _typed)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                    _invalid
                        ? '"From" must be lower than "To"'
                        : 'Type any amount, or drag the slider.',
                    style: AppText.body.copyWith(
                        fontSize: 11,
                        color:
                            _invalid ? AppColors.alert : AppColors.neutral200)),
              ),
            ),
            const Divider(height: 1, color: AppColors.neutral40),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 12),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _reset,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4000),
                          border: Border.all(
                              color: !_value.active
                                  ? AppColors.neutral200
                                  : AppColors.primary),
                        ),
                        child: Text('Reset',
                            style: AppText.button.copyWith(
                                color: !_value.active
                                    ? AppColors.neutral200
                                    : AppColors.primary)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Save',
                      onPressed: () => Navigator.of(context).pop(_value),
                      inactive: !_changed || _invalid,
                      disabledColor: AppColors.disabledFill,
                      disabledTextColor: AppColors.disabledText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoneyField extends StatelessWidget {
  const _MoneyField(
      {required this.label,
      required this.controller,
      required this.onChanged,
      this.hint = ''});
  final String label;
  final String hint;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.body.copyWith(fontSize: 10)),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.neutral50),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _ThousandsFormatter()
            ],
            onChanged: (_) => onChanged(),
            cursorColor: AppColors.primary,
            style: AppText.title1.copyWith(fontSize: 16),
            decoration: InputDecoration(
                border: InputBorder.none, isDense: true, hintText: hint),
          ),
        ),
      ],
    );
  }
}

class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    final d = n.text.replaceAll(',', '');
    if (d.isEmpty) return n.copyWith(text: '');
    final t = formatMoney(int.parse(d));
    return TextEditingValue(
        text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}
