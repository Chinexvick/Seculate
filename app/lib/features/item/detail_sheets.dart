import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/radio_sheet.dart';
import '../../data/models.dart';

TextStyle _t(double size, FontWeight w, Color c) => TextStyle(
    fontFamily: AppTheme.fontFamily, fontSize: size, fontWeight: w, color: c);

/// Lets the borrower pick how many days. The server decides the final price.
Future<int?> showDaysSheet(BuildContext context,
    {required int maxDays,
    required int pricePerDay,
    required int collateral,
    int securityFee = 0,
    int? minDays,
    int? lenderMaxDays}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: sheetShape,
    builder: (_) => _DaysSheet(
        maxDays: maxDays,
        pricePerDay: pricePerDay,
        collateral: collateral,
        securityFee: securityFee,
        minDays: minDays,
        lenderMaxDays: lenderMaxDays),
  );
}

class _DaysSheet extends StatefulWidget {
  const _DaysSheet(
      {required this.maxDays,
      required this.pricePerDay,
      required this.collateral,
      this.securityFee = 0,
      this.minDays,
      this.lenderMaxDays});
  final int? minDays;
  final int? lenderMaxDays;
  final int maxDays;
  final int pricePerDay;
  final int collateral;
  final int securityFee;

  @override
  State<_DaysSheet> createState() => _DaysSheetState();
}

class _DaysSheetState extends State<_DaysSheet> {
  late int _days = (widget.minDays ?? 1).clamp(1, 365);

  @override
  Widget build(BuildContext context) {
    var max = widget.maxDays > 0 ? widget.maxDays : 30;
    if (widget.lenderMaxDays != null && widget.lenderMaxDays! < max) {
      max = widget.lenderMaxDays!;
    }
    final min = (widget.minDays ?? 1).clamp(1, max);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            28, 28, 28, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHeader(title: 'How many days?'),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _days > min ? () => setState(() => _days--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppColors.primary,
                ),
                SizedBox(
                  width: 110,
                  child: Text('$_days ${_days == 1 ? 'day' : 'days'}',
                      textAlign: TextAlign.center,
                      style: _t(20, FontWeight.w500, AppColors.black)),
                ),
                IconButton(
                  onPressed: _days < max ? () => setState(() => _days++) : null,
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (widget.pricePerDay > 0)
              Center(
                child: Text('${naira(widget.pricePerDay)} per day',
                    style: _t(13, FontWeight.w400, AppColors.neutral200)),
              ),
            if (widget.securityFee > 0)
              Center(
                child: Text(
                    'Security fee ${naira(widget.securityFee)} (non-refundable, charged once)',
                    textAlign: TextAlign.center,
                    style: _t(12, FontWeight.w400, AppColors.neutral200)),
              ),
            Center(
              child: Text(
                  'Collateral ${naira(widget.collateral)} is held securely in escrow and returned when the item is back. Estimated rental ${naira(widget.pricePerDay * _days + widget.securityFee)}. Final amounts are confirmed after the lender accepts.',
                  textAlign: TextAlign.center,
                  style: _t(12, FontWeight.w400, AppColors.neutral200)),
            ),
            const SizedBox(height: 18),
            AppButton(
                label: 'Send request',
                onPressed: () => Navigator.of(context).pop(_days)),
          ],
        ),
      ),
    );
  }
}

/// Amount entry (Naira) for task offers. Returns the amount or null.
Future<int?> showAmountSheet(BuildContext context,
    {required String title, required String action, int? initial}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: sheetShape,
    builder: (_) =>
        _AmountSheet(title: title, action: action, initial: initial),
  );
}

class _AmountSheet extends StatefulWidget {
  const _AmountSheet({required this.title, required this.action, this.initial});
  final String title;
  final String action;
  final int? initial;

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  late final _c = TextEditingController(
      text: widget.initial == null ? '' : '${widget.initial}');

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = int.tryParse(_c.text.trim()) ?? 0;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            28, 28, 28, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SheetHeader(title: widget.title),
            const SizedBox(height: 18),
            TextField(
              controller: _c,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              style: _t(18, FontWeight.w500, AppColors.black),
              decoration: InputDecoration(
                prefixText: '₦ ',
                hintText: 'Amount',
                hintStyle: _t(16, FontWeight.w400, AppColors.neutral100),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 18),
            AppButton(
              label: widget.action,
              onPressed: v > 0 ? () => Navigator.of(context).pop(v) : null,
            ),
          ],
        ),
      ),
    );
  }
}

const reportReasons = [
  SheetOption('Spam or misleading', 'Spam or misleading'),
  SheetOption('Scam or fraud', 'Scam or fraud'),
  SheetOption('Prohibited item or service', 'Prohibited item or service'),
  SheetOption('Offensive or inappropriate', 'Offensive or inappropriate'),
  SheetOption('Other', 'Other'),
];

Future<String?> pickReportReason(BuildContext context, String title) =>
    showRadioSheet(context,
        title: title, options: reportReasons, selectedId: '');
