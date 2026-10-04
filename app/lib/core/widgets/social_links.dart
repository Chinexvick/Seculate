import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Seculate's official social pages.
const socialLinks = <(String, String)>[
  ('X', 'https://x.com/seculate_ng'),
  ('Instagram', 'https://www.instagram.com/seculate_ng'),
  ('Facebook', 'https://www.facebook.com/share/19iBKb1cVy/'),
  ('TikTok', 'https://www.tiktok.com/@seculate_ng'),
];

Future<void> openSocial(BuildContext context, String url) async {
  final ok =
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)
          .catchError((_) => false);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Could not open the link')));
  }
}

/// "Follow us" row of pills.
class SocialLinks extends StatelessWidget {
  const SocialLinks({super.key, this.title = 'Follow us'});
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(title!,
                style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    color: AppColors.neutral200)),
          ),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final (label, url) in socialLinks)
            InkWell(
              onTap: () => openSocial(context, url),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(label,
                    style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        color: AppColors.primary)),
              ),
            ),
        ]),
      ],
    );
  }
}
