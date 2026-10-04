import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/tappable.dart';
import '../../data/user_profile.dart';

/// Slide-in side menu opened from the "More" tab.
Future<void> showMoreDrawer(BuildContext context) {
  final nav = Navigator.of(context);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Menu',
    barrierColor: Colors.black38,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, _, __) => Align(
      alignment: Alignment.centerLeft,
      child: _Drawer(
        onNavigate: (route, {bool replaceAll = false}) {
          Navigator.of(ctx).pop();
          if (replaceAll) {
            nav.pushNamedAndRemoveUntil(route, (_) => false);
          } else {
            nav.pushNamed(route);
          }
        },
      ),
    ),
    transitionBuilder: (_, anim, __, child) => SlideTransition(
      position: Tween(begin: const Offset(-1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );
}

class _Drawer extends StatelessWidget {
  const _Drawer({required this.onNavigate});
  final void Function(String route, {bool replaceAll}) onNavigate;

  @override
  Widget build(BuildContext context) {
    final p = currentProfile;
    return Material(
      color: Colors.white,
      elevation: 8,
      child: SizedBox(
        width: 230,
        height: double.infinity,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 30, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppImage(p.avatarUrl, width: 97, height: 97, radius: 48.5),
                const SizedBox(height: 12),
                Text(p.displayName,
                    style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 16,
                        color: AppColors.black)),
                const SizedBox(height: 2),
                Text(p.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13,
                        color: AppColors.black)),
                const SizedBox(height: 28),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Item('menu_messages', 'Messages',
                              () => onNavigate(Routes.allChats)),
                          _Item('menu_profile', 'My profile',
                              () => onNavigate(Routes.profile)),
                          _Item('menu_settings', 'Settings',
                              () => onNavigate(Routes.userSettings)),
                          _Item('menu_listings', 'My Listings',
                              () => onNavigate(Routes.myListings)),
                          _Item(Icons.manage_search_rounded, 'Item requests',
                              () => onNavigate(Routes.requests)),
                          _Item(Icons.account_balance_wallet_outlined, 'Wallet',
                              () => onNavigate(Routes.wallet)),
                          _Item(Icons.toll_outlined, 'Credits',
                              () => onNavigate(Routes.credits)),
                          _Item(Icons.verified_outlined, 'Certificates',
                              () => onNavigate(Routes.certificates)),
                          _Item(
                              Icons.workspace_premium_outlined,
                              'Pricing plans',
                              () => onNavigate(Routes.pricing)),
                          _Item('menu_care', 'Customer care',
                              () => onNavigate(Routes.support)),
                        ]),
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: Tappable(
                    onTap: () => onNavigate(Routes.logIn, replaceAll: true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4000)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        SvgPicture.asset('assets/icons/menu_logout.svg',
                            width: 18, height: 18),
                        const SizedBox(width: 5),
                        const Text('Log out',
                            style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 12,
                                color: Colors.white)),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item(this.icon, this.label, this.onTap);
  final Object icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
        child: Row(children: [
          if (icon is IconData)
            SizedBox(
                width: 24,
                height: 24,
                child: Icon(icon as IconData, size: 24, color: AppColors.black))
          else
            SvgPicture.asset('assets/icons/$icon.svg', width: 24, height: 24),
          const SizedBox(width: 14),
          Text(label,
              style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14,
                  color: Color(0xFF354764))),
        ]),
      ),
    );
  }
}
