import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/backend.dart';
import '../../data/backend_wallet.dart';
import '../requests/req_widgets.dart';

const problemReasons = <String, String>{
  'item_not_as_described': 'Item or work is not as described',
  'handover_no_show': 'The other person did not show up',
  'damage_or_condition': 'Damage or condition problem',
  'late_return': 'Late or missing return',
  'payment_not_received': 'Payment problem',
  'other': 'Something else',
};

/// Full-screen "Report a problem": reason, description and up to 4 photos.
/// Pops with true when the report was sent.
class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key, required this.txId});
  final String txId;

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  String? _code;
  final _text = TextEditingController();
  final _photos = <String>[];
  bool _busy = false;

  bool get _ok => _code != null && _text.text.trim().length >= 20;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    if (_photos.length >= 4) return;
    try {
      final f = await ImagePicker().pickImage(
          source: ImageSource.gallery, maxWidth: 1600, imageQuality: 80);
      if (f != null && mounted) setState(() => _photos.add(f.path));
    } catch (_) {
      if (mounted) AppToast.show(context, 'Could not open your photos.');
    }
  }

  Future<void> _send() async {
    if (!_ok || _busy) return;
    setState(() => _busy = true);
    try {
      await backend.reportProblem(widget.txId,
          code: _code!, reason: _text.text.trim(), photos: _photos);
      if (!mounted) return;
      AppToast.show(context, 'Problem reported. Your funds are protected.');
      Navigator.of(context).pop(true);
    } on BackendError catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        AppToast.show(context, e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          const ReqHeader('Report a problem'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
              children: [
                Text(
                    'Your money stays protected while our team looks into it. The other person has 3 days to respond.',
                    style: AppText.body.copyWith(fontSize: 13)),
                const SizedBox(height: 16),
                for (final e in problemReasons.entries)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(
                        _code == e.key
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: _code == e.key
                            ? AppColors.primary
                            : AppColors.neutral100),
                    title: Text(e.value,
                        style: AppText.title1.copyWith(fontSize: 14)),
                    onTap: () => setState(() => _code = e.key),
                  ),
                const SizedBox(height: 10),
                ReqField(
                    label: 'What happened? (at least 20 characters)',
                    controller: _text,
                    maxLines: 5,
                    maxLength: 2000),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  for (var i = 0; i < _photos.length; i++)
                    Chip(
                      label: Text('Photo ${i + 1}'),
                      onDeleted: () => setState(() => _photos.removeAt(i)),
                    ),
                  if (_photos.length < 4)
                    ActionChip(
                        avatar:
                            const Icon(Icons.add_a_photo_outlined, size: 18),
                        label: const Text('Add photo'),
                        onPressed: _pick),
                ]),
                const SizedBox(height: 20),
                AppButton(
                    label: 'Send report',
                    loading: _busy,
                    inactive: !_ok,
                    onPressed: _ok ? _send : null),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

/// Reply to a problem someone reported against you.
class RespondProblemScreen extends StatefulWidget {
  const RespondProblemScreen(
      {super.key, required this.txId, required this.disputeId});
  final String txId, disputeId;

  @override
  State<RespondProblemScreen> createState() => _RespondProblemScreenState();
}

class _RespondProblemScreenState extends State<RespondProblemScreen> {
  final _text = TextEditingController();
  final _photos = <String>[];
  bool _busy = false;
  bool get _ok => _text.text.trim().length >= 10;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    if (_photos.length >= 4) return;
    try {
      final f = await ImagePicker().pickImage(
          source: ImageSource.gallery, maxWidth: 1600, imageQuality: 80);
      if (f != null && mounted) setState(() => _photos.add(f.path));
    } catch (_) {
      if (mounted) AppToast.show(context, 'Could not open your photos.');
    }
  }

  Future<void> _send() async {
    if (!_ok || _busy) return;
    setState(() => _busy = true);
    try {
      await backend.respondProblem(widget.txId, widget.disputeId,
          body: _text.text.trim(), photos: _photos);
      if (!mounted) return;
      AppToast.show(context, 'Response sent.');
      Navigator.of(context).pop(true);
    } on BackendError catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        AppToast.show(context, e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          const ReqHeader('Your response'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
              children: [
                ReqField(
                    label: 'Tell your side',
                    controller: _text,
                    maxLines: 5,
                    maxLength: 2000),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  for (var i = 0; i < _photos.length; i++)
                    Chip(
                        label: Text('Photo ${i + 1}'),
                        onDeleted: () => setState(() => _photos.removeAt(i))),
                  if (_photos.length < 4)
                    ActionChip(
                        avatar:
                            const Icon(Icons.add_a_photo_outlined, size: 18),
                        label: const Text('Add photo'),
                        onPressed: _pick),
                ]),
                const SizedBox(height: 20),
                AppButton(
                    label: 'Send response',
                    loading: _busy,
                    inactive: !_ok,
                    onPressed: _ok ? _send : null),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

/// Status of the problem report on a deal, with a Respond button when it is your turn.
class DisputeCard extends StatelessWidget {
  const DisputeCard(
      {super.key,
      required this.txId,
      required this.d,
      required this.onChanged});
  final String txId;
  final Map<String, dynamic> d;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final status = '${d['status']}';
    final done =
        const {'RESOLVED', 'REFUNDED', 'RELEASED', 'CLOSED'}.contains(status);
    final outcome = d['outcome'] as String?;
    String line;
    if (done) {
      line = outcome == 'in_your_favour'
          ? 'Resolved in your favour.'
          : outcome == 'against_you'
              ? 'Resolved in the other person’s favour.'
              : 'Resolved by our team.';
    } else if (d['can_respond'] == true) {
      line =
          'Someone reported a problem on this deal. Please respond before ${shortDate(d['response_due_at'])}.';
    } else {
      line = d['opened_by_me'] == true
          ? 'Your report is with our team. The other person can respond until ${shortDate(d['response_due_at'])}.'
          : 'Our team is reviewing this report.';
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: const Color(0xFFFFF9EC),
          border: Border.all(color: const Color(0xFFF3DDA6)),
          borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(problemReasons['${d['reason_code']}'] ?? 'Problem reported',
            style: AppText.title1.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('${d['reason'] ?? ''}',
            style: AppText.body.copyWith(fontSize: 13)),
        if ((d['response'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Response: ${d['response']}',
              style: AppText.body.copyWith(fontSize: 13)),
        ],
        if ((d['resolution'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Decision: ${d['resolution']}',
              style: AppText.body.copyWith(fontSize: 13)),
        ],
        const SizedBox(height: 8),
        Text(line,
            style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.black)),
        if (d['can_respond'] == true) ...[
          const SizedBox(height: 10),
          AppButton(
              label: 'Respond',
              onPressed: () async {
                final ok = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                        builder: (_) => RespondProblemScreen(
                            txId: txId, disputeId: '${d['id']}')));
                if (ok == true) onChanged();
              }),
        ],
      ]),
    );
  }
}

