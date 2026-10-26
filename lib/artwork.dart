import 'package:flutter/material.dart';

import '../theme.dart';

/// Gradient placeholder for album/singer artwork.
/// Pass [child] to overlay content. Replace with Image.network later.
class Artwork extends StatelessWidget {
  final List<Color> colors;
  final double radius;
  final double? size;
  final Widget? child;

  const Artwork({
    super.key,
    required this.colors,
    this.radius = 8,
    this.size,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final art = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned(
              right: -30,
              top: -30,
              child: _Blob(size: 120, color: AppColors.glow),
            ),
            const Positioned(
              left: -20,
              bottom: -40,
              child: _Blob(size: 100, color: AppColors.scrimSoft),
            ),
            ?child,
          ],
        ),
      ),
    );
    return size == null ? art : SizedBox(width: size, height: size, child: art);
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
