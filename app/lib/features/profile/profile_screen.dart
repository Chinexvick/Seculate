import 'package:flutter/material.dart';
import '../../data/backend_wallet.dart';
import '../../core/widgets/trust_badge.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_arrow.dart';
import '../../core/widgets/tappable.dart';
import '../../data/backend.dart';
import '../../data/profile_service.dart';
import '../../data/user_profile.dart';

/// Human label for the server-controlled verification status.
String verificationLabel(String status) {
  switch (status) {
    case 'verified':
      return 'Verified';
    case 'pending':
      return 'Under review';
    case 'rejected':
      return 'Verification rejected';
    default:
      return 'Not verified';
  }
}

/// Lets the user pick a photo and uploads it as their avatar.
/// Returns true when the avatar changed.
Future<bool> pickAndUploadAvatar(BuildContext context) async {
  try {
    final f = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
    if (f == null) return false;
    await backend.uploadAvatar(f.path);
    return true;
  } on BackendError catch (e) {
    if (context.mounted) AppToast.show(context, e.message);
  } catch (_) {
    if (context.mounted) {
      AppToast.show(
          context, 'Could not open your photos. Check app permissions.');
    }
  }
  return false;
}

/// "My profile" (read-only) with Personal Info / Business Info tabs.
/// "Edit" opens the Personal details form.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _p = currentProfile;
  bool _business = false;
  String _plan = '';
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      await ProfileService.instance.load();
    } catch (_) {}
    try {
      final s = await backend.planStatus();
      final plan = s['plan'];
      if (plan is Map && plan['name'] != null) _plan = '${plan['name']}';
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _photo() async {
    if (_uploading) return;
    setState(() => _uploading = true);
    final ok = await pickAndUploadAvatar(context);
    if (!mounted) return;
    setState(() => _uploading = false);
    if (ok) AppToast.show(context, 'Photo updated');
  }

  Future<void> _logout() async {
    final nav = Navigator.of(context);
    await backend.signOut();
    nav.pushNamedAndRemoveUntil(Routes.onboarding, (_) => false);
  }

  Future<void> _edit() async {
    await Navigator.of(context).pushNamed(Routes.editProfile);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 20, 0),
                  child: Row(
                    children: [
                      const SizedBox(width: 32, child: BackArrow()),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('My profile',
                            style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 15,
                                color: AppColors.black)),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _edit,
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Text('Edit',
                              style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 13,
                                  color: AppColors.primary)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _Header(
                  name: _p.displayName,
                  plan: _plan,
                  status: _p.verificationStatus,
                  ratingAvg: _p.ratingAvg,
                  ratingCount: _p.ratingCount,
                  avatarUrl: _p.avatarUrl,
                  business: _business,
                  onEditAccount: _edit,
                  onDeleteAccount: () =>
                      Navigator.of(context).pushNamed(Routes.deleteAccount),
                  onCamera: _photo,
                ),
                const SizedBox(height: 22),
                _Tabs(
                    business: _business,
                    onChanged: (b) => setState(() => _business = b)),
                const SizedBox(height: 4),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: SingleChildScrollView(
                      key: ValueKey(_business),
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 100),
                      child: _business ? _businessFields() : _personalFields(),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 22,
              bottom: 24,
              child: Tappable(
                onTap: () => Navigator.of(context).pushNamed(Routes.support),
                child: SvgPicture.asset('assets/icons/headset.svg',
                    width: 52, height: 52),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _personalFields() => Column(children: [
        const SizedBox(height: 14),
        const _TrustCard(),
        _LinkRow(Icons.account_balance_wallet_outlined, 'Wallet',
            () => Navigator.of(context).pushNamed(Routes.wallet)),
        _LinkRow(Icons.workspace_premium_outlined, 'Certificates',
            () => Navigator.of(context).pushNamed(Routes.certificates)),
        const SizedBox(height: 8),
        _Field('First Name*', _p.firstName),
        _Field('Last Name*', _p.lastName),
        _Field('Birthday', _p.birthday,
            placeholder: 'Choose your date of birth'),
        _Field('Sex', _p.sex, placeholder: 'Choose your gender'),
        _Field(
            'Identity verification', verificationLabel(_p.verificationStatus)),
        _Field('Phone number', _p.phone),
        _Field('Email', _p.email),
        _Field('Address', _p.address,
            placeholder: 'Link your address document'),
        const SizedBox(height: 18),
        _Link('My listings',
            () => Navigator.of(context).pushNamed(Routes.myListings)),
        _Link('My transactions',
            () => Navigator.of(context).pushNamed('/transactions')),
        _Link('Notifications',
            () => Navigator.of(context).pushNamed(Routes.notifications)),
        _Link('Settings',
            () => Navigator.of(context).pushNamed(Routes.userSettings)),
        _Link('Support', () => Navigator.of(context).pushNamed(Routes.support)),
        _Link('Pricing', () => Navigator.of(context).pushNamed(Routes.pricing)),
        _Link('Log out', _logout),
      ]);

  Widget _businessFields() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 26),
          const _Section('Business'),
          _Field('Business Name*', _p.businessName),
          _Field('About company', _p.about),
          _Field('Business link', _p.link),
        ],
      );
}

