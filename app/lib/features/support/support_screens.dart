import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/widgets/social_links.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_arrow.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../data/auth_service.dart';
import '../../data/backend.dart';
import '../../data/models.dart';
import '../../data/user_profile.dart';
import '../settings/settings_widgets.dart' show BoxField, SettingsScaffold;

const _cardBg = Color(0xFFF7F7F7);

/// "Support": hello banner, your tickets, contact channels and social links.
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  List<SupportTicket>? _tickets;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final t = await backend.tickets();
      if (mounted) setState(() => _tickets = t);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _openChat([String? ticketId]) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
        settings: const RouteSettings(name: Routes.supportChat),
        builder: (_) => SupportChatScreen(ticketId: ticketId)));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    void soon(String what) =>
        AppToast.show(context, '$what will open once connected');
    final first = currentProfile.firstName;
    final tickets = _tickets;
    return SettingsScaffold(
      title: 'Support',
      support: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: FadeSlideIn(
              child: Column(children: [
                SvgPicture.asset('assets/icons/support_logo.svg',
                    width: 80, height: 80),
                const SizedBox(height: 14),
                Text(
                    first.isEmpty
                        ? 'Hello , How can we\nHelp you?'
                        : 'Hello $first, How can we\nHelp you?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        height: 1.5,
                        color: AppColors.black)),
              ]),
            ),
          ),
          const SizedBox(height: 28),
          const Text('Available every 8am-9pm',
              style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  color: AppColors.neutral200)),
          const SizedBox(height: 10),
          _Channel('support_chat', 'Chat', 'Start a conversation with our team',
              () => _openChat()),
          if (_failed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: _load,
                child: const Text('Could not load your tickets. Tap to retry.',
                    style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        color: AppColors.alert)),
              ),
            ),
          if (tickets != null && tickets.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Your tickets',
                style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    color: AppColors.neutral200)),
            const SizedBox(height: 10),
            for (final t in tickets)
              _Channel(
                  'support_chat',
                  t.subject,
                  '${t.status} · ${timeLabel(t.createdAt)}',
                  () => _openChat(t.id)),
            const SizedBox(height: 12),
          ],
          _Channel('support_whatsapp', 'Whatsapp', 'Lets talk on whatsapp',
              () => soon('WhatsApp')),
          _Channel('support_mail', 'Email', 'saculate.ng@gmail.com',
              () => soon('Your email app')),
          _Channel('support_call', 'Call', '+234 908-342-5649',
              () => soon('The dialer')),
          const SizedBox(height: 22),
          const Text('Stay Connected',
              style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  color: AppColors.neutral200)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(2, 6, 2, 12),
            decoration: BoxDecoration(
                color: _cardBg, borderRadius: BorderRadius.circular(4)),
            child: Column(children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 12),
                child: Text(
                    'Reach out to Seculate Support on any of our social media channels',
                    style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.black)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (final i in ['instagram', 'x', 'facebook'])
                    GestureDetector(
                      onTap: () => openSocial(
                          context,
                          socialLinks
                              .firstWhere((l) => l.$1.toLowerCase() == i,
                                  orElse: () => socialLinks.first)
                              .$2),
                      child: SvgPicture.asset('assets/icons/support_$i.svg',
                          width: 24, height: 24),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const SocialLinks(title: null),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Channel extends StatelessWidget {
  const _Channel(this.icon, this.title, this.sub, this.onTap);
  final String icon;
  final String title;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
                color: _cardBg, borderRadius: BorderRadius.circular(4)),
            child: Row(children: [
              SizedBox(
                  width: 30,
                  child: SvgPicture.asset('assets/icons/$icon.svg',
                      width: 26, height: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13,
                            color: AppColors.black)),
                    Text(sub,
                        style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12,
                            color: AppColors.neutral200)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.neutral200),
            ]),
          ),
        ),
      );
}

