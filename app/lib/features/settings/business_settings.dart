import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/auth_service.dart';
import '../../data/profile_service.dart';
import '../../data/user_profile.dart';
import 'settings_widgets.dart';

/// Settings → Business details hub.
class BusinessDetailsScreen extends StatelessWidget {
  const BusinessDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void go(String r) => Navigator.of(context).pushNamed(r);
    return SettingsScaffold(
      title: 'Business details',
      child: Column(
        children: [
          Center(
            child: SizedBox(
              width: 100,
              height: 120,
              child: Stack(children: [
                Positioned.fill(
                    child: Image.asset('assets/images/profile/lock.png',
                        fit: BoxFit.contain)),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          _HubRow('Company name, description\nand links',
              () => go(Routes.companyDetails)),
        ],
      ),
    );
  }
}

class _HubRow extends StatelessWidget {
  const _HubRow(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF8A8A8A)))),
          child: Row(children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xFF444444))),
            ),
            const Icon(Icons.arrow_drop_down,
                color: Color(0xFFD4D4D4), size: 28),
          ]),
        ),
      );
}

/// Company name / about / link.
class CompanyDetailsScreen extends StatefulWidget {
  const CompanyDetailsScreen({super.key});

  @override
  State<CompanyDetailsScreen> createState() => _CompanyDetailsScreenState();
}

class _CompanyDetailsScreenState extends State<CompanyDetailsScreen> {
  final _p = currentProfile;
  late final _name = TextEditingController(text: _p.businessName);
  late final _about = TextEditingController(text: _p.about);
  late final _link = TextEditingController(text: _p.link);
  bool _saved = false;
  bool _busy = false;

  bool get _filled => _name.text.trim().isNotEmpty;

  @override
  void dispose() {
    _name.dispose();
    _about.dispose();
    _link.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_filled) {
      AppToast.show(context, 'Business name is required');
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ProfileService.instance.update({
        'business_name': _name.text.trim(),
        'business_about': _about.text.trim(),
        'business_link': _link.text.trim(),
      });
      if (mounted) setState(() => _saved = true);
    } catch (e) {
      if (mounted) {
        AppToast.show(context,
            e is AuthFailure ? e.message : 'Could not save. Please try again.');
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    void touch(String _) => setState(() => _saved = false);
    return SettingsScaffold(
      title: 'Company name, description and links',
      trailing: SavePill(saved: _saved, onTap: _save),
      child: Column(children: [
        BoxField(controller: _name, hint: 'Business name', onChanged: touch),
        BoxField(controller: _about, hint: 'About copany', onChanged: touch),
        BoxField(
            controller: _link,
            hint: 'Business link',
            keyboard: TextInputType.url,
            onChanged: touch),
        const SizedBox(height: 30),
        Center(
            child: SoftButton(
                label: _saved ? 'Saved' : 'save',
                active: _filled,
                onTap: _save)),
      ]),
    );
  }
}
