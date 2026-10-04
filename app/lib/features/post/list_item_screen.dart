import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/location_sheet.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_arrow.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/radio_sheet.dart';
import '../../data/ad_categories.dart';
import '../../data/backend.dart';
import '../../data/models.dart';
import '../../data/user_profile.dart';
import 'category_picker_screen.dart';
import 'promote_ad_screen.dart';

const _cardBg = Color(0xFFF4F5F7);
const _maxPhotos = 5;

/// "Post ad" form (Figma: Post ad → Categories → sub category → full form).
/// Also used to request a service / errand and to edit & resubmit a listing.
class ListItemScreen extends StatefulWidget {
  const ListItemScreen({super.key, this.requestService = false, this.editing});

  /// "Request service" entry: creates an errand / task instead of a listing.
  final bool requestService;

  /// A listing to edit and resubmit (changes requested / rejected).
  final Product? editing;

  @override
  State<ListItemScreen> createState() => _ListItemScreenState();
}

class _ListItemScreenState extends State<ListItemScreen> {
  String? _category;
  String? _location;
  String? _delivery;
  String _availability = adAvailabilityOptions.first;
  String _period = '2 weeks';
  DateTime? _neededBy;
  final List<String> _photos = [];
  List<String> _existing = const [];
  bool _saving = false;
  bool _submitted = false;
  bool _done = false;
  Map<String, dynamic>? _plan;

  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _features = TextEditingController();
  final _price = TextEditingController();
  final _collateral = TextEditingController();
  final _fee = TextEditingController();
  final _minDays = TextEditingController();
  final _maxDays = TextEditingController();
  final _company = TextEditingController();

