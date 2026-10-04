import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/backend.dart';
import '../../data/models.dart';

/// Opens the hosted escrow checkout for [txId]. Returns true when the browser
/// was launched. Shows the server's message when payment is unavailable.
Future<bool> payForTransaction(BuildContext context, String txId) async {
  try {
    final link = await backend.startEscrowPayment(txId);
    final ok =
        await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      AppToast.show(context, 'Could not open the payment page.');
    }
    return ok;
  } on BackendError catch (e) {
    if (context.mounted) {
      AppToast.show(context, e.message);
      if (e.code == 'identity_required' && e.extra?['who'] == 'self') {
        Navigator.of(context)
            .pushNamed('/identity-verification', arguments: false);
      }
    }
    return false;
  } catch (_) {
    if (context.mounted) {
      AppToast.show(context, 'Payment is not available right now.');
    }
    return false;
  }
}

/// Small pill button used inside chat cards and the transaction page.
class PillButton extends StatelessWidget {
  const PillButton(this.label, this.onTap,
      {super.key,
      this.filled = false,
      this.color = AppColors.primary,
      this.width,
      this.busy = false});
  final String label;
  final VoidCallback? onTap;
  final bool filled;
  final Color color;
  final double? width;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !busy;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          height: 38,
          width: width,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4000),
            color: filled ? color : null,
            border: filled ? null : Border.all(color: color),
          ),
          child: busy
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: filled ? Colors.white : color))
              : Text(label,
                  style: AppText.body.copyWith(
                      color: filled ? Colors.white : color,
                      fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}

/// Role of the signed-in user in a transaction.
bool isPayer(Txn t) => t.payerId == backend.uid;
bool isPayee(Txn t) => t.payeeId == backend.uid;

/// Who does what (mirrors the server rules; the server still enforces them).
/// Borrow: the borrower confirms receipt and returns, the lender confirms the
/// return. Tasks: the worker (payee) starts and submits, the requester confirms.
bool isWorker(Txn t) => t.kind == 'borrow' ? isPayer(t) : isPayee(t);
bool isConfirmer(Txn t) => t.kind == 'borrow' ? isPayee(t) : isPayer(t);

String dateLabel(DateTime? d) {
  if (d == null) return '-';
  final l = d.toLocal();
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
  return '${l.day} ${m[l.month - 1]} ${l.year}';
}