class _Header extends StatelessWidget {
  const _Header(
      {required this.name,
      required this.plan,
      required this.status,
      required this.ratingAvg,
      required this.ratingCount,
      required this.avatarUrl,
      required this.business,
      required this.onEditAccount,
      required this.onDeleteAccount,
      required this.onCamera});
  final String name;
  final String plan;
  final String status;
  final double ratingAvg;
  final int ratingCount;
  final String? avatarUrl;
  final bool business;
  final VoidCallback onEditAccount;
  final VoidCallback onDeleteAccount;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          SizedBox(
            width: 124,
            height: 124,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipOval(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: business
                          ? Container(
                              key: const ValueKey('b'),
                              color: Colors.white,
                              padding: const EdgeInsets.all(14),
                              child: Image.asset(
                                  'assets/images/profile/lock.png',
                                  fit: BoxFit.contain),
                            )
                          : AppImage(avatarUrl,
                              key: const ValueKey('a'),
                              width: 124,
                              height: 124,
                              fit: BoxFit.cover),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 6,
                  child: Tappable(
                    onTap: onCamera,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: SvgPicture.asset('assets/icons/camera_badge.svg',
                          width: 22, height: 22),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: AppColors.black)),
                const SizedBox(height: 6),
                Text(plan.isEmpty ? 'Member' : plan,
                    style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14,
                        color: AppColors.black)),
                const SizedBox(height: 4),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                      status == 'verified'
                          ? Icons.verified
                          : Icons.shield_outlined,
                      size: 14,
                      color: status == 'verified'
                          ? AppColors.primary
                          : AppColors.neutral200),
                  const SizedBox(width: 4),
                  Text(verificationLabel(status),
                      style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 11,
                          color: AppColors.neutral200)),
                ]),
                if (ratingCount > 0) ...[
                  const SizedBox(height: 4),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star_rounded,
                        size: 14, color: Color(0xFFF5B301)),
                    const SizedBox(width: 3),
                    Text('${ratingAvg.toStringAsFixed(1)} ($ratingCount)',
                        style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 11,
                            color: AppColors.neutral200)),
                  ]),
                ],
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onEditAccount,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        SvgPicture.asset('assets/icons/pencil.svg',
                            width: 16, height: 16),
                        const SizedBox(width: 6),
                        const Text('Not my account',
                            style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 10,
                                color: AppColors.black)),
                      ]),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onDeleteAccount,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: SvgPicture.asset('assets/icons/x_small.svg',
                            width: 15, height: 15),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 14),
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.neutral40))),
          child: Row(children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14,
                      color: AppColors.black)),
            ),
            const Icon(Icons.chevron_right, size: 22, color: AppColors.black),
          ]),
        ),
      );
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.business, required this.onChanged});
  final bool business;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, bool selected, VoidCallback onTap) => Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(label,
                  style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                      fontSize: 12,
                      color:
                          selected ? AppColors.black : AppColors.neutral200)),
            ),
          ),
        );
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 52),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: const Color(0xFFEAEAEA),
          borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        tab('Personal Info', !business, () => onChanged(false)),
        tab('Business Info', business, () => onChanged(true)),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 10, bottom: 18),
        child: Text(title,
            style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 18,
                color: AppColors.black)),
      );
}

/// Green caption + value with a bottom divider (Figma profile row).
class _Field extends StatelessWidget {
  const _Field(this.label, this.value, {this.placeholder});
  final String label;
  final String value;
  final String? placeholder;

  @override
  Widget build(BuildContext context) {
    final empty = value.isEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.neutral40))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 10,
                  color: AppColors.primaryDark)),
          const SizedBox(height: 6),
          SizedBox(
            height: 28,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(empty ? (placeholder ?? '') : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 15,
                      color: empty
                          ? AppColors.neutral100
                          : const Color(0xFF555555))),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            Icon(icon, size: 22, color: AppColors.black),
            const SizedBox(width: 12),
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 15,
                        color: AppColors.black))),
            const Icon(Icons.chevron_right, color: AppColors.neutral100),
          ]),
        ),
      );
}

/// Trust score with a short, honest breakdown of where it comes from.
class _TrustCard extends StatefulWidget {
  const _TrustCard();
  @override
  State<_TrustCard> createState() => _TrustCardState();
}

class _TrustCardState extends State<_TrustCard> {
  Map<String, dynamic>? _t;

  @override
  void initState() {
    super.initState();
    backend.myTrust().then((t) {
      if (mounted) setState(() => _t = t);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    if (t == null) return const SizedBox.shrink();
    final score = (t['score'] as num?)?.toInt() ?? 0;
    final band = '${t['band'] ?? 'new'}';
    final c = TrustBadge.color(band);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: const Color(0xFFF5F6F7),
          borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Trust score',
              style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: AppColors.black)),
          const Spacer(),
          TrustBadge(band: band, score: score),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              color: c,
              backgroundColor: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
            '${t['completed_deals']} finished deals · ${t['reviews']} reviews'
            '${t['verified'] == true ? ' · ID verified' : ' · verify your ID to raise it'}'
            '${(t['disputes_lost'] as num? ?? 0) > 0 ? ' · ${t['disputes_lost']} problem decisions against you' : ''}',
            style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12,
                height: 1.4,
                color: AppColors.neutral200)),
      ]),
    );
  }
}
