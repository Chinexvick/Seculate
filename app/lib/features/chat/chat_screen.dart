// ignore_for_file: curly_braces_in_flow_control_structures
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/radio_sheet.dart';
import '../../core/widgets/tappable.dart';
import '../../data/backend.dart';
import '../../data/backend_chat.dart';
import '../../data/models.dart';
import '../transactions/tx_widgets.dart';
import 'all_chats_screen.dart' show PresenceAvatar;

class ChatArgs {
  const ChatArgs(this.person, {this.conversationId, this.product, this.taskId});
  final Person person;

  /// Existing conversation. When null it is started (or reused) on open.
  final String? conversationId;

  /// When set (coming from "Borrow"), a request panel is offered.
  final Product? product;
  final String? taskId;
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.args});
  final ChatArgs args;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  final _picker = ImagePicker();
  final List<ChatMessage> _messages = [];
  final Set<String> _pending = {};
  StreamSubscription<ChatMessage>? _sub;

  String? _convId;
  bool _loading = true;
  String? _error;
  String? _warning;
  bool _tip = false;
  bool _showRequest = true;
  int _seq = 0;
  int _reloadTick = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      var id = widget.args.conversationId ?? _convId;
      id ??= await backend.startConversation(widget.args.person.id,
          listingId: widget.args.product?.id, taskId: widget.args.taskId);
      final history = await backend.messages(id);
      if (!mounted) return;
      _convId = id;
      setState(() {
        _messages
          ..clear()
          ..addAll(history);
        _loading = false;
      });
      _sub?.cancel();
      _sub = backend.incomingMessages(id).listen(_onIncoming, onError: (_) {});
      backend.markRead(id);
      _toBottom(jump: true);
    } on BackendError catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = e.message;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'Could not open the chat.';
        });
    }
  }

  Future<void> _reloadMessages() async {
    final id = _convId;
    if (id == null) return;
    try {
      final history = await backend.messages(id);
      if (!mounted) return;
      setState(() {
        final local = _messages.where((m) => _pending.contains(m.id)).toList();
        _messages
          ..clear()
          ..addAll(history)
          ..addAll(local);
        _reloadTick++;
      });
      _toBottom();
    } catch (_) {}
  }

  void _onIncoming(ChatMessage m) {
    if (!mounted) return;
    if (_messages.any((x) => x.id == m.id)) return;
    setState(() => _messages.add(m));
    _toBottom();
    if (!m.mine && _convId != null) backend.markRead(_convId!);
  }

  void _toBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients || !_scroll.position.hasContentDimensions) return;
      final max = _scroll.position.maxScrollExtent;
      if (jump) {
        _scroll.jumpTo(max);
      } else {
        _scroll.animateTo(max,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  void _showBlocked(SendResult r) {
    setState(() {
      _warning = r.error ?? 'This message could not be sent.';
      _tip = r.blocked || r.flagged;
    });
  }

  Future<void> _send() async {
    final t = _text.text.trim();
    final id = _convId;
    if (t.isEmpty || id == null) return;
    final localId = 'local_${_seq++}';
    setState(() {
      _warning = null;
      _tip = false;
      _pending.add(localId);
      _messages.add(ChatMessage(id: localId, text: t, time: 'Sending…'));
    });
    _text.clear();
    _toBottom();
    final r = await backend.sendMessage(id, t);
    if (!mounted) return;
    setState(() {
      _pending.remove(localId);
      _messages.removeWhere((m) => m.id == localId);
      if (r.ok && !r.blocked) {
        final rid = r.id;
        if (rid != null && !_messages.any((m) => m.id == rid)) {
          _messages.add(
              ChatMessage(id: rid, text: t, time: timeLabel(DateTime.now())));
        }
        if (r.flagged) {
          _warning = r.error;
          _tip = true;
        }
      } else {
        _showBlocked(r);
        _text.text = t;
        _text.selection = TextSelection.collapsed(offset: t.length);
      }
    });
  }

  Future<void> _sendImage(ImageSource source) async {
    final id = _convId;
    if (id == null) return;
    XFile? f;
    try {
      f = await _picker.pickImage(
          source: source, imageQuality: 80, maxWidth: 1600);
    } catch (_) {
      if (mounted) AppToast.show(context, 'Could not open the photo picker.');
      return;
    }
    if (f == null || !mounted) return;
    final localId = 'local_${_seq++}';
    setState(() {
      _warning = null;
      _pending.add(localId);
      _messages.add(ChatMessage(
          id: localId,
          text: '',
          kind: 'image',
          attachmentUrl: f!.path,
          time: 'Sending…'));
    });
    _toBottom();
    final r = await backend.sendImage(id, f.path);
    if (!mounted) return;
    setState(() {
      _pending.remove(localId);
      _messages.removeWhere((m) => m.id == localId);
      if (!r.ok) _showBlocked(r);
    });
    if (r.ok) _reloadMessages();
  }

  void _attachSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: sheetShape,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetRow(Icons.photo_library_outlined, 'Choose from gallery',
                  () {
                Navigator.pop(ctx);
                _sendImage(ImageSource.gallery);
              }),
              _SheetRow(Icons.photo_camera_outlined, 'Take a photo', () {
                Navigator.pop(ctx);
                _sendImage(ImageSource.camera);
              }),
            ],
          ),
        ),
      ),
    );
  }

  static const _reasons = [
    SheetOption('scam', 'Scam or fraud'),
    SheetOption(
        'off_platform', 'Asks for contact details or off-platform payment'),
    SheetOption('abuse', 'Abusive or harassing'),
    SheetOption('other', 'Something else'),
  ];

  Future<String?> _pickReason(String title) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: sheetShape,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SheetHeader(title: title),
              const SizedBox(height: 12),
              for (final o in _reasons)
                _SheetRow(null, o.label, () => Navigator.pop(ctx, o.label)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reportMessage(ChatMessage m) async {
    if (m.mine || _pending.contains(m.id)) return;
    final reason = await _pickReason('Report this message');
    if (reason == null || !mounted) return;
    try {
      await backend.reportMessage(m.id, reason);
      if (mounted)
        AppToast.show(context, 'Thanks, we will review this message.');
    } on BackendError catch (e) {
      if (mounted) AppToast.show(context, e.message);
    }
  }

  Future<void> _reportUser() async {
    final reason = await _pickReason('Report this user');
    if (reason == null || !mounted) return;
    try {
      await backend.reportUser(widget.args.person.id, reason);
      if (mounted)
        AppToast.show(context, 'Thanks, we will review this report.');
    } on BackendError catch (e) {
      if (mounted) AppToast.show(context, e.message);
    }
  }

  Future<void> _blockUser() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Block ${widget.args.person.name}?',
            style:
                const TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 16)),
        content: Text('They will no longer be able to message you.',
            style: AppText.body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Block',
                  style: TextStyle(color: AppColors.alert))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await backend.blockUser(widget.args.person.id);
      if (!mounted) return;
      AppToast.show(context, 'User blocked.');
      Navigator.of(context).maybePop();
    } on BackendError catch (e) {
      if (mounted) AppToast.show(context, e.message);
    }
  }

  void _menu() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: sheetShape,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetRow(Icons.flag_outlined, 'Report user', () {
                Navigator.pop(ctx);
                _reportUser();
              }),
              _SheetRow(Icons.block, 'Block user', () {
                Navigator.pop(ctx);
                _blockUser();
              }, color: AppColors.alert),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final person = widget.args.person;
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 14),
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).maybePop(),
                    child: SvgPicture.asset('assets/icons/arrow_back.svg',
                        width: 24, height: 24),
                  ),
                  const SizedBox(width: 12),
                  PresenceAvatar(asset: person.avatar, online: false),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(person.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          color: AppColors.black,
                        )),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _menu,
                    child: SvgPicture.asset('assets/icons/info.svg',
                        width: 24, height: 24),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.neutral40),
            const _SafetyBanner(),
            if (_warning != null)
              _WarningBanner(
                message: _warning!,
                tip: _tip,
                onClose: () => setState(() => _warning = null),
              ),
            Expanded(child: _body()),
            if (_convId != null) ...[
              if (_showRequest &&
                  widget.args.product != null &&
                  widget.args.product!.ownerId != backend.uid)
                _RequestPanel(
                  product: widget.args.product!,
                  onClose: () => setState(() => _showRequest = false),
                  onSent: () {
                    setState(() => _showRequest = false);
                    _reloadMessages();
                  },
                ),
              _composer(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: AppText.body),
              const SizedBox(height: 16),
              PillButton('Retry', _load, filled: true, width: 120),
            ],
          ),
        ),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
              'No messages yet. Say hello to ${widget.args.person.name}.',
              textAlign: TextAlign.center,
              style: AppText.body),
        ),
      );
    }
    return ListView.builder(
      controller: _scroll,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 12),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final m = _messages[i];
        return Padding(
          key: ValueKey(m.id),
          padding: const EdgeInsets.only(bottom: 12),
          child: _Bubble(
            message: m,
            sending: _pending.contains(m.id),
            reloadTick: _reloadTick,
            onLongPress: () => _reportMessage(m),
            onChanged: _reloadMessages,
          ),
        );
      },
    );
  }

  Widget _composer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 16),
      child: Container(
        height: 52,
        padding: const EdgeInsets.only(left: 22, right: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.neutral50),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _text,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _send(),
                textInputAction: TextInputAction.send,
                cursorColor: AppColors.primary,
                style: AppText.title1,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: 'Message',
                  hintStyle: AppText.body.copyWith(color: AppColors.neutral100),
                ),
              ),
            ),
            if (_text.text.trim().isEmpty) ...[
              Tappable(
                onTap: _attachSheet,
                child: SvgPicture.asset('assets/icons/attach.svg',
                    width: 24, height: 24),
              ),
              const SizedBox(width: 12),
              Tappable(
                onTap: () => _sendImage(ImageSource.camera),
                child: SvgPicture.asset('assets/icons/camera.svg',
                    width: 24, height: 24),
              ),
            ] else
              Tappable(
                onTap: _send,
                scale: 0.85,
                child: const Icon(Icons.send_rounded,
                    color: AppColors.primary, size: 24),
              ),
          ],
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow(this.icon, this.label, this.onTap,
      {this.color = AppColors.black});
  final IconData? icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      scale: 0.985,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 14)
            ],
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 15,
                      color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetyBanner extends StatelessWidget {
  const _SafetyBanner();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFECFCE8),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined,
              size: 16, color: AppColors.primaryDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Keep payments and contact inside Seculate. Never share phone numbers or bank details, and never pay outside the app.',
              style: AppText.body
                  .copyWith(fontSize: 11, color: AppColors.primaryDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner(
      {required this.message, required this.tip, required this.onClose});
  final String message;
  final bool tip;
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFDECEC),
      padding: const EdgeInsets.fromLTRB(28, 8, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.warning_amber_rounded,
                size: 16, color: AppColors.alert),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message,
                    style: AppText.body
                        .copyWith(fontSize: 12, color: AppColors.alert)),
                if (tip)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Safety tip: pay only through Seculate escrow so your money stays protected.',
                      style: AppText.body.copyWith(fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, size: 16, color: AppColors.neutral200),
            ),
          ),
        ],
      ),
    );
  }
}

