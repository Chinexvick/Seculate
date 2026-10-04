import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';

/// Where the success screen sends the user next.
class AuthSuccessArgs {
  const AuthSuccessArgs({
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.nextRoute,
    this.nextArguments,
    this.clearStack = false,
  });

  final String title;
  final String message;
  final String buttonLabel;
  final String nextRoute;
  final Object? nextArguments;

  /// True when the next screen should replace the whole auth stack (e.g. back to log in).
  final bool clearStack;

  factory AuthSuccessArgs.emailVerified(Object? next) => AuthSuccessArgs(
        title: 'Email verified',
        message:
            'Your email is confirmed. One more step: create a password to secure your account.',
        buttonLabel: 'Create password',
        nextRoute: '/create-password',
        nextArguments: next,
      );

  factory AuthSuccessArgs.passwordUpdated() => const AuthSuccessArgs(
        title: 'Password updated',
        message:
            'Your password was changed. Log in with your new password to continue.',
        buttonLabel: 'Back to log in',
        nextRoute: '/log-in',
        clearStack: true,
      );
}

/// Shared confirmation screen for the sign-up and password-reset flows.
class AuthSuccessScreen extends StatelessWidget {
  const AuthSuccessScreen({super.key, required this.args});
  final AuthSuccessArgs args;

  void _go(BuildContext context) {
    final nav = Navigator.of(context);
    if (args.clearStack) {
      nav.pushNamedAndRemoveUntil(args.nextRoute, (r) => r.isFirst,
          arguments: args.nextArguments);
    } else {
      nav.pushReplacementNamed(args.nextRoute, arguments: args.nextArguments);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: Column(
              children: [
                const Spacer(flex: 3),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.6, end: 1),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutBack,
                  builder: (_, v, child) =>
                      Transform.scale(scale: v, child: child),
                  child: Container(
                    key: const Key('auth-success-badge'),
                    width: 104,
                    height: 104,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF9EE),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(36),
                        topRight: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(36),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                            color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 38),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(args.title,
                    style: AppText.h5, textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Text(args.message,
                    textAlign: TextAlign.center, style: AppText.body),
                const Spacer(flex: 4),
                AppButton(
                    label: args.buttonLabel, onPressed: () => _go(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
