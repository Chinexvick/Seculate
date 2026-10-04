import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Small pill showing a person's trust band (new / building / trusted / elite).
class TrustBadge extends StatelessWidget {
  const TrustBadge({super.key, required this.band, this.score});
  final String band;
  final int? score;

  static String label(String b) => switch (b) {
        'elite' => 'Elite',
        'trusted' => 'Trusted',
        'building' => 'Building trust',
        _ => 'New member',
      };

  static Color color(String b) => switch (b) {
        'elite' => const Color(0xFF7B3FE4),
        'trusted' => const Color(0xFF008A23),
        'building' => const Color(0xFFB7791F),
        _ => const Color(0xFF6B788E),
      };

  @override
  Widget build(BuildContext context) {
    final c = color(band);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.shield_outlined, size: 12, color: c),
        const SizedBox(width: 4),
        Text(score == null ? label(band) : '${label(band)} · $score',
            style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: c)),
      ]),
    );
  }
}
