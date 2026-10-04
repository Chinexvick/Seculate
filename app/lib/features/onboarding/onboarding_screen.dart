import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/fade_slide_in.dart';

class _OnboardingPage {
  const _OnboardingPage({
    required this.image,
    required this.title,
    required this.description,
    required this.gapToDots,
  });
  final String image;
  final String title;
  final String description;

  /// Space between the illustration's bottom edge and the dots (from Figma).
  final double gapToDots;
}

const _pages = <_OnboardingPage>[
  _OnboardingPage(
    image: 'assets/images/onboarding_1.png',
    title: 'Lend to profit, borrow to succeed.',
    description:
        'Borrow items, lend unused stuff and get paid, or access handy services — all within a trusted community.',
    gapToDots: 78,
  ),
  _OnboardingPage(
    image: 'assets/images/onboarding_2.png',
    title: 'Secure Collateral System',
    description:
        'Optional fund locking protects lenders and builds trust — keeping items and the community safe.',
    gapToDots: 68,
  ),
  _OnboardingPage(
    image: 'assets/images/onboarding_3.png',
    title: 'Verified & Rated Community',
    description:
        'Know who you’re dealing with. Verified profiles, reviews, and ratings help you borrow and lend with confidence.',
    gapToDots: 9,
  ),
  _OnboardingPage(
    image: 'assets/images/onboarding_4.png',
    title: 'Flexible Plans, Transparent Fees',
    description:
        'Access the platform with simple subscriptions. No hidden fees, just seamless peer-to-peer transactions.',
    gapToDots: 9,
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _IllustrationPage(page: _pages[i]),
              ),
            ),
            _Dots(count: _pages.length, index: _index),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.08),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: Column(
                  key: ValueKey(_index),
                  children: [
                    Text(
                      _pages[_index].title,
                      textAlign: TextAlign.center,
                      style: AppText.h5,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _pages[_index].description,
                      textAlign: TextAlign.center,
                      style: AppText.body,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: FadeSlideIn(
                delay: const Duration(milliseconds: 150),
                child: Column(
                  children: [
                    AppButton(
                      label: 'Create an account',
                      onPressed: () =>
                          Navigator.of(context).pushNamed(Routes.signUp),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: 'Log in',
                      color: AppColors.black,
                      onPressed: () =>
                          Navigator.of(context).pushNamed(Routes.logIn),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _IllustrationPage extends StatelessWidget {
  const _IllustrationPage({required this.page});
  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(17, 0, 17, page.gapToDots),
        child: FadeSlideIn(
          child: Image.asset(
            page.image,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            cacheWidth: 1068,
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.only(left: i == 0 ? 0 : 5),
          height: 6.3,
          width: active ? 32.9 : 6.3,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.neutral50,
            borderRadius: BorderRadius.circular(126),
          ),
        );
      }),
    );
  }
}