  bool get _task => widget.requestService;
  bool get _isService => !_task && isServiceCategory(_category);
  int get _photoCount => _existing.length + _photos.length;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _category = e.subCategory ?? e.categoryLabel;
      _location = e.location.isEmpty ? null : e.location;
      _delivery = e.deliveryOption;
      if (e.availability.isNotEmpty) _availability = e.availability;
      _period = e.lendingPeriod ?? _period;
      _name.text = e.name;
      _desc.text = e.description;
      _features.text = e.features.join('\n');
      _price.text = e.pricePerDay > 0 ? '${e.pricePerDay}' : '';
      _collateral.text = e.collateral > 0 ? '${e.collateral}' : '';
      _fee.text = e.securityFee > 0 ? '${e.securityFee}' : '';
      _minDays.text = e.minDays != null ? '${e.minDays}' : '';
      _maxDays.text = e.maxDays != null ? '${e.maxDays}' : '';
      _existing = e.images.isNotEmpty
          ? e.images
          : (e.image.isEmpty ? const [] : [e.image]);
    } else if (currentProfile.city.isNotEmpty) {
      _location = currentProfile.city;
    }
    if (!_task) _loadPlan();
  }

  Future<void> _loadPlan() async {
    try {
      final p = await backend.planStatus();
      if (mounted) setState(() => _plan = p);
    } catch (_) {
      // Informational only; the server enforces the limit on submit.
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _desc,
      _features,
      _price,
      _collateral,
      _fee,
      _company
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickCategory() async {
    final r = await Navigator.of(context).push<String>(
      MaterialPageRoute(
          builder: (_) => CategoryPickerScreen(tasks: _task, parent: null)),
    );
    if (r != null) setState(() => _category = r);
  }

  Future<String?> _pick(String title, List<String> options, String? current) {
    return showRadioSheet(
      context,
      title: title,
      options: [for (final o in options) SheetOption(o, o)],
      selectedId: current ?? '',
    );
  }

  Future<void> _addPhotos() async {
    final room = _maxPhotos - _photoCount;
    if (room <= 0) return;
    try {
      final picked = await ImagePicker().pickMultiImage(
          imageQuality: 80, maxWidth: 1600, limit: room < 2 ? 2 : room);
      if (!mounted || picked.isEmpty) return;
      setState(() => _photos.addAll(picked.take(room).map((x) => x.path)));
    } catch (_) {
      if (mounted) AppToast.show(context, 'Could not open your photos');
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _neededBy ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _neededBy = d);
  }

  void _clear() {
    FocusScope.of(context).unfocus();
    setState(() {
      _category = _delivery = null;
      _location = currentProfile.city.isEmpty ? null : currentProfile.city;
      _availability = adAvailabilityOptions.first;
      _period = '2 weeks';
      _photos.clear();
      _existing = const [];
      _neededBy = null;
      _submitted = false;
      for (final c in [
        _name,
        _desc,
        _features,
        _price,
        _collateral,
        _fee,
        _company
      ]) {
        c.clear();
      }
    });
  }

  bool get _valid =>
      _category != null &&
      _location != null &&
      _name.text.trim().isNotEmpty &&
      _desc.text.trim().isNotEmpty &&
      (int.tryParse(_price.text) ?? 0) > 0 &&
      (_task || _isService || _photoCount > 0);

  bool get _limitReached {
    // Resubmitting an already-counted listing never uses extra room; the
    // server stays the authority either way.
    if (widget.editing != null) return false;
    final p = _plan;
    final plan = p?['plan'];
    final limit = plan is Map ? plan['item_limit_per_month'] : null;
    final used = p?['used_this_month'];
    return limit is num && used is num && used >= limit;
  }

  Future<void> _upgradePrompt([String? message]) async {
    if (!mounted) return;
    final go = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Monthly limit reached',
              style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: AppColors.black)),
          const SizedBox(height: 8),
          Text(
              message ??
                  'You have used all the listings in your plan this month. Upgrade to post more.',
              textAlign: TextAlign.center,
              style: AppText.body),
          const SizedBox(height: 22),
          AppButton(
              label: 'Upgrade plan', onPressed: () => Navigator.pop(ctx, true)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: OutlinedButton.styleFrom(
                  shape: const StadiumBorder(),
                  side: const BorderSide(color: AppColors.neutral50)),
              child: const Text('Not now',
                  style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: AppColors.black)),
            ),
          ),
        ]),
      ),
    );
    if (go == true && mounted) Navigator.of(context).pushNamed(Routes.upgrade);
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    if (!_valid) {
      setState(() => _submitted = true);
      AppToast.show(
          context,
          !_task && !_isService && _photoCount == 0
              ? 'Add at least one photo'
              : 'Please complete the required fields');
      return;
    }
    if (currentProfile.lat == null) {
      await Navigator.of(context).pushNamed(Routes.locationGate);
      if (!mounted || currentProfile.lat == null) return;
    }
    if (!_task && _limitReached) {
      await _upgradePrompt();
      return;
    }
    setState(() => _saving = true);
    try {
      final price = int.parse(_price.text);
      if (_task) {
        await backend.createTask(
          title: _name.text,
          description: _desc.text,
          categoryLabel: _category!,
          proposedPrice: price,
          locationLabel: _location,
          neededBy: _neededBy,
        );
      } else {
        final cat = _category!;
        final company = _company.text.trim();
        final e = widget.editing;
        await backend.createListing(
          ListingDraft(
            kind: _isService ? 'service' : 'item',
            title: _name.text,
            description: _isService && company.isNotEmpty
                ? '${_desc.text.trim()}\n\nCompany: $company'
                : _desc.text,
            categoryLabel: parentCategoryOf(cat) ?? cat,
            subCategory: parentCategoryOf(cat) == null ? null : cat,
            pricePerDay: price,
            collateral: _isService ? 0 : (int.tryParse(_collateral.text) ?? 0),
            securityFee: _isService ? 0 : (int.tryParse(_fee.text) ?? 0),
            minDays: _isService ? null : int.tryParse(_minDays.text),
            maxDays: _isService ? null : int.tryParse(_maxDays.text),
            lendingPeriod: _isService ? null : _period,
            availability: _isService ? null : _availability,
            deliveryOption: _isService ? null : _delivery,
            locationLabel: _location,
            features: _isService
                ? const []
                : [
                    for (final l in _features.text.split('\n'))
                      if (l.trim().isNotEmpty) l.trim()
                  ],
            photos: _photos,
          ),
          editingId: e?.id,
        );
      }
      if (!mounted) return;
      setState(() {
        _saving = false;
        _done = true;
      });
    } on BackendError catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      if (e.message.toLowerCase().contains('plan limit')) {
        await _upgradePrompt(e.message);
      } else {
        AppToast.show(context, e.message);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppToast.show(context, 'Could not submit. Please try again.');
    }
  }

  Widget _success() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 14, 28, 28),
      child: Column(
        children: [
          const Spacer(),
          FadeSlideIn(
            child: Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                  color: Color(0xFFE3F8E8), shape: BoxShape.circle),
              child: const Icon(Icons.hourglass_top_rounded,
                  color: AppColors.primary, size: 40),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Submitted for review',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w500,
                  fontSize: 22,
                  color: AppColors.black)),
          const SizedBox(height: 10),
          Text(
              'Submitted for review: your ${_task ? 'request' : 'listing'} goes live after our team approves it (usually within 24h).',
              textAlign: TextAlign.center,
              style: AppText.body),
          const Spacer(),
          AppButton(
              label: 'Done',
              onPressed: () {
                final nav = Navigator.of(context);
                if (nav.canPop()) nav.pop();
              }),
          if (!_task) ...[
            const SizedBox(height: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PromoteAdScreen())),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Promote your ad',
                    style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: AppColors.primary)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget? _planBanner() {
    final p = _plan;
    if (p == null || _task) return null;
    final plan = p['plan'];
    if (plan is! Map) return null;
    final limit = plan['item_limit_per_month'];
    final used = (p['used_this_month'] as num?)?.toInt() ?? 0;
    final text = limit is num
        ? '${(limit - used).clamp(0, limit).toInt()} of ${limit.toInt()} listings left this month (${plan['name']} plan)'
        : 'Unlimited listings on your ${plan['name']} plan';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
            color: const Color(0xFFE3F8E8),
            borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: AppText.body.copyWith(color: AppColors.black)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.editing != null
        ? 'Edit ad'
        : _task
            ? 'Request service'
            : 'Post ad';
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _done
            ? _success()
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 14, 28, 14),
                    child: Row(
                      children: [
                        const SizedBox(width: 32, child: BackArrow()),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(title,
                              style: const TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 22,
                                  color: AppColors.black)),
                        ),
                        SvgPicture.asset('assets/icons/info.svg',
                            width: 22, height: 22),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                      child: FadeSlideIn(
                        child: Column(
                          children: [
                            if (_planBanner() != null) _planBanner()!,
                            if (widget.editing?.reviewNote != null &&
                                widget.editing!.reviewNote!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFFFF4E5),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Text(
                                      'Reviewer note: ${widget.editing!.reviewNote}',
                                      style: AppText.body
                                          .copyWith(color: AppColors.black)),
                                ),
                              ),
                            _Card(children: [
                              _Label(_task ? 'Errand type' : 'Categories'),
                              _SelectBox(
                                text: _category ??
                                    (_task ? 'Errand type' : 'Categories'),
                                placeholder: _category == null,
                                error: _submitted && _category == null,
                                onTap: _pickCategory,
                              ),
                              if (!_task) ...[
                                const SizedBox(height: 16),
                                const _Label('Add photo'),
                                Wrap(spacing: 8, runSpacing: 8, children: [
                                  for (final u in _existing)
                                    _PhotoTile(url: u, onRemove: null),
                                  for (var i = 0; i < _photos.length; i++)
                                    _PhotoTile(
                                        path: _photos[i],
                                        onRemove: () => setState(
                                            () => _photos.removeAt(i))),
                                  if (_photoCount < _maxPhotos)
                                    _AddPhoto(onTap: _addPhotos),
                                ]),
                                const SizedBox(height: 14),
                                const Text(
                                    'The first image serves as the cover photo',
                                    style: _hint),
                                const SizedBox(height: 6),
                                const Text('Supported formats: JPEG and PNG.',
                                    style: _hint),
                              ],
                            ]),
                            const SizedBox(height: 32),
                            _Card(children: [
                              const _Label('Location'),
                              _SelectBox(
                                text: _location ?? 'Select location',
                                placeholder: _location == null,
                                error: _submitted && _location == null,
                                onTap: () async {
                                  final r = await showLocationSheet(context,
                                      current: _location);
                                  if (r != null) setState(() => _location = r);
                                },
                              ),
                              const SizedBox(height: 22),
                              _Label(_task
                                  ? 'Errand title'
                                  : _isService
                                      ? 'Service name'
                                      : 'Item name'),
                              _Input(
                                  controller: _name,
                                  error:
                                      _submitted && _name.text.trim().isEmpty,
                                  onChanged: (_) => setState(() {})),
                              const SizedBox(height: 22),
                              _Label(_task
                                  ? 'Errand description'
                                  : _isService
                                      ? 'Service description'
                                      : 'Item description'),
                              _Input(
                                  controller: _desc,
                                  lines: 5,
                                  error:
                                      _submitted && _desc.text.trim().isEmpty,
                                  onChanged: (_) => setState(() {})),
                              const SizedBox(height: 22),
                              if (_isService) ...[
                                const _Label('Company name'),
                                _Input(controller: _company),
                                const SizedBox(height: 22),
                              ] else if (!_task) ...[
                                const _Label('Item features (optional)'),
                                _Input(controller: _features, lines: 5),
                                const SizedBox(height: 22),
                              ],
                              _Label(_task
                                  ? 'Proposed price'
                                  : _isService
                                      ? 'Price'
                                      : 'Price per day'),
                              _Input(
                                controller: _price,
                                prefix: '₦',
                                keyboard: TextInputType.number,
                                formatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                error: _submitted &&
                                    (int.tryParse(_price.text) ?? 0) <= 0,
                                onChanged: (_) => setState(() {}),
                              ),
                              if (!_task && !_isService) ...[
                                const SizedBox(height: 22),
                                const _Label(
                                    'Collateral (refundable, optional)'),
                                _Input(
                                  controller: _collateral,
                                  prefix: '₦',
                                  keyboard: TextInputType.number,
                                  formatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  onChanged: (_) => setState(() {}),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: Text(
                                      'Held in escrow and returned to the borrower when the item comes back in good condition.',
                                      style: AppText.body),
                                ),
                                const SizedBox(height: 22),
                                const _Label(
                                    'Security fee (non-refundable, optional)'),
                                _Input(
                                  controller: _fee,
                                  prefix: '₦',
                                  keyboard: TextInputType.number,
                                  formatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  onChanged: (_) => setState(() {}),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: Text(
                                      'A one-off fee charged once per rental, for example handling or cleaning. It is not returned.',
                                      style: AppText.body),
                                ),
                                const SizedBox(height: 22),
                                const _Label(
                                    'Rental length in days (optional)'),
                                Row(children: [
                                  Expanded(
                                    child: _Input(
                                      controller: _minDays,
                                      hint: 'Minimum',
                                      keyboard: TextInputType.number,
                                      formatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(3)
                                      ],
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _Input(
                                      controller: _maxDays,
                                      hint: 'Maximum',
                                      keyboard: TextInputType.number,
                                      formatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(3)
                                      ],
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                ]),
                              ],
                              if (_task) ...[
                                const SizedBox(height: 22),
                                const _Label('Needed by (optional)'),
                                _SelectBox(
                                  text: _neededBy == null
                                      ? 'Select date'
                                      : '${_neededBy!.day}/${_neededBy!.month}/${_neededBy!.year}',
                                  placeholder: _neededBy == null,
                                  onTap: _pickDate,
                                ),
                              ],
                            ]),
                            if (!_isService && !_task)
                              const SizedBox(height: 32),
                            if (!_isService && !_task)
                              _Card(children: [
                                const _Label('Delivery'),
                                _SelectBox(
                                  text: _delivery ?? 'Region',
                                  placeholder: _delivery == null,
                                  onTap: () async {
                                    final r = await _pick('Delivery',
                                        adDeliveryOptions, _delivery);
                                    if (r != null) {
                                      setState(() => _delivery = r);
                                    }
                                  },
                                ),
                                const SizedBox(height: 14),
                                const _Label('Availability'),
                                _SelectBox(
                                  text: _availability,
                                  onTap: () async {
                                    final r = await _pick('Availability',
                                        adAvailabilityOptions, _availability);
                                    if (r != null) {
                                      setState(() => _availability = r);
                                    }
                                  },
                                ),
                                const SizedBox(height: 14),
                                const _Label('Lending Period'),
                                _SelectBox(
                                  text: _period,
                                  onTap: () async {
                                    final r = await _pick('Lending Period',
                                        adLendingPeriods, _period);
                                    if (r != null) setState(() => _period = r);
                                  },
                                ),
                              ]),
                            const SizedBox(height: 32),
                            AppButton(
                                label: widget.editing != null
                                    ? 'Resubmit for review'
                                    : 'Submit for review',
                                onPressed: _save,
                                loading: _saving),
                            const SizedBox(height: 8),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _clear,
                              child: const Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('Clear',
                                    style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                        color: AppColors.alert)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

const _hint = TextStyle(
    fontFamily: AppTheme.fontFamily, fontSize: 10, color: AppColors.neutral200);

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration:
          BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(8)),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: AppText.body),
      );
}

