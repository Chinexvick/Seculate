import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../borrow/borrow_screen.dart';
import '../home/home_screen.dart';
import '../post/post_ad_tab.dart';
import '../services/services_tab.dart';
import 'more_drawer.dart';

/// Lets any descendant switch the bottom-nav tab.
class ShellController extends InheritedWidget {
  const ShellController({super.key, required this.goTo, required super.child});
  final void Function(int index) goTo;

  static ShellController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellController>();

  @override
  bool updateShouldNotify(ShellController old) => false;
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  // Tabs are built lazily the first time they're visited, then kept alive.
  final Set<int> _built = {0};

  void _goTo(int i) {
    if (i == _index) return;
    setState(() {
      _index = i;
      _built.add(i);
    });
  }

  Widget _tab(int i) {
    if (!_built.contains(i)) return const SizedBox.shrink();
    switch (i) {
      case 0:
        return const HomeScreen();
      case 1:
        return const BorrowScreen();
      case 2:
        return const PostAdTab();
      case 3:
        return const ServicesTab();
      default:
        return _ComingSoon(title: _items[i].label);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShellController(
      goTo: _goTo,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: IndexedStack(
          index: _index,
          children: [for (var i = 0; i < _items.length; i++) _tab(i)],
        ),
        bottomNavigationBar: Builder(
          builder: (ctx) => _NavBar(
            index: _index,
            // "More" opens the side menu instead of switching tab.
            onTap: (i) => i == 4 ? showMoreDrawer(ctx) : _goTo(i),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.activeIcon,
      {this.tintActive = true});
  final String label;
  final String icon;
  final String activeIcon;

  /// The active home icon is already green, so it must not be tinted.
  final bool tintActive;
}

const _items = <_NavItem>[
  _NavItem(
      'Home', 'assets/icons/nav_home_outline.svg', 'assets/icons/nav_home.svg',
      tintActive: false),
  _NavItem('Borrow', 'assets/icons/nav_borrow.svg',
      'assets/icons/nav_borrow_active.svg'),
  _NavItem('Post ad', 'assets/icons/nav_post.svg', 'assets/icons/nav_post.svg'),
  _NavItem('Services', 'assets/icons/nav_services.svg',
      'assets/icons/nav_services_active.svg'),
  _NavItem(
      'More', 'assets/icons/nav_more.svg', 'assets/icons/nav_more_active.svg'),
];

class _NavBar extends StatelessWidget {
  const _NavBar({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.neutral50, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: _NavButton(item: _items[i], active: i == index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.active});
  final _NavItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.neutral100;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 1, end: active ? 1.12 : 1),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          builder: (_, s, child) => Transform.scale(scale: s, child: child),
          child: SvgPicture.asset(
            active ? item.activeIcon : item.icon,
            width: 24,
            height: 24,
            colorFilter: (active && !item.tintActive)
                ? null
                : ColorFilter.mode(color, BlendMode.srcIn),
          ),
        ),
        const SizedBox(height: 4),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 10,
            color: color,
          ),
          child: Text(item.label),
        ),
      ],
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(child: Text('$title - coming next', style: AppText.body)),
    );
  }
}
