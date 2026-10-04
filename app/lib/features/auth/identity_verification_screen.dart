import 'package:flutter/material.dart';
import '../outcome/outcome_screen.dart';
import 'package:flutter/services.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/back_arrow.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../data/auth_service.dart';
import '../../data/identity_widget.dart';
import '../../data/profile_service.dart';

class IdentityVerificationScreen extends StatefulWidget {
  /// [onboarding] is true during sign-up (Skip + go Home when done); from the
  /// profile or a payment prompt it is false (simply go back when done).
  const IdentityVerificationScreen({super.key, this.onboarding = true});
  final bool onboarding;

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<IdentityVerificationScreen> {
  final _nin = TextEditingController();
  bool _loading = false;
  bool _scanning = false;
  bool _typed = false;

  // A Nigerian NIN is 11 digits.
  bool get _valid => _nin.text.length == 11;

  @override
  void dispose() {
    _nin.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    try {
      if (widget.onboarding) await AuthService.instance.setStep('done');
      await ProfileService.instance.load();
    } catch (_) {}
    if (!mounted) return;
    if (widget.onboarding) {
      Navigator.of(context).pushNamedAndRemoveUntil(Routes.home, (_) => false);
    } else {
      Navigator.of(context).pop();
    }
  }

  /// ID document + face scan inside the app (Prembly widget).
  Future<void> _scan() async {
    if (_scanning) return;
    setState(() => _scanning = true);
    final r = await IdentityWidget.run(context);
    if (!mounted) return;
    setState(() => _scanning = false);
    switch (r.outcome) {
      case WidgetOutcome.verified:
        await OutcomeScreen.show(context,
            title: 'Identity verified',
            message:
                'Your identity is confirmed. You can now withdraw from your wallet and your profile shows a verified badge.');
        if (mounted) await _finish();
      case WidgetOutcome.pending:
        await OutcomeScreen.show(context,
            title: 'Verification submitted',
            message:
                'We received your details and are reviewing them. You will get a notification and an email once the review is done.');
        if (mounted) await _finish();
      case WidgetOutcome.rejected:
        await OutcomeScreen.show(context,
            title: 'Verification not approved',
            message: r.message ??
                'We could not match your details. Try again in good light with your ID flat and your face clearly visible.',
            ok: false,
            buttonLabel: 'Try again');
      case WidgetOutcome.failedToStart:
        AppToast.show(context, r.message ?? 'Could not start verification.');
      case WidgetOutcome.cancelled:
        break;
    }
  }

  Future<void> _skip() async {
    FocusScope.of(context).unfocus();
    final later = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      barrierColor: const Color(0x3D000000),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _SkipSheet(),
    );
    if (later == true && mounted) _finish();
  }

  Future<void> _confirm() async {
    if (_loading || !_valid) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final status =
          await ProfileService.instance.submitIdentity(nin: _nin.text);
      if (!mounted) return;
      setState(() => _loading = false);
      if (status == 'verified') {
        await OutcomeScreen.show(context,
            title: 'Identity verified',
            message:
                'Your identity is confirmed. You can now withdraw from your wallet and your profile shows a verified badge.');
      } else {
        await OutcomeScreen.show(context,
            title: 'Verification submitted',
            message:
                'We received your details and are reviewing them. You will get a notification and an email once the review is done.');
      }
      if (mounted) await _finish();
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppToast.show(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final digits = [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(11),
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(27, 16, 28, 24),
          child: FadeSlideIn(
            child: Column(
              children: [
                const BackArrow(),
                const SizedBox(height: 12),
                const Text('Identity Verification', style: AppText.h5),
                const SizedBox(height: 8),
                const SizedBox(
                  width: 295,
                  child: Text(
                    'Choose how you want to verify. It keeps the community safe and unlocks withdrawals.',
                    textAlign: TextAlign.center,
                    style: AppText.body,
                  ),
                ),
                const SizedBox(height: 20),
                if (!_typed) ...[
                  _MethodCard(
                    icon: Icons.face_retouching_natural,
                    title: 'ID + face scan',
                    body:
                        'Scan your NIN slip, driver’s licence, international passport or voter’s card, then a quick selfie. Done in the app.',
                    loading: _scanning,
                    onTap: _scan,
                  ),
                  const SizedBox(height: 12),
                  _MethodCard(
                    icon: Icons.pin_outlined,
                    title: 'NIN number',
                    body: 'Type your 11-digit NIN. No photos needed.',
                    onTap: () => setState(() => _typed = true),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Your ID is checked by our identity partner. We never store the full number or your photos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11,
                      height: 1.4,
                      color: AppColors.neutral200,
                    ),
                  ),
                ] else ...[
                  AppTextField(
                    label: 'NIN',
                    controller: _nin,
                    showClear: false,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: digits,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _confirm(),
                  ),
                  const SizedBox(height: 28),
                  AppButton(
                    label: 'Confirm',
                    onPressed: _confirm,
                    inactive: !_valid,
                    loading: _loading,
                    disabledColor: AppColors.disabledFill,
                    disabledTextColor: AppColors.disabledText,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'By tapping Confirm you agree that Seculate may check your NIN with our identity partner. We never store the full number.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11,
                      height: 1.4,
                      color: AppColors.neutral200,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() => _typed = false),
                    child: const Text('Use ID + face scan instead'),
                  ),
                ],
                const SizedBox(height: 18),
                if (widget.onboarding)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _skip,
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      child: Text(
                        'Skip this step',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkipSheet extends StatelessWidget {
  const _SkipSheet();

  @override
  Widget build(BuildContext context) {
    const grey = TextStyle(
      fontFamily: AppTheme.fontFamily,
      fontSize: 14,
      color: AppColors.neutral100,
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(27, 32, 27, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Complete Verification to Unlock Full Access',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'We use your NIN to confirm your identity and enhance community safety. Skipping this step is optional, but we encourage you to complete it for full access to features like borrowing and lending.',
              textAlign: TextAlign.center,
              style: grey,
            ),
            const SizedBox(height: 8),
            const Text(
              '✅ You can verify later from your dashboard.\n❌ Skipping now means a limited account experience.',
              textAlign: TextAlign.center,
              style: grey,
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Verify now',
              onPressed: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                key: const Key('skip-continue'),
                onPressed: () => Navigator.of(context).pop(true),
                style: OutlinedButton.styleFrom(
                  shape: const StadiumBorder(),
                  side: const BorderSide(color: AppColors.neutral50),
                ),
                child: const Text(
                  'Continue and skip',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: AppColors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
    this.loading = false,
  });
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.neutral50),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: loading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                child: loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.black))
                    : Icon(icon, color: AppColors.black),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppColors.black)),
                    const SizedBox(height: 4),
                    Text(body,
                        style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13,
                            height: 1.4,
                            color: AppColors.neutral100)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.neutral100),
            ],
          ),
        ),
      ),
    );
  }
}
