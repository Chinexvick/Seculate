import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_arrow.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../data/auth_service.dart';
import 'auth_success_screen.dart';

class CreatePasswordScreen extends StatefulWidget {
  const CreatePasswordScreen(
      {super.key, required this.email, this.reset = false});
  final String email;

  /// True when arriving from the forgot-password flow.
  final bool reset;

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _submitted = false;

  bool get _filled => _password.text.isNotEmpty && _confirm.text.isNotEmpty;
  bool get _match => _password.text == _confirm.text;
  bool get _strong =>
      _password.text.length >= 8 &&
      RegExp(r'[A-Za-z]').hasMatch(_password.text) &&
      RegExp(r'\d').hasMatch(_password.text);

  /// Mismatch is flagged once the user has tried to confirm.
  String? get _confirmError =>
      _submitted && _filled && !_match ? 'Passwords don’t match' : null;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _confirmTap() async {
    if (_loading) return;
    setState(() => _submitted = true);
    if (!_filled || !_match) return;
    if (!_strong) {
      AppToast.show(
          context, 'Use at least 8 characters with a letter and a number.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      if (widget.reset) {
        await AuthService.instance.setPasswordOnly(_password.text);
        await AuthService.instance.signOut();
      } else {
        await AuthService.instance.setPassword(_password.text);
      }
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppToast.show(context, e.message);
      return;
    }
    if (!mounted) return;
    setState(() => _loading = false);
    if (widget.reset) {
      Navigator.of(context).pushNamedAndRemoveUntil(
          Routes.authSuccess, (r) => r.isFirst,
          arguments: AuthSuccessArgs.passwordUpdated());
    } else {
      Navigator.of(context).pushNamed(Routes.personalDetails);
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
                Text(widget.reset ? 'Create New Password' : 'Create Password',
                    style: AppText.h5),
                const SizedBox(height: 8),
                const SizedBox(
                  width: 260,
                  child: Text(
                    'Create a strong, unique password to keep your account secure',
                    textAlign: TextAlign.center,
                    style: AppText.body,
                  ),
                ),
                const SizedBox(height: 28),
                AppTextField(
                  label: 'Password',
                  controller: _password,
                  leadingIcon: 'assets/icons/lock.svg',
                  password: true,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Confirm password',
                  controller: _confirm,
                  leadingIcon: 'assets/icons/lock.svg',
                  password: true,
                  textInputAction: TextInputAction.done,
                  errorText: _confirmError,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _confirmTap(),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Confirm',
                  onPressed: _confirmTap,
                  inactive: !_filled,
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
