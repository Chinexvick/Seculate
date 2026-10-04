import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';

/// One result screen per thing that happened. Each caller passes copy that talks
/// only about its own event (credits added, wallet topped up, withdrawal, ...).
class OutcomeScreen extends StatelessWidget {
  const OutcomeScreen({
    super.key,
    required this.title,
    required this.message,
    this.ok = true,
    this.buttonLabel = 'Done',
    this.detail,
  });

  final String title;
  final String message;
  final bool ok;
  final String buttonLabel;

  /// Optional highlighted line, e.g. the amount.
  final String? detail;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    bool ok = true,
    String buttonLabel = 'Done',
    String? detail,
  }) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => OutcomeScreen(
            title: title,
            message: message,
            ok: ok,
            buttonLabel: buttonLabel,
            detail: detail),
      ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
          child: Column(children: [
            const Spacer(),
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: ok ? const Color(0xFFF3FBF5) : const Color(0xFFFFF3F2),
                border: Border.all(
                    color:
                        ok ? const Color(0xFFBDEBC8) : const Color(0xFFF6C4BF),
                    width: 2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Icon(
                  ok ? Icons.check_rounded : Icons.error_outline_rounded,
                  size: 46,
                  color: ok ? AppColors.primaryDark : const Color(0xFFD6392B)),
            ),
            const SizedBox(height: 24),
            Text(title, textAlign: TextAlign.center, style: AppText.h5),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: AppText.body),
            if (detail != null) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                decoration: BoxDecoration(
                    color: const Color(0xFFF7F9F8),
                    borderRadius: BorderRadius.circular(14)),
                child: Text(detail!,
                    style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        color: AppColors.black)),
              ),
            ],
            const Spacer(),
            AppButton(
                label: buttonLabel,
                onPressed: () => Navigator.of(context).pop()),
          ]),
        ),
      ),
    );
  }
}
