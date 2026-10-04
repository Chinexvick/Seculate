import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/auth_service.dart';
import 'settings_widgets.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _cur = TextEditingController();
  final _new = TextEditingController();
  final _re = TextEditingController();
  final _show = [false, false, false];
  bool _busy = false;

  bool get _ok =>
      _cur.text.isNotEmpty && _strong(_new.text) && _new.text == _re.text;

  static bool _strong(String v) =>
      v.length >= 8 &&
      RegExp(r'[A-Za-z]').hasMatch(v) &&
      RegExp(r'\d').hasMatch(v);

  @override
  void dispose() {
    _cur.dispose();
    _new.dispose();
    _re.dispose();
    super.dispose();
  }

  Widget _eye(int i) => GestureDetector(
        onTap: () => setState(() => _show[i] = !_show[i]),
        child: Icon(
            _show[i]
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 22,
            color: AppColors.neutral100),
      );

  Future<void> _submit() async {
    if (!_ok || _busy) {
      if (!_ok) {
        AppToast.show(context,
            'Use at least 8 characters with a letter and a number, and make both new passwords match');
      }
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await AuthService.instance.changePassword(_cur.text, _new.text);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppToast.show(context, e.message);
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppToast.show(
          context, 'Could not change your password. Please try again.');
      return;
    }
    if (!mounted) return;
    final nav = Navigator.of(context);
    AppToast.show(context, 'Password changed');
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    void t(String _) => setState(() {});
    return SettingsScaffold(
      title: 'Change password',
      child: Column(children: [
        BoxField(
            controller: _cur,
            hint: 'Enter your current pssword',
            obscure: !_show[0],
            suffix: _eye(0),
            onChanged: t),
        BoxField(
            controller: _new,
            hint: 'New password',
            obscure: !_show[1],
            suffix: _eye(1),
            onChanged: t),
        BoxField(
            controller: _re,
            hint: 'Re-type new password',
            obscure: !_show[2],
            suffix: _eye(2),
            errorText: _re.text.isNotEmpty && _re.text != _new.text
                ? 'Passwords do not match'
                : null,
            onChanged: t),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pushNamed(Routes.forgotPassword),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Forgot Password?',
                  style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13,
                      color: AppColors.primaryDark,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primaryDark)),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SoftButton(
            label: _busy ? '...' : 'Continue',
            active: _ok,
            onTap: _submit,
            width: 150),
      ]),
    );
  }
}
