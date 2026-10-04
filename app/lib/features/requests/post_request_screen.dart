import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/backend.dart';
import '../../data/backend_credits.dart';
import '../../data/user_profile.dart';
import 'req_widgets.dart';

/// Post a request: "I need to borrow ...". Goes to review before nearby
/// lenders see it, and costs credits (returned if it is not approved).
class PostRequestScreen extends StatefulWidget {
  /// Pass [editing] (a request_detail map) to change an existing request.
  const PostRequestScreen({super.key, this.editing});
  final Map<String, dynamic>? editing;

  @override
  State<PostRequestScreen> createState() => _PostRequestScreenState();
}

class _PostRequestScreenState extends State<PostRequestScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _budget = TextEditingController();
  final _days = TextEditingController(text: '1');
  DateTime _from = DateTime.now();
  double _radius = 10;
  bool _busy = false;
  int? _balance;
  int _cost = 1;

  bool get _edit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _title.text = '${e['title'] ?? ''}';
      _desc.text = '${e['description'] ?? ''}';
      final b = (e['budget_ngn'] as num?) ?? 0;
      _budget.text = b > 0 ? '${b.toInt()}' : '';
      _days.text = '${e['duration_days'] ?? 1}';
      _radius = ((e['radius_km'] as num?) ?? 10).toDouble().clamp(1, 50);
      final nf = DateTime.tryParse('${e['needed_from']}');
      if (nf != null && !nf.isBefore(DateTime.now())) _from = nf;
    }
    backend.myCredits().then((d) {
      if (!mounted) return;
      setState(() {
        _balance = (d['balance'] as num?)?.toInt();
        _cost = (d['request_cost'] as num?)?.toInt() ?? 1;
      });
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _budget.dispose();
    _days.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (d != null) setState(() => _from = d);
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    final days = int.tryParse(_days.text.trim()) ?? 0;
    if (title.length < 3) {
      AppToast.show(context, 'Say what you need to borrow');
      return;
    }
    if (days < 1) {
      AppToast.show(context, 'Enter how many days you need it');
      return;
    }
    if (!_edit && _balance != null && _balance! < _cost) {
      AppToast.show(
          context, 'You need $_cost credit to post. Buy credits first.');
      return;
    }
    setState(() => _busy = true);
    try {
      if (_edit) {
        await backend.updateRequest('${widget.editing!['id']}',
            title: title,
            description: _desc.text.trim(),
            budget: num.tryParse(_budget.text.trim()) ?? 0,
            days: days,
            from: _from,
            radiusKm: _radius);
        if (mounted) {
          AppToast.show(context, 'Saved. Sent back for review.');
          Navigator.of(context).pop(true);
        }
        return;
      }
      final p = currentProfile;
      await backend.createRequest(
        title: title,
        description: _desc.text.trim(),
        budget: num.tryParse(_budget.text.trim()) ?? 0,
        days: days,
        from: _from,
        radiusKm: _radius,
        lat: p.lat,
        lng: p.lng,
        area: p.city,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on BackendError catch (e) {
      if (mounted) AppToast.show(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          ReqHeader(_edit ? 'Edit request' : 'Post a request'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
              children: [
                ReqField(
                    label: 'What do you need?',
                    controller: _title,
                    hint: 'e.g. Extension ladder',
                    maxLength: 120),
                ReqField(
                    label: 'Details',
                    controller: _desc,
                    hint:
                        'Size, condition, anything the lender should know. No phone numbers or links.',
                    maxLines: 4,
                    maxLength: 1500),
                Row(children: [
                  Expanded(
                    child: ReqField(
                        label: 'Budget (optional)',
                        controller: _budget,
                        prefix: '₦ ',
                        keyboard: TextInputType.number,
                        digitsOnly: true),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ReqField(
                        label: 'Days needed',
                        controller: _days,
                        keyboard: TextInputType.number,
                        digitsOnly: true,
                        maxLength: 3),
                  ),
                ]),
                Text('Needed from',
                    style: AppText.body
                        .copyWith(color: AppColors.black, fontSize: 13)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF5F6F7),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('${_from.day}/${_from.month}/${_from.year}',
                        style: AppText.title1),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Search radius: ${_radius.round()} km',
                    style: AppText.body
                        .copyWith(color: AppColors.black, fontSize: 13)),
                Slider(
                  value: _radius,
                  min: 1,
                  max: 50,
                  divisions: 49,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _radius = v),
                ),
                Text(
                    'Only lenders within this distance of ${currentProfile.city.isNotEmpty ? currentProfile.city : 'your saved location'} will see your request. It stays open for 7 days after approval.',
                    style: AppText.body.copyWith(fontSize: 12)),
                const SizedBox(height: 14),
                if (!_edit)
                  Text(
                      'Posting costs $_cost ${_cost == 1 ? 'credit' : 'credits'}'
                      '${_balance != null ? ' (you have $_balance)' : ''}. It is returned if the request is not approved.',
                      style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12,
                          color: AppColors.primaryDark)),
                const SizedBox(height: 20),
                AppButton(
                    label: _edit ? 'Save and resubmit' : 'Send for review',
                    loading: _busy,
                    onPressed: _busy ? null : _submit),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