class _SelectBox extends StatelessWidget {
  const _SelectBox({
    required this.text,
    required this.onTap,
    this.placeholder = false,
    this.error = false,
  });
  final String text;
  final bool placeholder;
  final bool error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: error ? AppColors.alert : Colors.transparent),
        ),
        child: Row(children: [
          Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: placeholder
                    ? AppText.body.copyWith(fontSize: 15)
                    : AppText.title1.copyWith(color: AppColors.black)),
          ),
          SvgPicture.asset('assets/icons/chevron_right_dark.svg',
              width: 20, height: 20),
        ]),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    this.lines = 1,
    this.prefix,
    this.keyboard,
    this.formatters,
    this.error = false,
    this.onChanged,
    this.hint,
  });
  final String? hint;
  final TextEditingController controller;
  final int lines;
  final String? prefix;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? formatters;
  final bool error;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 20, vertical: lines > 1 ? 12 : 0),
      height: lines > 1 ? 118 : 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: error ? AppColors.alert : Colors.transparent),
      ),
      child: Row(
        crossAxisAlignment:
            lines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          if (prefix != null) ...[
            Text(prefix!,
                style: AppText.body.copyWith(color: AppColors.neutral100)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              maxLines: lines > 1 ? null : 1,
              expands: lines > 1,
              keyboardType: lines > 1 ? TextInputType.multiline : keyboard,
              textAlignVertical:
                  lines > 1 ? TextAlignVertical.top : TextAlignVertical.center,
              inputFormatters: formatters,
              cursorColor: AppColors.primary,
              style: AppText.title1,
              decoration: InputDecoration(
                  border: InputBorder.none, isDense: true, hintText: hint),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhoto extends StatelessWidget {
  const _AddPhoto({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 77,
        height: 74,
        decoration: BoxDecoration(
            color: const Color(0xFFE3F8E8),
            borderRadius: BorderRadius.circular(6)),
        child: const Icon(Icons.add, color: Color(0xFF7FDB95), size: 26),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({this.path, this.url, this.onRemove});
  final String? path;
  final String? url;
  final VoidCallback? onRemove;
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 77,
            height: 74,
            child: path != null
                ? Image.file(File(path!), fit: BoxFit.cover, cacheWidth: 240)
                : AppImage(url, width: 77, height: 74),
          ),
        ),
        if (onRemove != null)
          Positioned(
            right: -6,
            top: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                    color: AppColors.black, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 13, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
