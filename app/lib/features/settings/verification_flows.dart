import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/auth_service.dart';
import '../../data/backend.dart';
import '../../data/backend_profile.dart';
import '../../data/profile_service.dart';
import '../../data/user_profile.dart';
import 'settings_widgets.dart';

const _lightGrey = Color(0xFFF1F1F1);

const _noteStyle = TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 14,
    height: 1.5,
    color: Color(0xFF666666));

/// Settings -> Confirm phone number. Shows the number on file. SMS
/// verification is not available yet, so we say so instead of faking it.
class ConfirmPhoneScreen extends StatefulWidget {
  const ConfirmPhoneScreen({super.key});
  @override
  State<ConfirmPhoneScreen> createState() => _ConfirmPhoneScreenState();
}

class _ConfirmPhoneScreenState extends State<ConfirmPhoneScreen> {
  final _p = currentProfile;

  Future<void> _change() async {
    await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ChangePhoneScreen()));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: 'Phone Number',
      support: false,
      child: Column(children: [
        Container(
          height: 62,
          padding: const EdgeInsets.fromLTRB(10, 0, 8, 0),
          decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF8A8A8A)),
              borderRadius: BorderRadius.circular(2)),
          child: Row(children: [
            Expanded(
              child: Text(_p.phone.isEmpty ? 'No phone number' : _p.phone,
                  style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 18,
                      color: AppColors.black)),
            ),
            if (_p.phoneVerified)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ]),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
              _p.phoneVerified
                  ? 'Your number is verified.'
                  : 'Phone verification is coming soon. We will let you know when you can confirm your number.',
              style: _noteStyle),
        ),
        const SizedBox(height: 22),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: _change,
            child: Container(
              width: 48,
              height: 42,
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: SvgPicture.asset('assets/icons/pencil.svg',
                  width: 20,
                  height: 20,
                  colorFilter:
                      const ColorFilter.mode(AppColors.black, BlendMode.srcIn)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton(this.label, this.active, this.onTap);
  final String label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          color: active ? AppColors.primary : _lightGrey,
          child: Text(label,
              style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  color: AppColors.black)),
        ),
      );
}

/// "change your phone number": saves the number to the profile.
class ChangePhoneScreen extends StatefulWidget {
  const ChangePhoneScreen({super.key});
  @override
  State<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends State<ChangePhoneScreen> {
  final _c = TextEditingController();
  bool _busy = false;

  bool get _ok => _c.text.replaceAll(' ', '').length >= 10;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_ok || _busy) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await ProfileService.instance.update({'phone': _c.text.trim()});
      if (!mounted) return;
      AppToast.show(context, 'Phone number saved');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppToast.show(
          context,
          e is AuthFailure
              ? e.message
              : 'Could not save your number. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: 'change your phone number',
      support: false,
      child: Column(children: [
        Container(
          height: 62,
          padding: const EdgeInsets.fromLTRB(10, 0, 8, 0),
          decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF8A8A8A)),
              borderRadius: BorderRadius.circular(2)),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _c,
                autofocus: true,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))
                ],
                onChanged: (_) => setState(() {}),
                cursorColor: AppColors.primary,
                style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 18,
                    color: AppColors.black),
                decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'New phone number',
                    hintStyle:
                        TextStyle(fontSize: 15, color: Color(0xFF9A9A9A))),
              ),
            ),
            _MiniButton(_busy ? '...' : 'Save', _ok, _save),
          ]),
        ),
        const SizedBox(height: 14),
        const Align(
            alignment: Alignment.centerLeft,
            child:
                Text('Phone verification is coming soon.', style: _noteStyle)),
      ]),
    );
  }
}

/// Settings -> Change email. There is no automated flow yet, so we send the
/// request to support.
class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});
  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _p = currentProfile;
  bool _busy = false;
  bool _sent = false;

  Future<void> _contact() async {
    if (_busy || _sent) return;
    setState(() => _busy = true);
    try {
      await backend.createTicket('Change my email address',
          'I would like to change the email on my account (${_p.email}).',
          category: 'account');
      if (!mounted) return;
      setState(() {
        _busy = false;
        _sent = true;
      });
      AppToast.show(context, 'Request sent. Our team will reach out.');
    } on BackendError catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppToast.show(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: 'Change email',
      child: Column(children: [
        Container(
          width: double.infinity,
          height: 56,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF8A8A8A)),
              borderRadius: BorderRadius.circular(2)),
          child: Text(_p.email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 16,
                  color: AppColors.black)),
        ),
        const SizedBox(height: 14),
        const Align(
            alignment: Alignment.centerLeft,
            child: Text('Contact support to change your email.',
                style: _noteStyle)),
        const SizedBox(height: 22),
        SoftButton(
            label: _sent ? 'Request sent' : (_busy ? '...' : 'Contact support'),
            active: !_sent,
            onTap: _contact,
            width: 180),
      ]),
    );
  }
}