/// Panel shown when the chat was opened from "Borrow": pick days and send
/// the request. The server creates the request message.
class _RequestPanel extends StatefulWidget {
  const _RequestPanel(
      {required this.product, required this.onClose, required this.onSent});
  final Product product;
  final VoidCallback onClose;
  final VoidCallback onSent;

  @override
  State<_RequestPanel> createState() => _RequestPanelState();
}

class _RequestPanelState extends State<_RequestPanel> {
  int _days = 1;
  bool _busy = false;

  int get _max {
    final d = widget.product.availabilityDays;
    final cap = d > 0 ? d : 30;
    final mx = widget.product.maxDays;
    return (mx != null && mx > 0 && mx < cap) ? mx : cap;
  }

  int get _min => (widget.product.minDays ?? 1).clamp(1, _max);

  @override
  void initState() {
    super.initState();
    _days = _min;
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      await backend.requestBorrow(widget.product.id, _days);
      if (!mounted) return;
      widget.onSent();
    } on BackendError catch (e) {
      if (mounted) {
        AppToast.show(context, e.message);
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Container(
      margin: const EdgeInsets.fromLTRB(28, 4, 28, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AppImage(p.image, width: 52, height: 52, radius: 8),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.title1
                            .copyWith(fontWeight: FontWeight.w500)),
                    Text('Request to borrow',
                        style: AppText.body.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onClose,
                child: const Icon(Icons.close,
                    size: 18, color: AppColors.neutral200),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Days', style: AppText.body),
              const Spacer(),
              _Step(Icons.remove,
                  _days > _min ? () => setState(() => _days--) : null),
              SizedBox(
                  width: 40,
                  child: Text('$_days',
                      textAlign: TextAlign.center, style: AppText.title1)),
              _Step(Icons.add,
                  _days < _max ? () => setState(() => _days++) : null),
              const SizedBox(width: 12),
              PillButton('Send request', _busy ? null : _send,
                  filled: true, busy: _busy),
            ],
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.icon, this.onTap);
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color:
                    onTap == null ? AppColors.neutral40 : AppColors.primary)),
        child: Icon(icon,
            size: 16,
            color: onTap == null ? AppColors.neutral50 : AppColors.primary),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.sending,
    required this.reloadTick,
    required this.onLongPress,
    required this.onChanged,
  });
  final ChatMessage message;
  final bool sending;
  final int reloadTick;
  final VoidCallback onLongPress;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final m = message;
    final align = m.mine ? Alignment.centerRight : Alignment.centerLeft;
    final Widget content;
    switch (m.kind) {
      case 'system':
        content = Center(
          child: Text(m.text,
              textAlign: TextAlign.center,
              style: AppText.body
                  .copyWith(fontSize: 12, fontStyle: FontStyle.italic)),
        );
        break;
      case 'borrow_request':
        content = m.refId == null
            ? _TextBubble(m, sending: sending)
            : _BorrowCard(m, key: ValueKey('b${m.id}'));
        break;
      case 'offer':
        content = m.refId == null
            ? _TextBubble(m, sending: sending)
            : _OfferCard(m, onChanged: onChanged, key: ValueKey('o${m.id}'));
        break;
      case 'image':
        content = _ImageBubble(m, sending: sending);
        break;
      default:
        content = _TextBubble(m, sending: sending);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child:
            Transform.translate(offset: Offset(0, (1 - t) * 10), child: child),
      ),
      child: Align(
        alignment: m.kind == 'system' ? Alignment.center : align,
        child: GestureDetector(
          onLongPress: m.mine || m.kind == 'system' ? null : onLongPress,
          child: content,
        ),
      ),
    );
  }
}

