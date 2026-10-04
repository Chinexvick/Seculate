// ignore_for_file: curly_braces_in_flow_control_structures
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/back_arrow.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/tappable.dart';
import '../../core/widgets/app_image.dart';
import '../../data/backend.dart';
import '../../data/models.dart';
import 'chat_screen.dart' show ChatArgs;

/// Avatar with the green/grey presence dot used in chat lists.
class PresenceAvatar extends StatelessWidget {
  const PresenceAvatar(
      {super.key, required this.asset, required this.online, this.size = 47});
  final String asset;
  final bool online;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dot = size * 0.32;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: AppImage(asset, width: size, height: size),
          ),
          Positioned(
            right: -size * 0.02,
            bottom: -size * 0.02,
            child: Container(
              width: dot,
              height: dot,
              padding: const EdgeInsets.all(1.6),
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: online ? AppColors.primary : const Color(0xFF7A8699),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AllChatsScreen extends StatefulWidget {
  const AllChatsScreen({super.key});

  @override
  State<AllChatsScreen> createState() => _AllChatsScreenState();
}

class _AllChatsScreenState extends State<AllChatsScreen>
    with WidgetsBindingObserver {
  final _search = TextEditingController();
  List<Conversation> _all = const [];
  bool _loading = true;
  String? _error;
  StreamSubscription<AppNotification>? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _sub = backend.incomingNotifications().listen((n) {
      if (n.kind == NotificationKind.message || n.rawKind.contains('message'))
        _load(silent: true);
    }, onError: (_) {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _load(silent: true);
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _error = null);
    try {
      final c = await backend.conversations();
      if (mounted)
        setState(() {
          _all = c;
          _loading = false;
          _error = null;
        });
    } on BackendError catch (e) {
      if (mounted && !silent)
        setState(() {
          _loading = false;
          _error = e.message;
        });
    }
  }

  Future<void> _open(Conversation c) async {
    await Navigator.of(context).pushNamed(Routes.chat,
        arguments: ChatArgs(c.person, conversationId: c.id, taskId: c.taskId));
    if (mounted) _load(silent: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final list = q.isEmpty
        ? _all
        : _all.where((c) => c.person.name.toLowerCase().contains(q)).toList();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
              child: Column(
                children: [
                  Row(
                    children: const [
                      SizedBox(width: 24, child: BackArrow()),
                      SizedBox(width: 20),
                      Text('All Chats',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w500,
                            fontSize: 22,
                            color: AppColors.black,
                          )),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 47,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.neutral50),
                    ),
                    child: Row(
                      children: [
                        SvgPicture.asset('assets/icons/search.svg',
                            width: 22,
                            height: 22,
                            colorFilter: const ColorFilter.mode(
                                AppColors.neutral200, BlendMode.srcIn)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _search,
                            onChanged: (_) => setState(() {}),
                            cursorColor: AppColors.primary,
                            style: AppText.title1,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              hintText: 'Search',
                              hintStyle: AppText.body,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.neutral40),
            Expanded(child: _content(list)),
          ],
        ),
      ),
    );
  }
}

extension on _AllChatsScreenState {
  Widget _content(List<Conversation> list) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2));
    }
    Widget scrollable(Widget child) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _load,
          child: child,
        );
    if (_error != null && _all.isEmpty) {
      return scrollable(ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(
              child: Text(_error!,
                  textAlign: TextAlign.center, style: AppText.body)),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
                onPressed: _load,
                child: const Text('Retry',
                    style: TextStyle(color: AppColors.primary))),
          ),
        ],
      ));
    }
    if (list.isEmpty) {
      return scrollable(ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(
              child: Text(_all.isEmpty ? 'No chats yet' : 'No chats found',
                  style: AppText.body)),
          if (_all.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 8, 40, 0),
              child: Text(
                  'Messages from lenders and borrowers will show up here.',
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(fontSize: 12)),
            ),
        ],
      ));
    }
    return scrollable(ListView.builder(
      physics:
          const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(28, 10, 28, 24),
      itemCount: list.length,
      itemBuilder: (_, i) => FadeSlideIn(
        delay: Duration(milliseconds: 40 * i),
        offset: 8,
        child: _ChatRow(conversation: list[i], onTap: () => _open(list[i])),
      ),
    ));
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({required this.conversation, required this.onTap});
  final Conversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    return Tappable(
      onTap: onTap,
      scale: 0.985,
      child: SizedBox(
        height: 84,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            PresenceAvatar(asset: c.person.avatar, online: c.online),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(c.person.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                              color: AppColors.black,
                            )),
                      ),
                      Text(c.time, style: AppText.body.copyWith(fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(c.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: c.isRequest
                                ? AppText.body
                                    .copyWith(fontStyle: FontStyle.italic)
                                : AppText.body),
                      ),
                      if (c.unread > 0)
                        Container(
                          width: 15,
                          height: 15,
                          margin: const EdgeInsets.only(left: 12),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                              color: AppColors.alert, shape: BoxShape.circle),
                          child: Text('${c.unread}',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 9,
                                color: Colors.white,
                              )),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
