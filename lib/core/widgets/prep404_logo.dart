import 'package:flutter/material.dart';

/// Official Prep404 Brand Logo Widget
/// Displays the confirmed brush-script wordmark with underline swoosh and energy dashes.
class Prep404Logo extends StatelessWidget {
  final double height;
  final double? width;
  final bool isSquare;

  const Prep404Logo({
    super.key,
    this.height = 32,
    this.width,
    this.isSquare = false,
    double? fontSize, // Kept for backwards compatibility
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = isSquare
        ? 'assets/images/brand/prep404_square_logo_cream.png'
        : 'assets/images/brand/prep404_horizontal_transparent.png';

    return Image.asset(
      assetPath,
      height: height,
      width: width,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) {
        // High-fidelity fallback
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Prep',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: height * 0.75,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: isDark ? const Color(0xFFFFF2DF) : const Color(0xFF45204F),
              ),
            ),
            Text(
              '404',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: height * 0.75,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: const Color(0xFFF28C28),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Backwards compatibility alias
typedef ChorchaLogo = Prep404Logo;
