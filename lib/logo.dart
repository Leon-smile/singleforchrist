import 'package:flutter/material.dart';

import '../theme.dart';

/// The SFC Lyrics app mark: a cross rising from an open lyric book.
/// Drawn in code (no image asset needed) and scales to any [size].
class LogoMark extends StatelessWidget {
  final double size;

  /// When false, only the cross + book are drawn (no lime rounded square),
  /// useful on top of an existing lime background.
  final bool withBackground;

  const LogoMark({super.key, this.size = 40, this.withBackground = true});

  /// Path of the PNG logo. Put your file here (see pubspec.yaml assets).
  static const assetPath = 'assets/logo/sfc_icon.png';

  @override
  Widget build(BuildContext context) {
    final painted = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter(withBackground)),
    );
    if (!withBackground) return painted;

    // Uses the PNG; if the file is missing, falls back to the drawn version.
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => painted,
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final bool withBackground;
  _LogoPainter(this.withBackground);

  static const _ink = Color(0xFF0E110F);

  @override
  void paint(Canvas canvas, Size size) {
    // The artwork is designed on a 100 x 100 grid.
    canvas.scale(size.width / 100, size.height / 100);

    final lime = Paint()..color = AppColors.accent;
    final ink = Paint()..color = _ink;

    if (withBackground) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 100, 100),
          const Radius.circular(22),
        ),
        lime,
      );
    }

    // Cross
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(46, 13, 8, 38),
        const Radius.circular(2),
      ),
      ink,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(35, 22, 30, 8),
        const Radius.circular(2),
      ),
      ink,
    );

    // Book pages
    final left = Path()
      ..moveTo(50, 82)
      ..cubicTo(42, 74, 28, 72, 15, 74)
      ..lineTo(15, 49)
      ..cubicTo(28, 47, 42, 49, 50, 57)
      ..close();
    final right = Path()
      ..moveTo(50, 82)
      ..cubicTo(58, 74, 72, 72, 85, 74)
      ..lineTo(85, 49)
      ..cubicTo(72, 47, 58, 49, 50, 57)
      ..close();
    canvas.drawPath(left, ink);
    canvas.drawPath(right, ink);

    // Lyric lines on the pages
    final line = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    Path curve(
      double x1,
      double y1,
      double cx1,
      double cy1,
      double cx2,
      double cy2,
      double x2,
      double y2,
    ) => Path()
      ..moveTo(x1, y1)
      ..cubicTo(cx1, cy1, cx2, cy2, x2, y2);

    canvas.drawPath(curve(23, 59, 29, 58, 35, 59, 41, 62), line);
    canvas.drawPath(curve(23, 66, 29, 65, 34, 66, 39, 68), line);
    canvas.drawPath(curve(77, 59, 71, 58, 65, 59, 59, 62), line);
    canvas.drawPath(curve(77, 66, 71, 65, 66, 66, 61, 68), line);
  }

  @override
  bool shouldRepaint(covariant _LogoPainter old) =>
      old.withBackground != withBackground;
}

/// Mark + "SFC Lyrics" wordmark, used in the sidebar.
class LogoLockup extends StatelessWidget {
  final double markSize;
  final double fontSize;

  const LogoLockup({super.key, this.markSize = 32, this.fontSize = 18});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LogoMark(size: markSize),
        const SizedBox(width: 10),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'SFC '),
              TextSpan(
                text: 'Lyrics',
                style: TextStyle(color: AppColors.accent),
              ),
            ],
          ),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
