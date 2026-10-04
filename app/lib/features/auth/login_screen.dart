import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../data/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _passwordTouched = false;
  bool _loading = false;

  bool get _emailOk =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim());
  bool get _valid => _emailOk && _password.text.isNotEmpty;

  /// Matches the Figma states: red "Invalid email address" once something
  /// is typed, red "Password required" after the field was visited empty.
  String? get _emailError =>
      _email.text.isNotEmpty && !_emailOk ? 'Invalid email address' : null;
  String? get _passwordError =>
      _passwordTouched && _password.text.isEmpty ? 'Password required' : null;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_valid) {
      setState(() => _passwordTouched = true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await AuthService.instance.signIn(_email.text, _password.text);
      final step = await AuthService.instance.onboardingStep();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
          AuthService.routeForStep(step), (_) => false,
          arguments: _email.text.trim());
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
          padding: const EdgeInsets.fromLTRB(27, 52, 28, 24),
          child: FadeSlideIn(
            child: Column(
              children: [
                const Text('Log in', style: AppText.h5),
                const SizedBox(height: 8),
                const SizedBox(
                  width: 251,
                  child: Text(
                    'Let’s get you started on something great.',
                    textAlign: TextAlign.center,
                    style: AppText.body,
                  ),
                ),
                const SizedBox(height: 44),
                AppTextField(
                  label: 'Email',
                  controller: _email,
                  leadingIcon: 'assets/icons/mail.svg',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  errorText: _emailError,
                  showValid: _emailOk,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Password',
                  controller: _password,
                  leadingIcon: 'assets/icons/lock.svg',
                  password: true,
                  textInputAction: TextInputAction.done,
                  errorText: _passwordError,
                  onChanged: (_) => setState(() {}),
                  onFocusLost: () => setState(() => _passwordTouched = true),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: _LinkText(
                    'Forgot Password?',
                    onTap: () =>
                        Navigator.of(context).pushNamed(Routes.forgotPassword),
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Log in',
                  onPressed: _submit,
                  inactive: !_valid,
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
                    Text(
                      'or continue with',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 10,
                        color: AppColors.neutral100,
                      ),
                    ),
                    SizedBox(width: 9),
                    SizedBox(
                        width: 76,
                        child: Divider(height: 1, color: AppColors.neutral40)),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    _SocialButton('assets/icons/google.svg'),
                    SizedBox(width: 18),
                    _SocialButton('assets/icons/facebook.svg'),
                    SizedBox(width: 18),
                    _SocialButton('assets/icons/apple.svg'),
                  ],
                ),
                const SizedBox(height: 42),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('New user?', style: AppText.body),
                    _LinkText(
                      ' Create an account',
                      onTap: () => Navigator.of(context)
                          .pushReplacementNamed(Routes.signUp),
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

class _SocialButton extends StatelessWidget {
  const _SocialButton(this.asset);
  final String asset;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AppToast.show(
          context, 'Social sign-in isn’t available yet. Use your email.'),
      child: SvgPicture.asset(asset, width: 41, height: 41),
    );
  }
}

class _LinkText extends StatelessWidget {
  const _LinkText(this.text, {required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          text,
          style: AppText.body.copyWith(
            color: AppColors.primaryDark,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.primaryDark,
          ),
        ),
      ),
    );
  }
}
