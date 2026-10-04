import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/back_arrow.dart';
import '../../core/widgets/fade_slide_in.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _loading = false;

  bool get _emailOk =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim());
  String? get _emailError =>
      _email.text.isNotEmpty && !_emailOk ? 'Invalid email address' : null;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_loading || !_emailOk) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final r = await AuthService.instance
          .sendOtp(_email.text.trim(), OtpPurpose.recovery);
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.of(context).pushNamed(Routes.verifyCode,
          arguments: VerifyCodeArgs(_email.text.trim(),
              reset: true, devCode: r.devCode));
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppToast.show(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                const Text('Forgot password', style: AppText.h5),
                const SizedBox(height: 8),
                const Text(
                  'Enter the email linked to your account.',
                  textAlign: TextAlign.center,
                  style: AppText.body,
                ),
                const SizedBox(height: 28),
                AppTextField(
                  label: 'Email',
                  controller: _email,
                  leadingIcon: 'assets/icons/mail.svg',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  errorText: _emailError,
                  showValid: _emailOk,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _next(),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Next',
                  onPressed: _next,
                  inactive: !_emailOk,
                  loading: _loading,
                  disabledColor: AppColors.disabledFill,
                  disabledTextColor: AppColors.disabledText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Arguments for the 6-digit code screen.
class VerifyCodeArgs {
  const VerifyCodeArgs(this.email, {this.reset = false, this.devCode});
  final String email;
  final bool reset;

  /// Returned by the server only while no email provider is configured.
  final String? devCode;
}
