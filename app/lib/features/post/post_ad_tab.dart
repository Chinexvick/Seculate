import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/back_arrow.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../shell/main_shell.dart';

/// "Post ad" tab: lend onboarding with the two ways to earn.
class PostAdTab extends StatelessWidget {
  const PostAdTab({super.key});

  @override
  Widget build(BuildContext context) {
    final shell = ShellController.maybeOf(context);
    return SafeArea(
      child: LayoutBuilder(builder: (context, box) {
        // Shrink the illustration on short screens so the buttons stay
        // above the nav bar; the page also scrolls as a safety net.
        final img = ((box.maxHeight - 330) * 0.85).clamp(120.0, 336.0);
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight - 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => shell?.goTo(0),
                    behavior: HitTestBehavior.opaque,
                    child: const IgnorePointer(child: BackArrow()),
                  ),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  child: Image.asset('assets/images/lend.png',
                      width: img, height: img, fit: BoxFit.contain),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: Column(
                    children: const [
                      SizedBox(
                        width: 315,
                        child: Text(
                          'Make Money from What You Own and Know',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w500,
                            fontSize: 24,
                            height: 32 / 24,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      SizedBox(
                        width: 315,
                        child: Text(
                          'Rent out items or offer your skills to earn money from people around you.',
                          textAlign: TextAlign.center,
                          style: AppText.body,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 200),
                  child: Column(
                    children: [
                      AppButton(
                        label: 'List item',
                        onPressed: () =>
                            Navigator.of(context).pushNamed(Routes.listItem),
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        label: 'Request service',
                        color: AppColors.black,
                        onPressed: () =>
                            Navigator.of(context).pushNamed(Routes.postService),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
