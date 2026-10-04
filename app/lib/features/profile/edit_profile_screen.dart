import 'package:flutter/material.dart';
import '../auth/identity_verification_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_arrow.dart';
import '../../core/widgets/radio_sheet.dart';
import '../../core/widgets/tappable.dart';
import '../../data/auth_service.dart';
import '../../data/profile_service.dart';
import '../../data/user_profile.dart';
import '../settings/verification_flows.dart';
import 'profile_screen.dart' show pickAndUploadAvatar, verificationLabel;

/// "Personal details" edit form. The save pill turns into a green "Saved"
/// pill, then the screen closes.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _p = currentProfile;
  late final _first = TextEditingController(text: _p.firstName);
  late final _last = TextEditingController(text: _p.lastName);
  late final _phone = TextEditingController(text: _p.phone);
  late final _email = TextEditingController(text: _p.email);
  late final _address = TextEditingController(text: _p.address);

  late String _location = _p.location;
  late String _birthday = _p.birthday;
  late String _sex = _p.sex;

  bool _saved = false;
  bool _saving = false;
  bool _uploading = false;

  @override
  void dispose() {
    for (final c in [_first, _last, _phone, _email, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid =>
      _first.text.trim().isNotEmpty && _last.text.trim().isNotEmpty;

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (_saved) return;
    if (!_valid) {
      AppToast.show(context, 'First and last name are required');
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    final fields = <String, dynamic>{
      'first_name': _first.text.trim(),
      'last_name': _last.text.trim(),
      'address': _address.text.trim(),
      'country': _location,
    };
    final phone = _phone.text.trim();
    if (phone.isNotEmpty) fields['phone'] = phone;
    final iso = _birthdayIso();
    if (iso != null) fields['birthday'] = iso;
    if (profileSexOptions.contains(_sex)) fields['sex'] = _sex;
    try {
      await ProfileService.instance.update(fields);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _saving = false);
      if (mounted) AppToast.show(context, e.message);
      return;
    } catch (_) {
      if (mounted) setState(() => _saving = false);
      if (mounted) {
        AppToast.show(
            context, 'Could not save your changes. Please try again.');
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saved = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted) Navigator.of(context).pop();
  }

  /// dd/MM/yyyy -> yyyy-MM-dd (null when empty/invalid).
  String? _birthdayIso() {
    final parts = _birthday.split('/');
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]),
        m = int.tryParse(parts[1]),
        y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return null;
    String two(int n) => n.toString().padLeft(2, '0');
    return '$y-${two(m)}-${two(d)}';
  }

  Future<void> _photo() async {
    if (_uploading) return;
    setState(() => _uploading = true);
    final ok = await pickAndUploadAvatar(context);
    if (!mounted) return;
    setState(() => _uploading = false);
    if (ok) AppToast.show(context, 'Photo updated');
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _initialDate(),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      String two(int n) => n.toString().padLeft(2, '0');
      setState(() => _birthday = '${two(d.day)}/${two(d.month)}/${d.year}');
    }
  }

  DateTime _initialDate() {
    final iso = _birthdayIso();
    final d = iso == null ? null : DateTime.tryParse(iso);
    return d ?? DateTime(1995, 1, 1);
  }

  Future<void> _pick(String title, List<String> opts, String cur,
      ValueChanged<String> set) async {
    FocusScope.of(context).unfocus();
    final r = await showRadioSheet(
      context,
      title: title,
      options: [for (final o in opts) SheetOption(o, o)],
      selectedId: cur,
    );
    if (r != null) setState(() => set(r));
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
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Personal details',
                            style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 15,
                                color: AppColors.black)),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _save,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: _saved
                                ? AppColors.primary
                                : const Color(0xFFEAEAEA),
                            borderRadius: BorderRadius.circular(4000),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Text(
                                _saved ? 'Saved' : (_saving ? '...' : 'save'),
                                key: ValueKey(_saved),
                                style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 12,
                                    color: _saved
                                        ? Colors.black
                                        : AppColors.neutral200)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
                    child: Column(
                      children: [
                        Center(
                            child: _Avatar(url: _p.avatarUrl, onEdit: _photo)),
                        const SizedBox(height: 36),
                        _Box.text('First Name*', _first,
                            onChanged: (_) => setState(() {})),
                        _Box.text('Last Name*', _last,
                            onChanged: (_) => setState(() {})),
                        _Box.pick('Location', _location,
                            onTap: () => _pick('Location', profileCountries,
                                _location, (v) => _location = v)),
                        _Box.pick('Birthday', _birthday,
                            placeholder: 'Choose your date of birth',
                            icon: Icons.calendar_today_outlined,
                            onTap: _pickDate),
                        _Box.pick('Sex', _sex,
                            placeholder: 'Choose your gender',
                            onTap: () => _pick('Sex', profileSexOptions, _sex,
                                (v) => _sex = v)),
                        _Box.pick('Identity verification',
                            verificationLabel(_p.verificationStatus),
                            onTap: () async {
                          if (_p.verificationStatus == 'verified' ||
                              _p.verificationStatus == 'pending') {
                            AppToast.show(context,
                                verificationLabel(_p.verificationStatus));
                            return;
                          }
                          await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const IdentityVerificationScreen(
                                          onboarding: false)));
                          if (mounted) setState(() {});
                        }),
                        _Box.text('Phone number',
                            _phone, keyboard: TextInputType.phone, formatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))
                        ]),
                        _Box.pick('Email', _p.email,
                            icon: Icons.lock_outline,
                            onTap: () => Navigator.of(context)
                                .pushNamed(Routes.changeEmail)),
                        _Box.text('Address', _address),
                        _Box.pick('Address document', '',
                            placeholder: 'Upload an address document',
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const AddressDocumentScreen()))),
                      ],
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
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.onEdit});
  final String? url;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 124,
      height: 124,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipOval(
              child: AppImage(url, width: 124, height: 124, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            right: -2,
            bottom: 6,
            child: Tappable(
              onTap: onEdit,
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                    color: Color(0xFFEAEAEA), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: SvgPicture.asset('assets/icons/pencil.svg',
                    width: 18, height: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Green caption above an outlined box (text field or picker).
class _Box extends StatelessWidget {
  const _Box._(this.label,
      {this.controller,
      this.value,
      this.placeholder,
      this.onTap,
      this.icon,
      this.keyboard,
      this.formatters,
      this.onChanged});

  factory _Box.text(String label, TextEditingController c,
          {TextInputType? keyboard,
          List<TextInputFormatter>? formatters,
          ValueChanged<String>? onChanged}) =>
      _Box._(label,
          controller: c,
          keyboard: keyboard,
          formatters: formatters,
          onChanged: onChanged);

  factory _Box.pick(String label, String value,
          {String? placeholder, IconData? icon, required VoidCallback onTap}) =>
      _Box._(label,
          value: value, placeholder: placeholder, icon: icon, onTap: onTap);

  final String label;
  final TextEditingController? controller;
  final String? value;
  final String? placeholder;
  final VoidCallback? onTap;
  final IconData? icon;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? formatters;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isPick = controller == null;
    final empty = (value ?? '').isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 10,
                  color: AppColors.primary)),
          const SizedBox(height: 4),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: AppColors.neutral50),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: isPick
                        ? Text(empty ? (placeholder ?? '') : value!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: empty ? 11 : 14,
                                color: AppColors.neutral200))
                        : TextField(
                            controller: controller,
                            keyboardType: keyboard,
                            inputFormatters: formatters,
                            onChanged: onChanged,
                            cursorColor: AppColors.primary,
                            style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 14,
                                color: AppColors.black),
                            decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero),
                          ),
                  ),
                  if (isPick)
                    Icon(icon ?? Icons.arrow_drop_down,
                        size: icon == null ? 26 : 20,
                        color: AppColors.neutral50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
