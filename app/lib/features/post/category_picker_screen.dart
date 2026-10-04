import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/back_arrow.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../data/ad_categories.dart';

/// Two-level category picker (Figma "Categories" → sub category).
/// Pops with the chosen label.
class CategoryPickerScreen extends StatefulWidget {
  const CategoryPickerScreen({super.key, this.parent, this.tasks = false});

  /// Lists the errand / task categories.
  final bool tasks;

  /// When set, lists the sub categories of this category.
  final AdCategory? parent;

  @override
  State<CategoryPickerScreen> createState() => _CategoryPickerScreenState();
}

class _CategoryPickerScreenState extends State<CategoryPickerScreen> {
  final _search = TextEditingController();

  List<_Row> get _rows {
    final q = _search.text.trim().toLowerCase();
    final p = widget.parent;
    final all = widget.tasks
        ? [
            for (final t in adTaskCategories)
              _Row(t, 'assets/images/services/svc_errand.png', null)
          ]
        : p == null
            ? [for (final c in adCategories) _Row(c.label, c.image, c)]
            : [
                for (final s in p.subs) _Row(s, p.subImages[s] ?? p.image, null)
              ];
    return q.isEmpty
        ? all
        : all.where((r) => r.label.toLowerCase().contains(q)).toList();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _tap(_Row r) async {
    final c = r.category;
    if (c != null && c.subs.isNotEmpty) {
      final res = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => CategoryPickerScreen(parent: c)),
      );
      if (res != null && mounted) Navigator.of(context).pop(res);
    } else {
      Navigator.of(context).pop(r.label);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
              child: Row(
                children: [
                  const SizedBox(width: 32, child: BackArrow()),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                        widget.parent?.label ??
                            (widget.tasks ? 'Errand type' : 'Categories'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.title1.copyWith(
                            fontSize: 18, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(27, 16, 27, 12),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppColors.neutral50),
                ),
                child: Row(children: [
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
                        hintText: 'Search categories',
                        hintStyle: AppText.body,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            Expanded(
              child: rows.isEmpty
                  ? const Center(
                      child: Text('No category found', style: AppText.body))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: rows.length,
                      itemBuilder: (_, i) => FadeSlideIn(
                        delay: Duration(milliseconds: 30 * (i < 10 ? i : 10)),
                        child:
                            _RowTile(row: rows[i], onTap: () => _tap(rows[i])),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row {
  const _Row(this.label, this.image, this.category);
  final String label;
  final String image;
  final AdCategory? category;
}

class _RowTile extends StatelessWidget {
  const _RowTile({required this.row, required this.onTap});
  final _Row row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFEDEEF1),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Image.asset(row.image, fit: BoxFit.contain),
            ),
            const SizedBox(width: 12),
            Expanded(
              child:
                  Text(row.label, style: AppText.title1.copyWith(fontSize: 15)),
            ),
            SvgPicture.asset('assets/icons/chevron_right_dark.svg',
                width: 20, height: 20),
          ],
        ),
      ),
    );
  }
}
