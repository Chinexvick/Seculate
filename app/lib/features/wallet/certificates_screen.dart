import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/state_views.dart';
import '../../data/backend.dart';
import '../../data/backend_wallet.dart';
import '../../data/models.dart';
import '../requests/req_widgets.dart';

/// Agreement certificates for your finished deals, plus a "check a certificate" box.
class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});
  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  List<Map<String, dynamic>>? _list;
  String? _error;
  final _num = TextEditingController();
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _num.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final l = await backend.myCertificates();
      if (mounted) setState(() => _list = l);
    } on BackendError catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _check() async {
    final n = _num.text.trim();
    if (n.isEmpty || _checking) return;
    setState(() => _checking = true);
    try {
      final r = await backend.verifyCertificate(n);
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title:
              Text(r['valid'] == true ? 'Certificate is valid' : 'Not found'),
          content: Text(r['valid'] == true
              ? '${r['number']}\n${r['title'] ?? ''}\nIssued ${shortDate(r['issued_at'])}'
              : 'No certificate matches that number. Check it and try again.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c), child: const Text('OK'))
          ],
        ),
      );
    } on BackendError catch (e) {
      if (mounted) AppToast.show(context, e.message);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = _list;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          const ReqHeader('Certificates'),
          Expanded(
            child: l == null
                ? (_error != null
                    ? StateMessage(message: _error!, onAction: _load)
                    : const LoadingView())
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                      children: [
                        Text(
                            'A certificate is issued when a deal finishes. It records who agreed what, and how it ended.',
                            style: AppText.body.copyWith(fontSize: 13)),
                        const SizedBox(height: 16),
                        if (l.isEmpty)
                          Text(
                              'No certificates yet. They appear after a deal is completed.',
                              style: AppText.body),
                        for (final c in l)
                          ReqCard(
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                    builder: (_) => CertificateScreen(
                                        txId: '${c['transaction_id']}'))),
                            child: Row(children: [
                              const Icon(Icons.workspace_premium_outlined,
                                  color: AppColors.primaryDark),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('${c['title'] ?? 'Agreement'}',
                                          style: AppText.title1.copyWith(
                                              fontWeight: FontWeight.w500)),
                                      Text(
                                          '${c['number']} · ${shortDate(c['issued_at'])}',
                                          style: AppText.body
                                              .copyWith(fontSize: 12)),
                                    ]),
                              ),
                              const Icon(Icons.chevron_right),
                            ]),
                          ),
                        const SizedBox(height: 22),
                        Text('Check a certificate',
                            style: AppText.title1
                                .copyWith(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 10),
                        ReqField(
                            label: 'Certificate number',
                            controller: _num,
                            hint: 'SEC-20261004-AB12CD34'),
                        AppButton(
                            label: 'Check',
                            loading: _checking,
                            onPressed: _check),
                      ],
                    ),
                  ),
          ),
        ]),
      ),
    );
  }
}

/// One certificate, loaded for a deal (issued on first open if the deal has ended).
class CertificateScreen extends StatefulWidget {
  const CertificateScreen({super.key, required this.txId});
  final String txId;
  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  Map<String, dynamic>? _c;
  bool _loaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    backend.certificateForTx(widget.txId).then((c) {
      if (mounted) {
        setState(() {
          _c = c;
          _loaded = true;
        });
      }
    }).catchError((Object e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loaded = true;
        });
      }
    });
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 110,
              child: Text(k, style: AppText.body.copyWith(fontSize: 13))),
          Expanded(
              child: Text(v, style: AppText.title1.copyWith(fontSize: 14))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final s = Map<String, dynamic>.from((c?['snapshot'] as Map?) ?? const {});
    String name(String k) => '${(s[k] as Map?)?['name'] ?? ''}';
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          const ReqHeader('Agreement certificate'),
          Expanded(
            child: !_loaded
                ? const LoadingView()
                : c == null
                    ? Center(
                        child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Text(
                            _error ??
                                'A certificate is issued once the deal is finished.',
                            textAlign: TextAlign.center,
                            style: AppText.body),
                      ))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: AppColors.primary, width: 2),
                                borderRadius: BorderRadius.circular(16)),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(
                                      child: Text('${c['number']}',
                                          style: const TextStyle(
                                              fontFamily: AppTheme.fontFamily,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 17,
                                              color: AppColors.primaryDark)),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 18),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(
                                            text: '${c['number']}'));
                                        AppToast.show(context,
                                            'Certificate number copied');
                                      },
                                    ),
                                  ]),
                                  const Divider(),
                                  _row('Deal', '${s['title'] ?? ''}'),
                                  _row('Type', '${s['kind'] ?? ''}'),
                                  _row('Borrower / client', name('borrower')),
                                  _row('Lender / worker', name('lender')),
                                  _row('Amount',
                                      naira((s['amount'] as num?) ?? 0)),
                                  if (((s['collateral'] as num?) ?? 0) > 0)
                                    _row('Collateral',
                                        naira(s['collateral'] as num)),
                                  if (s['rental_days'] != null)
                                    _row(
                                        'Duration', '${s['rental_days']} days'),
                                  _row(
                                      'Outcome',
                                      s['final_state'] == 'refunded'
                                          ? 'Refunded'
                                          : 'Completed'),
                                  _row('Issued', shortDate(c['issued_at'])),
                                ]),
                          ),
                          const SizedBox(height: 14),
                          Text(
                              'Anyone can check this number under Certificates > Check a certificate.',
                              style: AppText.body.copyWith(fontSize: 12)),
                        ],
                      ),
          ),
        ]),
      ),
    );
  }
}