class _TextBubble extends StatelessWidget {
  const _TextBubble(this.m, {this.sending = false});
  final ChatMessage m;
  final bool sending;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: sending ? 0.6 : 1,
      child: Column(
        crossAxisAlignment:
            m.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 260),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: m.mine ? const Color(0xFFF5F6F7) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: m.mine ? null : Border.all(color: AppColors.neutral40),
            ),
            child: Text(m.text,
                style: AppText.body.copyWith(color: const Color(0xFF505F79))),
          ),
          if (sending)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child:
                  Text('Sending…', style: AppText.body.copyWith(fontSize: 10)),
            ),
        ],
      ),
    );
  }
}

class _ImageBubble extends StatefulWidget {
  const _ImageBubble(this.m, {required this.sending});
  final ChatMessage m;
  final bool sending;

  @override
  State<_ImageBubble> createState() => _ImageBubbleState();
}

class _ImageBubbleState extends State<_ImageBubble> {
  Future<String?>? _url;

  bool get _local => widget.sending || widget.m.id.startsWith('local_');

  @override
  void initState() {
    super.initState();
    final p = widget.m.attachmentUrl;
    if (!_local && p != null && p.isNotEmpty) _url = backend.chatImageUrl(p);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.m.attachmentUrl ?? '';
    Widget img;
    if (_local) {
      img = Image.file(File(p),
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const SizedBox(width: 200, height: 200));
    } else {
      img = FutureBuilder<String?>(
        future: _url,
        builder: (_, s) =>
            AppImage(s.data, width: 200, height: 200, radius: 12),
      );
    }
    return Opacity(
      opacity: widget.sending ? 0.6 : 1,
      child: ClipRRect(borderRadius: BorderRadius.circular(12), child: img),
    );
  }
}

