import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/auth_service.dart';
import '../../data/backend.dart';
import '../../data/backend_profile.dart';
import '../../data/profile_service.dart';
import '../../data/user_profile.dart';
import 'settings_widgets.dart';

/// Settings hub.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void go(String r) => Navigator.of(context).pushNamed(r);
    return SettingsScaffold(
      title: 'Settings',
      scroll: false,
      child: Container(
        color: const Color(0xFFEFFBEF),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _Group([
              _Row('Personal details', () => go(Routes.editProfile)),
              _Row('Business Details', () => go(Routes.businessDetails)),
            ]),
            _Group([
              _Row('Confirm phone number', () => go(Routes.confirmPhone)),
              _Row('Change email', () => go(Routes.changeEmail)),
              _Row('Change Language', () => go(Routes.changeLanguage)),
            ]),
            _Group([
              _Row('Disable chat', () => go(Routes.chatToggle)),
              _Row('Disable feedback', () => go(Routes.feedbackToggle)),
              _Row('Manage feedback', () => go(Routes.manageNotifications)),
            ]),
            _Group([
              _Row('Change password', () => go(Routes.changePassword)),
              _Row('Delete my account permanently',
                  () => go(Routes.deleteAccount)),
              _Row('Log out', () async {
                final nav = Navigator.of(context);
                await backend.signOut();
                nav.pushNamedAndRemoveUntil(Routes.onboarding, (_) => false);
              }),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(this.rows);
  final List<Widget> rows;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Container(
          color: Colors.white,
          child: Column(children: rows),
        ),
      );
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 50),
          padding: const EdgeInsets.fromLTRB(32, 12, 18, 12),
          decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Color(0xFF8A8A8A), width: 0.7))),
          child: Row(children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14,
                      color: Color(0xFF444444))),
            ),
            const Icon(Icons.chevron_right, size: 26, color: AppColors.black),
          ]),
        ),
      );
}

/// Change language: single dropdown (stored in profiles.language).
class ChangeLanguageScreen extends StatefulWidget {
  const ChangeLanguageScreen({super.key});
  @override
  State<ChangeLanguageScreen> createState() => _ChangeLanguageScreenState();
}

class _ChangeLanguageScreenState extends State<ChangeLanguageScreen> {
  bool _busy = false;

  Future<void> _set(String v) async {
    if (_busy) return;
    final p = currentProfile;
    final old = p.language;
    setState(() {
      p.language = v;
      _busy = true;
    });
    try {
      await ProfileService.instance.update({'language': v});
      if (mounted) AppToast.show(context, 'Language updated');
    } catch (e) {
      p.language = old;
      if (mounted) {
        AppToast.show(context,
            e is AuthFailure ? e.message : 'Could not update the language.');
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = currentProfile;
    return SettingsScaffold(
      title: 'Change Language',
      child: DropBox(
        hint: 'Language',
        value: p.language,
        options: const [
          'English UK',
          'English US',
          'Yoruba',
          'Igbo',
          'Hausa',
          'Pidgin'
        ],
        onChanged: _set,
      ),
    );
  }
}

/// Custom green toggle matching the Figma switch (knob left = off).
class GreenSwitch extends StatelessWidget {
  const GreenSwitch({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 62,
          height: 30,
          padding: const EdgeInsets.all(3),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: value ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
                color: value ? AppColors.primary : AppColors.black, width: 1.3),
          ),
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
                color: value ? Colors.white : AppColors.primary,
                shape: BoxShape.circle),
          ),
        ),
      );
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow(this.label, this.value, this.onChanged);
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF8A8A8A)),
            borderRadius: BorderRadius.circular(2)),
        child: Row(children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 15,
                    color: AppColors.black)),
          ),
          GreenSwitch(value: value, onChanged: onChanged),
        ]),
      );
}

/// Single-switch page ("Enable chat" / "Disable feedback").
class SingleToggleScreen extends StatefulWidget {
  const SingleToggleScreen({super.key, required this.chat});
  final bool chat;
  @override
  State<SingleToggleScreen> createState() => _SingleToggleScreenState();
}

class _SingleToggleScreenState extends State<SingleToggleScreen> {
  final _p = currentProfile;
  bool _loading = true;
  bool _failed = false;
  bool _busy = false;

  String get _key => widget.chat ? 'chat_enabled' : 'feedback_enabled';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final prefs = await backend.loadPrefs();
      if (prefs['chat_enabled'] is bool) {
        _p.chatEnabled = prefs['chat_enabled'] as bool;
      }
      if (prefs['feedback_enabled'] is bool) {
        _p.feedbackEnabled = prefs['feedback_enabled'] as bool;
      }
    } catch (_) {
      _failed = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggle(bool v) async {
    if (_busy) return;
    final old = widget.chat ? _p.chatEnabled : _p.feedbackEnabled;
    setState(() {
      _busy = true;
      if (widget.chat) {
        _p.chatEnabled = v;
      } else {
        _p.feedbackEnabled = v;
      }
    });
    try {
      await backend.savePrefs({_key: v});
    } catch (e) {
      if (widget.chat) {
        _p.chatEnabled = old;
      } else {
        _p.feedbackEnabled = old;
      }
      if (mounted) {
        AppToast.show(
            context, e is BackendError ? e.message : 'Could not save.');
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: widget.chat ? 'Enable chat' : 'Disable feedback',
      child: _loading
          ? const Center(
              child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator()))
          : _failed
              ? _RetryBox(onRetry: _load)
              : _ToggleRow(
                  widget.chat ? 'Receive mesages' : 'Receive and show feedback',
                  widget.chat ? _p.chatEnabled : _p.feedbackEnabled,
                  _toggle,
                ),
    );
  }
}

class _RetryBox extends StatelessWidget {
  const _RetryBox({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(children: [
        const Text('Could not load your settings.',
            style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14,
                color: AppColors.black)),
        const SizedBox(height: 12),
        SoftButton(label: 'Retry', onTap: onRetry),
      ]);
}

class ManageNotificationScreen extends StatefulWidget {
  const ManageNotificationScreen({super.key});
  @override
  State<ManageNotificationScreen> createState() =>
      _ManageNotificationScreenState();
}

class _ManageNotificationScreenState extends State<ManageNotificationScreen> {
  final _n = currentProfile.notifications;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final prefs = await backend.loadPrefs();
      for (final k in _n.keys.toList()) {
        if (prefs[k] is bool) _n[k] = prefs[k] as bool;
      }
    } catch (_) {
      _failed = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggle(String k, bool v) async {
    final old = _n[k]!;
    setState(() => _n[k] = v);
    try {
      await backend.savePrefs({k: v});
    } catch (e) {
      _n[k] = old;
      if (mounted) {
        AppToast.show(
            context, e is BackendError ? e.message : 'Could not save.');
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: 'Manage notification',
      child: _loading
          ? const Center(
              child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator()))
          : _failed
              ? _RetryBox(onRetry: _load)
              : Column(children: [
                  for (final k in _n.keys.toList())
                    _ToggleRow(k, _n[k]!, (v) => _toggle(k, v)),
                ]),
    );
  }
}