/// Support chat: a ticket thread with our team (polls every 8 seconds).
class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key, this.ticketId});
  final String? ticketId;
  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  List<ChatMessage> _msgs = [];
  String? _ticket;
  Timer? _poll;
  bool _loading = false;
  bool _failed = false;
  bool _sending = false;

  static const _chips = [
    'General enquiries',
    'Report an issue',
    'How do i start?',
    'Account services',
    'How to get funded?',
  ];

  String get _name => currentProfile.displayName.toUpperCase();

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticketId;
    if (_ticket != null) {
      _load(first: true);
      _poll = Timer.periodic(const Duration(seconds: 8), (_) => _load());
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut);
        }
      });

  Future<void> _load({bool first = false}) async {
    final id = _ticket;
    if (id == null) return;
    if (first) setState(() => _loading = true);
    try {
      final m = await backend.ticketMessages(id);
      if (!mounted) return;
      final grew = m.length != _msgs.length;
      setState(() {
        _msgs = m;
        _loading = false;
        _failed = false;
      });
      if (grew) _toBottom();
    } catch (_) {
      if (!mounted) return;
      if (first) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  Future<void> _send(String t) async {
    t = t.trim();
    if (t.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      if (_ticket == null) {
        final subject = t.length > 60 ? '${t.substring(0, 60)}...' : t;
        _ticket = await backend.createTicket(subject, t);
        _poll = Timer.periodic(const Duration(seconds: 8), (_) => _load());
      } else {
        await backend.replyTicket(_ticket!, t);
      }
      _text.clear();
      await _load();
    } on BackendError catch (e) {
      if (mounted) AppToast.show(context, e.message);
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 20, 8),
              child: Row(children: const [
                SizedBox(width: 32, child: BackArrow()),
                SizedBox(width: 10),
                Text('Support chat',
                    style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14,
                        color: AppColors.black)),
              ]),
            ),
            Expanded(
              child: ListView(
                controller: _scroll,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                children: [
                  _Bubble(
                    bot: true,
                    child: Text(
                        'Hello $_name, thank you for contacting Seculate.\n\nDescribe your question or issue below and our support team will reply here. Tap a shortcut to get started.',
                        style: _bubbleStyle),
                  ),
                  if (_loading)
                    const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(child: CircularProgressIndicator())),
                  if (_failed)
                    GestureDetector(
                      onTap: () => _load(first: true),
                      child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(
                              child: Text(
                                  'Could not load messages. Tap to retry.',
                                  style: TextStyle(color: AppColors.alert)))),
                    ),
                  for (final m in _msgs)
                    _Bubble(
                        bot: !m.mine, child: Text(m.text, style: _bubbleStyle)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in _chips)
                    GestureDetector(
                      onTap: () => setState(() => _text.text = c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4000),
                            border: Border.all(color: AppColors.primary)),
                        child: Text(c,
                            style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 10,
                                color: AppColors.black)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 4, 28, 16),
              child: Container(
                height: 52,
                padding: const EdgeInsets.only(left: 22, right: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.neutral50),
                ),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _text,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: _send,
                      textInputAction: TextInputAction.send,
                      cursorColor: AppColors.primary,
                      style: AppText.title1,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: 'Message',
                        hintStyle:
                            AppText.body.copyWith(color: AppColors.neutral100),
                      ),
                    ),
                  ),
                  if (_text.text.trim().isEmpty) ...[
                    SvgPicture.asset('assets/icons/attach.svg',
                        width: 24, height: 24),
                    const SizedBox(width: 12),
                    SvgPicture.asset('assets/icons/camera.svg',
                        width: 24, height: 24),
                  ] else
                    GestureDetector(
                      onTap: () => _send(_text.text),
                      child: const Icon(Icons.send_rounded,
                          color: AppColors.primary, size: 24),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _bubbleStyle = TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 14,
    height: 1.5,
    color: Color(0xFF444444));

class _Bubble extends StatelessWidget {
  const _Bubble({required this.bot, required this.child});
  final bool bot;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      constraints: const BoxConstraints(maxWidth: 250),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bot ? const Color(0xFFF4F5F7) : const Color(0xFFE6E6E6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: bot
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                      color: Color(0xFFE9E9E9), shape: BoxShape.circle),
                  child: const Icon(Icons.person,
                      color: Color(0xFF1B9A2F), size: 22),
                ),
                const SizedBox(width: 6),
                box,
              ],
            )
          : Align(alignment: Alignment.centerRight, child: box),
    );
  }
}

/// Settings → Delete my account permanently.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});
  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  String? _reason;
  final _pw = TextEditingController();
  bool _busy = false;
  static const _reasons = [
    'Found a better platform',
    'Privacy concerns',
    'Too many notifications',
    'I am not using the app',
    'Other',
  ];

  @override
  void dispose() {
    _pw.dispose();
    super.dispose();
  }

  bool get _ready => _reason != null && _pw.text.isNotEmpty;

  Future<void> _delete() async {
    if (_busy) return;
    if (_reason == null) {
      AppToast.show(context, 'Please tell us why you are leaving');
      return;
    }
    if (_pw.text.isEmpty) {
      AppToast.show(context, 'Enter your password to confirm');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete account?',
            style: TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 17)),
        content: const Text(
            'Your account will be deactivated and you will be logged out. Some records (such as transactions) are kept as required by law and our policy. This cannot be undone from the app.',
            style: AppText.body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.black))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.alert))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final nav = Navigator.of(context);
    try {
      await AuthService.instance.signIn(currentProfile.email, _pw.text);
      await backend.requestAccountDeletion(reason: _reason);
      await backend.signOut();
      nav.pushNamedAndRemoveUntil(Routes.onboarding, (_) => false);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppToast.show(context, e.message);
    } on BackendError catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppToast.show(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: 'Delete my account permanently',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(
            'Deleting your account deactivates it and logs you out. Records such as transactions and reports are kept as required by law and our policy. This cannot be undone from the app.',
            style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF666666))),
        const SizedBox(height: 18),
        _Reason(
          value: _reason,
          options: _reasons,
          onChanged: (v) => setState(() => _reason = v),
        ),
        const SizedBox(height: 14),
        BoxField(
            controller: _pw,
            hint: 'Enter your password to confirm',
            obscure: true,
            onChanged: (_) => setState(() {})),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _delete,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: _ready ? AppColors.alert : const Color(0xFFD0D0D0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_busy ? '...' : 'Delete my account permanently',
                style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    color: _ready ? Colors.white : AppColors.black)),
          ),
        ),
      ]),
    );
  }
}

class _Reason extends StatelessWidget {
  const _Reason(
      {required this.value, required this.options, required this.onChanged});
  final String? value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      color: Colors.white,
      position: PopupMenuPosition.under,
      itemBuilder: (_) => [
        for (final o in options) PopupMenuItem(value: o, child: Text(o)),
      ],
      child: Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF8A8A8A)),
            borderRadius: BorderRadius.circular(4)),
        child: Row(children: [
          Expanded(
            child: Text(value ?? 'Why do you leave',
                style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: value == null ? 16 : 15,
                    color: value == null
                        ? const Color(0xFF9A9A9A)
                        : AppColors.black)),
          ),
          const Icon(Icons.arrow_drop_down, color: Color(0xFFD4D4D4), size: 28),
        ]),
      ),
    );
  }
}