/// Borrow request card; always reflects the server state of the transaction.
class _BorrowCard extends StatefulWidget {
  const _BorrowCard(this.m, {super.key});
  final ChatMessage m;

  @override
  State<_BorrowCard> createState() => _BorrowCardState();
}

class _BorrowCardState extends State<_BorrowCard> with WidgetsBindingObserver {
  Txn? _tx;
  Product? _listing;
  String? _error;
  bool _busy = false;
  bool _awaiting = false;
  StreamSubscription<Txn>? _sub;

  String get _id => widget.m.refId!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _sub = backend.watchTransaction(_id).listen(_set, onError: (_) {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed && _awaiting) _load();
  }

  void _set(Txn t) {
    if (!mounted) return;
    setState(() {
      _tx = t;
      if (t.state == 'escrow_held' ||
          t.state == 'active' ||
          t.state == 'cancelled') _awaiting = false;
    });
  }

  Future<void> _load() async {
    try {
      final t = await backend.transaction(_id);
      if (!mounted) return;
      _set(t);
      if (_listing == null && t.listingId != null) {
        try {
          final l = await backend.listing(t.listingId!);
          if (mounted) setState(() => _listing = l);
        } catch (_) {}
      }
    } on BackendError catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _do(Future<void> Function() f) async {
    setState(() => _busy = true);
    try {
      await f();
      await _load();
    } on BackendError catch (e) {
      if (mounted) AppToast.show(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pay() async {
    setState(() => _busy = true);
    final ok = await payForTransaction(context, _id);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _awaiting = true;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _tx;
    final mine = widget.m.mine;
    return Container(
      width: 232,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment:
            mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          AppImage(_listing?.image, width: 175, height: 133, radius: 16),
          const SizedBox(height: 10),
          if (t != null && t.title.isNotEmpty)
            Text(t.title,
                textAlign: mine ? TextAlign.right : TextAlign.left,
                style: AppText.title1.copyWith(fontWeight: FontWeight.w500)),
          Text(
              widget.m.text.isEmpty
                  ? 'I would like to request the borrowing of this item.'
                  : widget.m.text,
              textAlign: mine ? TextAlign.right : TextAlign.left,
              style: AppText.body.copyWith(color: const Color(0xFF505F79))),
          if (t != null) ...[
            const SizedBox(height: 8),
            Text(
                '${t.rentalDays > 0 ? '${t.rentalDays} day${t.rentalDays == 1 ? '' : 's'} · ' : ''}${naira(t.amount)}',
                style: AppText.body.copyWith(fontSize: 12)),
            Text(t.stateLabel,
                style: AppText.body.copyWith(
                    fontSize: 12,
                    color: t.state == 'cancelled'
                        ? AppColors.alert
                        : AppColors.primaryDark,
                    fontWeight: FontWeight.w500)),
          ],
          const SizedBox(height: 10),
          if (_error != null)
            GestureDetector(
              onTap: () {
                setState(() => _error = null);
                _load();
              },
              child: Text('$_error Tap to retry.',
                  style: AppText.body
                      .copyWith(fontSize: 12, color: AppColors.alert)),
            )
          else if (t == null)
            const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary))
          else
            ..._actions(t),
        ],
      ),
    );
  }