/// Submit the NIN to the verification service. Numbers are never stored
/// in the app; the server returns only a status.
class IdentitySubmitScreen extends StatefulWidget {
  const IdentitySubmitScreen({super.key});
  @override
  State<IdentitySubmitScreen> createState() => _IdentitySubmitScreenState();
}

class _IdentitySubmitScreenState extends State<IdentitySubmitScreen> {
  final _nin = TextEditingController();
  bool _busy = false;

  bool get _ok => _nin.text.length == 11;

  @override
  void dispose() {
    _nin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_ok || _busy) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await ProfileService.instance.submitIdentity(nin: _nin.text);
      await ProfileService.instance.load();
      if (!mounted) return;
      AppToast.show(context, 'Submitted. We will update your status shortly.');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppToast.show(context,
          e is AuthFailure ? e.message : 'Could not submit. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    void t(String _) => setState(() {});
    final digits = [FilteringTextInputFormatter.digitsOnly];
    return SettingsScaffold(
      title: 'Verify your identity',
      child: Column(children: [
        const Align(
            alignment: Alignment.centerLeft,
            child: Text(
                'Enter your NIN. We send it securely for checking and never keep it on your phone.',
                style: _noteStyle)),
        const SizedBox(height: 18),
        BoxField(
            controller: _nin,
            hint: 'NIN (11 digits)',
            keyboard: TextInputType.number,
            formatters: digits,
            maxLength: 11,
            onChanged: t),
        const SizedBox(height: 10),
        SoftButton(
            label: _busy ? '...' : 'Submit',
            active: _ok,
            onTap: _submit,
            width: 150),
      ]),
    );
  }
}

/// Upload a proof-of-address document to private storage. Nothing is marked
/// verified in the app: our team reviews uploads.
class AddressDocumentScreen extends StatefulWidget {
  const AddressDocumentScreen({super.key});
  @override
  State<AddressDocumentScreen> createState() => _AddressDocumentScreenState();
}

class _AddressDocumentScreenState extends State<AddressDocumentScreen> {
  String? _type;
  String? _path;
  bool _busy = false;
  bool _done = false;

  bool get _ok => _type != null && _path != null;

  Future<void> _pick() async {
    try {
      final f = await ImagePicker().pickImage(
          source: ImageSource.gallery, maxWidth: 2000, imageQuality: 85);
      if (f != null && mounted) setState(() => _path = f.path);
    } catch (_) {
      if (mounted) {
        AppToast.show(
            context, 'Could not open your photos. Check app permissions.');
      }
    }
  }

  Future<void> _submit() async {
    if (!_ok || _busy) return;
    setState(() => _busy = true);
    try {
      await backend.uploadVerificationDoc(_path!, label: 'address');
      if (mounted) setState(() => _done = true);
    } on BackendError catch (e) {
      if (mounted) AppToast.show(context, e.message);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: 'Address document',
      child: _done
          ? const Align(
              alignment: Alignment.topLeft,
              child: Text(
                  'Document received. It will be reviewed by our team; we will notify you of the outcome.',
                  style: _noteStyle))
          : Column(children: [
              DropBox(
                  hint: 'Document type',
                  value: _type,
                  options: profileAddressDocOptions,
                  onChanged: (v) => setState(() => _type = v)),
              GestureDetector(
                onTap: _pick,
                child: Row(children: [
                  const SizedBox(width: 14),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                        color: _path != null
                            ? AppColors.primaryDark
                            : AppColors.primary,
                        shape: BoxShape.circle),
                    child: Icon(_path != null ? Icons.check : Icons.add,
                        color: AppColors.black, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                        _path != null
                            ? 'Photo attached'
                            : 'Attach a photo of the document',
                        style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 14,
                            color: AppColors.black)),
                  ),
                ]),
              ),
              const SizedBox(height: 22),
              SoftButton(
                  label: _busy ? '...' : 'Submit',
                  active: _ok,
                  onTap: _submit,
                  width: 150),
            ]),
    );
  }
}
