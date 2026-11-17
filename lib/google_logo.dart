import 'package:flutter/material.dart';

/// Official multicolor Google "G" from the image asset.
class GoogleLogo extends StatelessWidget {
  final double size;
  const GoogleLogo({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/googlelogo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
