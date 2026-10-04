import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/auth_service.dart';
import '../../data/profile_service.dart';
import '../../data/user_profile.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  late final Animation<double> _title = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.65, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _tagline = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.35, 1, curve: Curves.easeOutCubic),
  );

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final started = DateTime.now();
    _decide().then((route) async {
      // Keep the splash visible long enough for the animation.
      final left = 2400 - DateTime.now().difference(started).inMilliseconds;
      if (left > 0) await Future<void>.delayed(Duration(milliseconds: left));
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(route);
    });
  }

  /// Signed-in users resume where they left off; others see onboarding.
  Future<String> _decide() async {
    try {
      if (!AuthService.instance.signedIn) return Routes.onboarding;
      final step = await AuthService.instance.onboardingStep();
      if (step == 'done' || step == 'plan') {
        await ProfileService.instance.load();
        final st = currentProfile.accountStatus;
        if (st == 'suspended' || st == 'banned') return Routes.accountBlocked;
        return Routes.home;
      }
      return AuthService.routeForStep(step);
    } catch (_) {
      return AuthService.instance.signedIn ? Routes.home : Routes.onboarding;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _title,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1).animate(_title),
                child: const Text('Seculate', style: AppText.splashTitle),
              ),
            ),
            const SizedBox(height: 0),
            FadeTransition(
              opacity: _tagline,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.4),
                  end: Offset.zero,
                ).animate(_tagline),
                child: const Text(
                  'Own it for as long as you need it.',
                  style: AppText.splashTagline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
