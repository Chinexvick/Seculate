import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/back_arrow.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../data/auth_service.dart';
import 'auth_success_screen.dart';
import 'forgot_password_screen.dart' show VerifyCodeArgs;

class VerifyCodeScreen extends StatefulWidget {
  const VerifyCodeScreen({super.key, required this.args});
  final VerifyCodeArgs args;

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen>
    with WidgetsBindingObserver {
  static const _resendSeconds = 30;
  static const _len = 6;
  final _code = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  int _left = _resendSeconds;
  bool _loading = false;
  bool _wrong = false;
  String? _devCode;
  String? _clipCode;

  OtpPurpose get _purpose =>
      widget.args.reset ? OtpPurpose.recovery : OtpPurpose.signup;

  bool get _full => _code.text.length == _len;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _devCode = widget.args.devCode;
    _startTimer();
    _checkClipboard();
    _focus.addListener(() => setState(() {}));
    WidgetsBinding.instance
        .addPostFrameCallback((_) => mounted ? _focus.requestFocus() : null);
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _left = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_left <= 1) {
        t.cancel();
      }
      if (mounted) setState(() => _left = _left - 1);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkClipboard();
  }

  /// When the user copies the code from their email and comes back, offer
  /// it right away (Android shows its own paste prompt for keyboards too).
  Future<void> _checkClipboard() async {
    try {
      final d = await Clipboard.getData(Clipboard.kTextPlain);
      final t = _extractCode(d?.text);
      if (t != null && mounted) setState(() => _clipCode = t);
    } catch (_) {}
  }

  /// Finds a 6-digit code in copied text (tolerates spaces and extra words).
  static String? _extractCode(String? raw) {
    final t = (raw ?? '').replaceAll(RegExp(r'[\s-]'), '');
    final m = RegExp(r'(?<!\d)\d{6}(?!\d)').firstMatch(t);
    return m?.group(0);
  }

  Future<void> _pasteTapped() async {
    String? c;
    try {
      c = _extractCode((await Clipboard.getData(Clipboard.kTextPlain))?.text);
    } catch (_) {}
    if (!mounted) return;
    if (c == null) {
      AppToast.show(context, 'Copy the 6-digit code from your email first.');
      return;
    }
    _useCode(c);
  }

  void _useCode(String c) {
    _code.text = c;
    setState(() {
      _wrong = false;
      _clipCode = null;
    });
    _confirm();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_loading || !_full) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await AuthService.instance
          .verifyOtp(widget.args.email, _code.text, _purpose);
      if (!mounted) return;
      setState(() => _loading = false);
      if (widget.args.reset) {
        Navigator.of(context)
            .pushNamed(Routes.createPassword, arguments: widget.args);
      } else {
        Navigator.of(context).pushNamed(Routes.authSuccess,
            arguments: AuthSuccessArgs.emailVerified(widget.args));
      }
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _wrong = true;
      });
      _code.clear();
      AppToast.show(context, e.message);
      _focus.requestFocus();
    }
  }

  String get _timeText => '00:${_left.clamp(0, 99).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
          child: FadeSlideIn(
            child: Column(
              children: [
                const BackArrow(),
                const SizedBox(height: 12),
                const Text('Verify Email', style: AppText.h5),
                const SizedBox(height: 8),
                Text(
                  'Enter the 6-digit code we sent to\n${widget.args.email}',
                  textAlign: TextAlign.center,
                  style: AppText.body,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: 300,
                  height: 52,
                  child: Stack(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var i = 0; i < _len; i++) _box(i),
                        ],
                      ),
                      // Invisible field captures taps and typing.
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0,
                          child: TextField(
                            controller: _code,
                            focusNode: _focus,
                            keyboardType: TextInputType.number,
                            maxLength: _len,
                            showCursor: false,
                            enableInteractiveSelection: false,
                            autofillHints: const [AutofillHints.oneTimeCode],
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            onChanged: (v) {
                              setState(() => _wrong = false);
                              if (v.length == _len) _confirm();
                            },
                            decoration: const InputDecoration(
                                counterText: '', border: InputBorder.none),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_wrong)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                        'That code didn’t work. Check it and try again.',
                        style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12,
                            color: AppColors.alert)),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: GestureDetector(
                    key: const Key('paste-code'),
                    onTap: _pasteTapped,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                          color: const Color(0xFFEAF9EE),
                          borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.content_paste_rounded,
                            size: 16, color: AppColors.primaryDark),
                        const SizedBox(width: 8),
                        Text(
                            _clipCode != null
                                ? 'Paste code  $_clipCode'
                                : 'Paste code',
                            style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primaryDark)),
                      ]),
                    ),
                  ),
                ),
                if (_devCode != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: GestureDetector(
                      onTap: () => _useCode(_devCode!),
                      child: Text(
                          'Test mode: email isn’t set up yet. Tap to use code $_devCode',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 11,
                              color: AppColors.neutral200)),
                    ),
                  ),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Confirm',
                  onPressed: _confirm,
                  inactive: !_full,
                  loading: _loading,
                  disabledColor: AppColors.disabledFill,
                  disabledTextColor: AppColors.disabledText,
                ),
                const SizedBox(height: 32),
                _resend(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _box(int i) {
    final text = _code.text;
    final filled = i < text.length;
    final active = _focus.hasFocus && i == text.length.clamp(0, _len - 1);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 42,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active ? AppColors.primary : AppColors.neutral50,
        ),
      ),
      child: Text(
        filled ? text[i] : '',
        style: const TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 24,
          color: AppColors.black,
        ),
      ),
    );
  }

  Widget _resend() {
    final ready = _left <= 0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: ready
          ? () async {
              _code.clear();
              try {
                final r = await AuthService.instance
                    .sendOtp(widget.args.email, _purpose);
                if (!mounted) return;
                setState(() => _devCode = r.devCode);
                AppToast.show(context, 'New code sent');
                _startTimer();
              } on AuthFailure catch (e) {
                if (mounted) AppToast.show(context, e.message);
              }
            }
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Resend code',
              style: AppText.body.copyWith(
                color: ready ? AppColors.primaryDark : AppColors.neutral200,
                decoration: ready ? TextDecoration.underline : null,
              )),
          if (!ready) ...[
            const SizedBox(width: 10),
            Text(_timeText,
                style: AppText.body.copyWith(color: AppColors.primary)),
          ],
        ],
      ),
    );
  }
}