/// Plain activity log for a deal.
class DealTimeline extends StatelessWidget {
  const DealTimeline({super.key, required this.events});
  final List<Map<String, dynamic>> events;

  static String _label(String s) => switch (s) {
        'requested' => 'Request sent',
        'accepted' => 'Request accepted',
        'payment_pending' => 'Waiting for payment',
        'escrow_held' => 'Payment secured in escrow',
        'active' => 'Handover confirmed',
        'return_pending' => 'Return submitted',
        'confirmed' => 'Return confirmed',
        'release_pending' => 'Release queued',
        'released' => 'Funds released',
        'disputed' => 'Problem reported',
        'refunded' => 'Refunded',
        'cancelled' => 'Cancelled',
        _ => s.replaceAll('_', ' '),
      };

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text('Activity',
            style: AppText.title1.copyWith(fontWeight: FontWeight.w500)),
        children: [
          for (final e in events)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child:
                        Icon(Icons.circle, size: 8, color: AppColors.primary)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_label('${e['to_state']}'),
                            style: AppText.title1.copyWith(fontSize: 14)),
                        if ((e['note'] ?? '').toString().isNotEmpty)
                          Text('${e['note']}',
                              style: AppText.body.copyWith(fontSize: 12)),
                        Text(shortDate(e['created_at']),
                            style: AppText.body.copyWith(fontSize: 11)),
                      ]),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}