  List<Widget> _actions(Txn t) {
    final out = <Widget>[];
    final payer = isPayer(t);
    final payee = isPayee(t);
    final cross = payer ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    void add(Widget w) {
      out.add(Align(
          alignment:
              widget.m.mine ? Alignment.centerRight : Alignment.centerLeft,
          child: w));
      out.add(const SizedBox(height: 8));
    }

    switch (t.state) {
      case 'requested':
        if (payee) {
          add(PillButton('Accept Request',
              () => _do(() => backend.respondRequest(_id, true)),
              filled: true,
              color: const Color(0xFF66DD84),
              busy: _busy,
              width: 140));
          add(PillButton(
              'Decline', () => _do(() => backend.respondRequest(_id, false)),
              busy: _busy, width: 140));
        } else if (payer) {
          add(PillButton(
              'Cancel Request', () => _do(() => backend.cancelTransaction(_id)),
              busy: _busy, width: 140));
        }
        break;
      case 'accepted':
      case 'payment_pending':
        if (_awaiting) {
          add(Row(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary)),
            const SizedBox(width: 8),
            Text('Waiting for payment confirmation',
                style: AppText.body.copyWith(fontSize: 12)),
          ]));
          add(PillButton('Pay again', _pay, busy: _busy, width: 140));
        } else if (payer) {
          add(PillButton('Pay securely', _pay,
              filled: true, busy: _busy, width: 140));
          add(PillButton(
              'Cancel Request', () => _do(() => backend.cancelTransaction(_id)),
              busy: _busy, width: 140));
        } else {
          add(Text('Waiting for the borrower to pay into escrow.',
              style: AppText.body.copyWith(fontSize: 12)));
        }
        break;
      default:
        break;
    }
    out.add(Align(
      alignment: widget.m.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => Navigator.of(context)
            .pushNamed(Routes.transaction, arguments: t.id),
        child: Text('View details',
            style: AppText.body.copyWith(
                fontSize: 12,
                color: AppColors.primary,
                decoration: TextDecoration.underline)),
      ),
    ));
    return [Column(crossAxisAlignment: cross, children: out)];
  }
}

