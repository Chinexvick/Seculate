import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/back_arrow.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../data/auth_service.dart';
import '../../data/profile_service.dart';

/// Formats digits as "706 619 9167".
class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var d = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (d.length > 10) d = d.substring(0, 10);
    final b = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 3 || i == 6) b.write(' ');
      b.write(d[i]);
    }
    final t = b.toString();
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _phone = TextEditingController();
  bool _loading = false;

  bool get _valid =>
      _first.text.trim().isNotEmpty &&
      _last.text.trim().isNotEmpty &&
      _phone.text.replaceAll(' ', '').length == 10;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_loading || !_valid) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await ProfileService.instance.saveDetails(
          first: _first.text,
          last: _last.text,
          phone10: _phone.text.replaceAll(' ', ''));
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.of(context).pushNamed(Routes.locationGate);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppToast.show(
          context,
          e is AuthFailure
              ? e.message
              : 'Could not save your details. Check your connection.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(27, 16, 28, 24),
          child: FadeSlideIn(
            child: Column(
              children: [
                const BackArrow(),
                const SizedBox(height: 12),
                const Text('Personal Details', style: AppText.h5),
                const SizedBox(height: 8),
                const SizedBox(
                  width: 301,
                  child: Text(
                    'We’d love to know you better! Drop your name and number to stay connected.',
                    textAlign: TextAlign.center,
                    style: AppText.body,
                  ),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'First name',
                  controller: _first,
                  showClear: false,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Last name',
                  controller: _last,
                  showClear: false,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Phone number',
                  controller: _phone,
                  showClear: false,
                  hint: '000 000 0000',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [_PhoneFormatter()],
                  leadingWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      _NigeriaFlag(),
                      SizedBox(width: 8),
                      Text('+234', style: AppText.title1),
                    ],
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _next(),
                ),
                const SizedBox(height: 28),
                AppButton(
                  label: 'Next',
                  onPressed: _next,
                  inactive: !_valid,
                  loading: _loading,
                  disabledColor: AppColors.disabledFill,
                  disabledTextColor: AppColors.disabledText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NigeriaFlag extends StatelessWidget {
  const _NigeriaFlag();

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF008751);
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        width: 24,
        height: 18,
        child: Row(
          children: const [
            Expanded(child: ColoredBox(color: green, child: SizedBox.expand())),
            Expanded(
                child:
                    ColoredBox(color: Colors.white, child: SizedBox.expand())),
            Expanded(child: ColoredBox(color: green, child: SizedBox.expand())),
          ],
        ),
      ),
    );
  }
}
