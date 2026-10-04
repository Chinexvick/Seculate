import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/back_arrow.dart';

/// Screen title row with back arrow, shared by credits and request screens.
class ReqHeader extends StatelessWidget {
  const ReqHeader(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
        child: Row(children: [
          const SizedBox(width: 24, child: BackArrow()),
          const SizedBox(width: 20),
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w500,
                    fontSize: 22,
                    color: AppColors.black)),
          ),
          if (trailing != null) trailing!,
        ]),
      );
}

/// Plain labelled text input in the app's soft-grey style.
class ReqField extends StatelessWidget {
  const ReqField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboard,
    this.maxLines = 1,
    this.maxLength,
    this.prefix,
    this.digitsOnly = false,
  });
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboard;
  final int maxLines;
  final int? maxLength;
  final String? prefix;
  final bool digitsOnly;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style:
                  AppText.body.copyWith(color: AppColors.black, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboard,
            maxLines: maxLines,
            maxLength: maxLength,
            inputFormatters:
                digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
            style: AppText.title1,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppText.body.copyWith(color: AppColors.neutral50),
              prefixText: prefix,
              counterText: '',
              filled: true,
              fillColor: const Color(0xFFF5F6F7),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1)),
            ),
          ),
        ]),
      );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});
  final String status;

  static const _labels = {
    'pending_review': 'In review',
    'open': 'Open',
    'matched': 'Matched',
    'expired': 'Expired',
    'cancelled': 'Cancelled',
    'rejected': 'Not approved',
    'changes_requested': 'Changes needed',
    'submitted': 'Sent',
    'counter_offered': 'Counter offer',
    'accepted': 'Accepted',
    'withdrawn': 'Withdrawn',
  };

  @override
  Widget build(BuildContext context) {
    final good =
        status == 'open' || status == 'matched' || status == 'accepted';
    final bad =
        status == 'rejected' || status == 'cancelled' || status == 'expired';
    final color = good
        ? AppColors.primaryDark
        : bad
            ? AppColors.alert
            : AppColors.neutral200;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Text(_labels[status] ?? status,
          style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color)),
    );
  }
}

String shortDate(dynamic iso) {
  final d = DateTime.tryParse('${iso ?? ''}')?.toLocal();
  if (d == null) return '';
  const m = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return '${d.day} ${m[d.month - 1]}';
}

String expiresIn(dynamic iso) {
  final d = DateTime.tryParse('${iso ?? ''}');
  if (d == null) return '';
  final left = d.difference(DateTime.now());
  if (left.isNegative) return 'Expired';
  if (left.inDays >= 1) return '${left.inDays}d left';
  if (left.inHours >= 1) return '${left.inHours}h left';
  return 'Ending soon';
}

/// Rounded grey card container.
class ReqCard extends StatelessWidget {
  const ReqCard({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFFF5F6F7),
                borderRadius: BorderRadius.circular(12)),
            child: child,
          ),
        ),
      );
}
