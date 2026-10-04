import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../data/auth_service.dart';
import '../../data/user_profile.dart';

/// Shown instead of the app when an account is suspended or banned.
class AccountBlockedScreen extends StatelessWidget {
  const AccountBlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final banned = currentProfile.accountStatus == 'banned';
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: Column(
            children: [
              const Spacer(flex: 3),
              const Icon(Icons.shield_outlined,
                  size: 72, color: AppColors.alert),
              const SizedBox(height: 20),
              Text(banned ? 'Account closed' : 'Account suspended',
                  style: AppText.h5),
              const SizedBox(height: 10),
              Text(
                  banned
                      ? 'This account was closed for breaking our community rules.'
                      : 'Your account is paused after a review of activity that broke our community rules. You can contact support to appeal.',
                  textAlign: TextAlign.center,
                  style: AppText.body),
              const Spacer(flex: 4),
              AppButton(
                label: 'Log out',
                onPressed: () async {
                  await AuthService.instance.signOut();
                  currentProfile.clear();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        Routes.onboarding, (_) => false);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