/// Counter-offer bubble with Accept / Counter / Reject for the recipient.
class _OfferCard extends StatefulWidget {
  const _OfferCard(this.m, {required this.onChanged, super.key});
  final ChatMessage m;
  final VoidCallback onChanged;

  @override
  State<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<_OfferCard> {
  Offer? _offer;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final o = await backend.offer(widget.m.refId!);
      if (mounted)
        setState(() {
          _offer = o;
          _error = null;
        });
    } on BackendError catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _respond(String action, {int? counter}) async {
    setState(() => _busy = true);
    try {
      await backend.respondOffer(widget.m.refId!, action, counter: counter);
      await _load();
      widget.onChanged();
    } on BackendError catch (e) {
      if (mounted) AppToast.show(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _counter() async {
    final ctrl = TextEditingController();
    final v = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      shape: sheetShape,
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            28, 20, 28, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHeader(title: 'Your counter offer'),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: AppText.title1,
              decoration: InputDecoration(
                prefixText: '₦ ',
                hintText: 'Amount',
                hintStyle: AppText.body,
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: AppColors.neutral50)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: PillButton('Send counter offer', () {
                final n = int.tryParse(ctrl.text.replaceAll(',', '').trim());
                if (n == null || n <= 0) return;
                Navigator.pop(ctx, n);
              }, filled: true, width: 220),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
    if (v != null && mounted) _respond('counter', counter: v);
  }

  @override
  Widget build(BuildContext context) {
    final o = _offer;
    final mine = widget.m.mine;
    return Container(
      width: 232,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(mine ? 'Your offer' : 'Offer received',
              style: AppText.body.copyWith(fontSize: 12)),
          if (o == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _error != null
                  ? GestureDetector(
                      onTap: _load,
                      child: Text('$_error Tap to retry.',
                          style: AppText.body
                              .copyWith(fontSize: 12, color: AppColors.alert)))
                  : const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary)),
            )
          else ...[
            Text(naira(o.amount),
                style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                    color: AppColors.black)),
            if ((o.note ?? '').isNotEmpty)
              Text(o.note!,
                  style: AppText.body.copyWith(color: const Color(0xFF505F79))),
            const SizedBox(height: 8),
            if (o.status == 'pending' && o.toUser == backend.uid) ...[
              PillButton('Accept', () => _respond('accept'),
                  filled: true,
                  color: const Color(0xFF66DD84),
                  busy: _busy,
                  width: 140),
              const SizedBox(height: 8),
              PillButton('Counter', _counter, busy: _busy, width: 140),
              const SizedBox(height: 8),
              PillButton('Reject', () => _respond('reject'),
                  color: AppColors.alert, busy: _busy, width: 140),
            ] else
              Text(_statusLabel(o.status),
                  style: AppText.body.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: o.status == 'accepted'
                          ? AppColors.primaryDark
                          : o.status == 'pending'
                              ? AppColors.neutral200
                              : AppColors.alert)),
          ],
        ],
      ),
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'accepted':
        return 'Offer accepted';
      case 'rejected':
        return 'Offer rejected';
      case 'countered':
        return 'Countered';
      case 'expired':
        return 'Offer expired';
      default:
        return 'Waiting for a response';
    }
  }
}
