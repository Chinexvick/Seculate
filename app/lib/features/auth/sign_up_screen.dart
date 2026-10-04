import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/back_arrow.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../data/auth_service.dart';
import 'forgot_password_screen.dart' show VerifyCodeArgs;

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
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
    final email = _email.text.trim();
    try {
      final r = await AuthService.instance.sendOtp(email, OtpPurpose.signup);
      if (!mounted) return;
      setState(() => _loading = false);
      if (r.exists) {
        AppToast.show(context, 'You already have an account. Log in instead.');
        Navigator.of(context).pushReplacementNamed(Routes.logIn);
        return;
      }
      Navigator.of(context).pushNamed(Routes.verifyCode,
          arguments: VerifyCodeArgs(email, devCode: r.devCode));
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
                const Text('Welcome aboard', style: AppText.h5),
                const SizedBox(height: 8),
                const Text(
                  'Let’s get you started on something great.',
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
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SizedBox(
                        width: 76,
                        child: Divider(height: 1, color: AppColors.neutral40)),
                    SizedBox(width: 9),
                    Text('or continue with',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 10,
                          color: AppColors.neutral100,
                        )),
                    SizedBox(width: 9),
                    SizedBox(
                        width: 76,
                        child: Divider(height: 1, color: AppColors.neutral40)),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final a in const [
                      'assets/icons/google.svg',
                      'assets/icons/facebook.svg',
                      'assets/icons/apple.svg'
                    ]) ...[
                      GestureDetector(
                        onTap: () => AppToast.show(context,
                            'Social sign-in isn’t available yet. Use your email.'),
                        child: SvgPicture.asset(a, width: 41, height: 41),
                      ),
                      if (!a.contains('apple')) const SizedBox(width: 18),
                    ],
                  ],
                ),
                const SizedBox(height: 42),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Have an account?', style: AppText.body),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context)
                          .pushReplacementNamed(Routes.logIn),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          ' Log in',
                          style: AppText.body.copyWith(
                            color: AppColors.primaryDark,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
