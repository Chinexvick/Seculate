import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shows a bundled asset or a network photo, with a calm placeholder while
/// loading and when there is no picture.
class AppImage extends StatelessWidget {
  const AppImage(this.src,
      {super.key,
      this.width,
      this.height,
      this.fit = BoxFit.cover,
      this.radius = 0});

  final String? src;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double radius;

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: const Color(0xFFF1F3F5),
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined, color: AppColors.neutral50),
      );

  @override
  Widget build(BuildContext context) {
    final s = src;
    Widget child;
    if (s == null || s.isEmpty) {
      child = _placeholder();
    } else if (s.startsWith('http')) {
      child = Image.network(
        s,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        loadingBuilder: (c, w, p) => p == null ? w : _placeholder(),
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    } else {
      child = Image.asset(s,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _placeholder());
    }
    return radius > 0
        ? ClipRRect(borderRadius: BorderRadius.circular(radius), child: child)
        : child;
  }
}
