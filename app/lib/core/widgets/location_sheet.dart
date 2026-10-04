import 'package:flutter/material.dart';

import '../../data/ng_locations.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';
import 'radio_sheet.dart';

/// Searchable list of locations across Nigeria. Anything missing can be typed
/// in with "Can't find your location? Add it". Returns the chosen location.
Future<String?> showLocationSheet(BuildContext context, {String? current}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: sheetShape,
    builder: (_) => _LocationSheet(current: current),
  );
}

class _LocationSheet extends StatefulWidget {
  const _LocationSheet({this.current});
  final String? current;

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  final _all = allNgLocations();
  final _search = TextEditingController();
  final _custom = TextEditingController();
  late String? _sel = widget.current;
  bool _adding = false;

  @override
  void dispose() {
    _search.dispose();
    _custom.dispose();
    super.dispose();
  }

  List<String> get _shown {
    final q = _search.text.trim().toLowerCase();
    final base = [
      if (widget.current != null && !_all.contains(widget.current))
        widget.current!,
      ..._all,
    ];
    if (q.isEmpty) return base;
    return base.where((l) => l.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final list = _shown;
    final customOk = _custom.text.trim().length >= 3;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHeader(title: 'Location'),
              const SizedBox(height: 14),
              if (!_adding) ...[
                _field(_search, 'Search town, area or state',
                    onChanged: (_) => setState(() {})),
                const SizedBox(height: 4),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      for (final l in list)
                        InkWell(
                          onTap: () => setState(() => _sel = l),
                          child: Container(
                            height: 56,
                            decoration: const BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: AppColors.neutral40))),
                            child: Row(children: [
                              Expanded(
                                  child: Text(l,
                                      style: const TextStyle(
                                          fontFamily: AppTheme.fontFamily,
                                          fontSize: 15,
                                          color: AppColors.black))),
                              Icon(
                                  l == _sel
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: l == _sel
                                      ? AppColors.primary
                                      : AppColors.neutral50),
                            ]),
                          ),
                        ),
                      if (list.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text('No match. Add your location below.',
                              style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  color: AppColors.neutral200)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  key: const Key('add-location'),
                  onPressed: () => setState(() {
                    _adding = true;
                    _custom.text = _search.text.trim();
                  }),
                  icon: const Icon(Icons.add_location_alt_outlined,
                      color: AppColors.primary),
                  label: const Text("Can't find your location? Add it",
                      style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary)),
                ),
                if (_sel != null && _sel != widget.current)
                  AppButton(
                      label: 'Save',
                      onPressed: () => Navigator.of(context).pop(_sel)),
              ] else ...[
                const Text('Type your area, town and state',
                    style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13,
                        color: AppColors.neutral200)),
                const SizedBox(height: 8),
                _field(_custom, 'e.g. Ogudu GRA, Lagos',
                    autofocus: true, onChanged: (_) => setState(() {})),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Use this location',
                  inactive: !customOk,
                  onPressed: () =>
                      Navigator.of(context).pop(_custom.text.trim()),
                ),
                TextButton(
                    onPressed: () => setState(() => _adding = false),
                    child: const Text('Back to the list')),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint,
      {ValueChanged<String>? onChanged, bool autofocus = false}) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neutral50),
      ),
      child: TextField(
        controller: c,
        autofocus: autofocus,
        onChanged: onChanged,
        textCapitalization: TextCapitalization.words,
        cursorColor: AppColors.primary,
        style: AppText.title1.copyWith(fontSize: 15),
        decoration: InputDecoration(
            border: InputBorder.none, isDense: true, hintText: hint),
      ),
    );
  }
}
